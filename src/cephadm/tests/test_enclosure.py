import pytest

from unittest import mock
from tests.fixtures import host_sysfs

with mock.patch('builtins.open', create=True):
    from importlib.machinery import SourceFileLoader
    cd = SourceFileLoader('cephadm', 'cephadm.py').load_module()


@pytest.fixture
def enclosure(host_sysfs):
    e = cd.Enclosure(
        enc_id='1',
        enc_path='/sys/class/scsi_generic/sg2/device/enclosure/0:0:1:0',
        dev_path='/sys/class/scsi_generic/sg2')
    yield e


class TestEnclosure:

    def test_enc_metadata(self, enclosure):
        """Check metadata for the enclosure e.g. vendor and model"""
       
        assert enclosure.vendor == "EnclosuresInc"
        assert enclosure.components == '12'
        assert enclosure.model == "D12"
        assert enclosure.enc_id == '1'

        assert enclosure.ses_paths == ['sg2']
        assert enclosure.path_count == 1

    def test_enc_slots(self, enclosure):
        """Check slot count"""

        assert len(enclosure.slot_map) == 12

    def test_enc_slot_format(self, enclosure):
        """Check the attributes of a slot are as expected"""

        assert all(k in ['fault', 'locate', 'serial', 'status'] 
                   for k, _v in enclosure.slot_map['0'].items())

    def test_enc_slot_status(self, enclosure):
        """Check the number of occupied slots is correct"""

        occupied_slots = [slot_id for slot_id in enclosure.slot_map 
                          if enclosure.slot_map[slot_id].get('status').upper() == 'OK']

        assert len(occupied_slots) == 6

    def test_enc_disk_count(self, enclosure):
        """Check the disks found matches the slot info"""

        assert len(enclosure.device_lookup) == 6
        assert enclosure.device_count == 6

    def test_enc_device_serial(self, enclosure):
        """Check the device serial numbers are as expected"""
        
        assert all(fake_serial in enclosure.device_lookup.keys() 
                   for fake_serial in [
                       'fake000',
                       'fake001',
                       'fake002',
                       'fake003',
                       'fake004',
                       'fake005'])

    def test_enc_slot_to_serial(self, enclosure):
        """Check serial number to slot matches across slot_map and device_lookup"""

        for serial, slot in enclosure.device_lookup.items():
            assert enclosure.slot_map[slot].get('serial') == serial
