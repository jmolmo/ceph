"""
Ceph Call Home Agent
"""

from typing import List, Any, Tuple, Dict, Optional, Set, Callable
import time
import json
import requests
import asyncio
import os
from jinja2 import Environment, PackageLoader

from mgr_module import Option, CLIReadCommand, MgrModule, HandleCommandResult, NotifyType
from .options import CHES_ENDPOINT, INTERVAL_INVENTORY_REPORT_SECONDS, INTERVAL_PERFORMANCE_REPORT_SECONDS
from .dataClasses import ReportHeader, ReportEvent


class SendError(Exception):
    pass


def inventory() -> str:
    """<
    Produce the content for the inventory report

    Returns a string with a json structure with the ceph cluster inventory information
    """
    return "{'inventory': {}}"


def performance() -> str:
    """
    Produce the content for the performance report

    Returns a string with a json structure with the ceph cluster performance information
    """
    return "{'performance': {}}"


def last_contact() -> str:
    """
    Produce the content for the last_contact report

    Returns a string with just the tiomestamp of the last contact with the cluster
    """
    return "{'last_contact': %s }" % format(int(time.time()))

class Report:
    def __init__(self, report_type: str, description: str, fn: Callable[[], str], url: str, seconds_interval: int,
                 mgr_module: Any):
        self.report_type = report_type                       # name of the report
        self.fn = fn                           # function used to retrieve the data
        self.url = url                         # url to send the report
        self.interval = seconds_interval       # interval to send the report (seconds)
        self.mgr = mgr_module
        self.templates_environment = Environment(loader=PackageLoader('call_home_agent', package_path='templates'))
        self.description = description
        self.last_id = ''

        # Last upload settings
        self.last_upload_option_name = 'report_%s_last_upload' % self.report_type
        last_upload = self.mgr.get_store(self.last_upload_option_name, None)
        if last_upload is None:
            self.last_upload = str(int(time.time()) - self.interval + 1)
        else:
            self.last_upload = str(int(last_upload))

    def __str__(self) -> str:
        try:
            template = self.templates_environment.get_template('report_header.json')

            the_header = ReportHeader(self.report_type, self.mgr.get('mon_map')['fsid'], self.mgr.version)
            report = json.loads(template.render(header=the_header.__dict__))

            template = self.templates_environment.get_template('report_event.json')
            event_section = json.loads(template.render(event=ReportEvent(self.report_type,
                                                                         self.mgr.get('mon_map')['fsid'],
                                                                         self.description,
                                                                         self.fn).__dict__))
            report['events'].append(event_section)
            self.last_id = str(the_header.event_time_ms)

            return json.dumps(report)
        except Exception as ex:
            raise Exception('<%s> report not available: %s\n%s' % (self.report_type, ex, report))

    def send(self, force: bool = False) -> None:
        # Do not send report if the required interval is not reached
        if not force:
            if (int(time.time()) - int(self.last_upload)) < self.interval:
                self.mgr.log.info('%s report not sent because interval not reached', self.report_type)
                return
        resp = None
        try:
            self.mgr.log.info('Sending <%s> report to <%s>', self.report_type, self.url)
            resp = requests.post(url=self.url,
                                 headers={'accept': 'application/json', 'content-type': 'application/json'},
                                 data=str(self))
            resp.raise_for_status()
            self.last_upload = str(int(time.time()))
            self.mgr.set_store(self.last_upload_option_name, self.last_upload)
            self.mgr.health_checks.pop('CHA_ERROR_SENDING_REPORT', None)
            self.mgr.log.info('Successfully sent <%s> report(%s) to <%s>', self.report_type, self.last_id, self.url)
        except Exception as e:
            explanation = "\n{}".format(resp.content) if resp else ''
            raise SendError('Failed to send <%s> to <%s>: %s %s' % (self.report_type, self.url, str(e), explanation))

class CallHomeAgent(MgrModule):
    MODULE_OPTIONS: List[Option] = [
        Option(
            name='ches_endpoint',
            type='str',
            default=CHES_ENDPOINT,
            desc='Call Home Event streamer end point'
        ),
        Option(
            name='interval_inventory_report_minutes',
            type='int',
            min=0,
            max=10080,  # One week
            default=INTERVAL_INVENTORY_REPORT_SECONDS,
            desc='Time frequency for the inventory report'
        ),
        Option(
            name='interval_performance_report_minutes',
            type='int',
            min=0,
            max=10080,  # One week
            default=INTERVAL_PERFORMANCE_REPORT_SECONDS,
            desc='Time frequency for the performance report'
        ),
        Option(
            name='customer_email',
            type='str',
            default='',
            desc='Customer contact email'
        ),
        Option(
            name='country_code',
            type='str',
            default='',
            desc='Customer country code'
        )
    ]

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super(CallHomeAgent, self).__init__(*args, **kwargs)

        # set up some members to enable the serve() method and shutdown()
        self.run = True

        # Init module options
        # Env vars (if they exist) have preference over module options
        self.ches_url = str(os.environ.get('CHA_CHES_ENDPOINT', self.get_module_option('ches_endpoint')))
        self.interval_performance_seconds = int(
            os.environ.get('CHA_INTERVAL_INVENTORY_REPORT_SECONDS',
                           self.get_module_option('interval_inventory_report_minutes')))  # type: ignore
        self.interval_inventory_seconds = int(
            os.environ.get('CHA_INTERVAL_PERFORMANCE_REPORT_SECONDS',
                           self.get_module_option('interval_performance_report_minutes')))  # type: ignore
        self.customer_email = os.environ.get('CHA_CUSTOMER_EMAIL', self.get_module_option('customer_email'))
        self.country_code = os.environ.get('CHA_COUNTRY_CODE', self.get_module_option('country_code'))
        # Health checks
        self.health_checks: Dict[str, Dict[str, Any]] = dict()

        # Prepare reports
        self.reports = {'inventory': Report('inventory',
                                            'Ceph cluster composition',
                                            inventory,
                                            self.ches_url,
                                            self.interval_performance_seconds,
                                            self),
                        'performance': Report('performance',
                                              'Ceph cluster performance',
                                              performance,
                                              self.ches_url,
                                              self.interval_inventory_seconds,
                                              self),
                        'last_contact': Report('last_contact',
                                               'Last contact timestamps with this ceph cluster',
                                               last_contact,
                                               self.ches_url,
                                               1800,
                                               self)
                        }

    async def report_task(self, report: Report) -> None:
        """
            Coroutine for sending the report passed as parameter
        """
        self.log.info('Launched task for <%s> report each %s seconds)', report.report_type, report.interval)
        while self.run:
            try:
                report.send()
            except Exception as ex:
                send_error = str(ex)
                self.log.error(send_error)
                self.health_checks.update({
                    'CHA_ERROR_SENDING_REPORT': {
                        'severity': 'error',
                        'summary': 'Ceph Call Home Agent manager module: error sending {} report to '
                                   'endpoint {}'.format(self.ches_url, report.report_type),
                        'detail': [send_error]
                    }
                })

            self.set_health_checks(self.health_checks)
            await asyncio.sleep(report.interval)

    def launch_coroutines(self) -> None:
        """
         Launch module coroutines (reports or any other async task)
        """
        loop = asyncio.new_event_loop()  # type: ignore
        try:
            for report_name, report in self.reports.items():
                t = loop.create_task(self.report_task(report))
            loop.run_forever()
        except Exception as ex:
            self.log.exception(str(ex))

    def serve(self) -> None:
        """
            - Launch coroutines for report tasks
        """
        self.log.info('Starting Ceph Call Home Agent')

        # Launch coroutines for the reports
        self.launch_coroutines()

        self.log.info('Call home agent finished')

    def shutdown(self) -> None:
        """
        This method is called by the mgr when the module needs to shut
        down (i.e., when the serve() function needs to exit).
        """
        self.log.info('Stopping Ceph Call Home Agent')
        self.run = False

    @CLIReadCommand('callhome show')
    def print_report_cmd(self, report_type: str) -> Tuple[int, str, str]:
        """
            Prints the report requested.
            Example:
                ceph callhome show inventory
        """
        return HandleCommandResult(stdout=f'report: {self.reports[report_type]}')

    @CLIReadCommand('callhome send')
    def send_report_cmd(self, report_type: str) -> Tuple[int, str, str]:
        """
            Command for sending the report requested.
            Example:
                ceph callhome send inventory
        """
        try:
            self.reports[report_type].send(force=True)
        except Exception as ex:
            return HandleCommandResult(stderr=str(ex))
        else:
            return HandleCommandResult(stdout=f'{report_type} report sent successfully')


