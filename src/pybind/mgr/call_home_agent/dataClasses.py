from datetime import datetime
from typing import Any

from .tools import lock_attributes
from .config import get_settings


@lock_attributes
class ReportHeader:
    def __init__(self, report_type: str, ceph_cluster_id: str, ceph_version: str) -> None:
        try:
            id_data = get_settings()
        except Exception as ex:
            raise Exception('Error getting encrypted identification keys for %s report: %s. '
                            'Provide keys and restart Ceph Call Home module', (report_type, ex))

        dt = datetime.timestamp(datetime.now())
        report_time = datetime.fromtimestamp(dt).strftime("%Y-%m-%d %H:%M:%S")
        report_time_ms = int(dt * 1000)
        local_report_time = datetime.fromtimestamp(dt).strftime("%a %b %d %H:%M:%S %Z")

        self.agent: str = "Ceph Call Home"
        self.api_key: str = id_data['api_key'].decode('utf-8')
        self.private_key: str = id_data['private_key'].decode('utf-8')
        self.target_space: str = ""
        self.country_code: str = ""
        self.report_type = report_type
        self.event_time: str = report_time
        self.event_time_ms: int = report_time_ms
        self.local_event_time: str = local_report_time
        self.ceph_cluster_id = ceph_cluster_id
        self.ceph_cluster_version: str = ceph_version


@lock_attributes
class ReportEvent:
    def __init__(self, event_type: str, ceph_cluster_id: str, description: str, fn: Any ) -> None:
        dt = datetime.timestamp(datetime.now())
        event_time = datetime.fromtimestamp(dt).strftime("%Y-%m-%d %H:%M:%S")
        event_time_ms = int(dt * 1000)
        local_event_time = datetime.fromtimestamp(dt).strftime("%a %b %d %H:%M:%S %Z")

        self.event_type: str = event_type
        self.event_time: str = event_time
        self.event_time_ms: int = event_time_ms
        self.local_event_time: str = local_event_time
        self.description: str = description
        self.ceph_cluster_id: str = ceph_cluster_id
        self.content = fn()
