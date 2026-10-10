"""Bounded mutation tests for the R5 independent source verifier.

The temporary fixture intentionally has no copper route. These tests exercise
structural rejection, not electrical continuity or a manufacturing release.
"""
from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest

from altium_r5_documents import build_pcb
from verify_altium_r5 import Audit,check_model,check_pcb

ROOT=Path(__file__).resolve().parents[1]


class R5ReadbackTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.design=json.loads((ROOT/'hardware/altium-r5/orion-r5-design.json').read_text('utf8'))
        cls.temp=tempfile.TemporaryDirectory(prefix='r5-readback-tests-',dir=ROOT/'tmp')
        cls.source=Path(cls.temp.name)/'Unrouted-structural-fixture.PcbDoc'
        build_pcb(cls.design,cls.source,{'tracks':[],'vias':[],'regions':[]})
        cls.raw=cls.source.read_text('cp1252')

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def model_errors(self,data):
        a=Audit();check_model(a,data);return a.errors

    def source_errors(self,raw):
        path=Path(self.temp.name)/(self._testMethodName+'.PcbDoc')
        path.write_text(raw,encoding='cp1252')
        a=Audit();check_pcb(a,path,self.design,{c['ref']:c for c in self.design['components']})
        return a.errors

    def test_positive_source_and_model(self):
        self.assertEqual(self.model_errors(self.design),[])
        self.assertEqual(self.source_errors(self.raw),[])

    def test_swapped_module_signal_is_rejected(self):
        data=deepcopy(self.design);m=next(c for c in data['components'] if c['ref']=='MCU1')
        next(p for p in m['pins'] if p['number']=='6')['net']='GPIO7'
        self.assertTrue(any('MCU1: pin/net functions differ' in e for e in self.model_errors(data)))

    def test_module_header_hole_is_rejected(self):
        data=deepcopy(self.design);m=next(c for c in data['components'] if c['ref']=='MCU1')
        m['pcb_footprint']['pads'][0]['drill']=1.0
        self.assertTrue(any('castellated land geometry changed' in e for e in self.model_errors(data)))

    def test_module_paste_is_rejected(self):
        data=deepcopy(self.design);m=next(c for c in data['components'] if c['ref']=='MCU1')
        m['pcb_footprint']['pads'][0]['paste']=True
        self.assertTrue(any('suppress stencil paste' in e for e in self.model_errors(data)))

    def test_drawn_window_without_real_cutout_is_rejected(self):
        self.assertIn('|ISBOARDCUTOUT=TRUE',self.raw)
        changed=self.raw.replace('|ISBOARDCUTOUT=TRUE','|ISBOARDCUTOUT=FALSE')
        self.assertTrue(any('actual board cutout' in e for e in self.source_errors(changed)))

    def test_stroke_text_substitution_is_rejected(self):
        changed=self.raw.replace('|USETTFONTS=TRUE','|USETTFONTS=FALSE')
        self.assertTrue(any('actual TrueType Text' in e for e in self.source_errors(changed)))

    def test_schematic_pcb_uid_mismatch_is_rejected(self):
        uid=next(c['uid'] for c in self.design['components'] if c['ref']=='MCU1')
        changed=self.raw.replace('|SOURCEUNIQUEID='+uid,'|SOURCEUNIQUEID=BADUID01')
        if changed==self.raw:
            changed=self.raw.replace('|SOURCEUNIQUEID=\\'+uid,'|SOURCEUNIQUEID=\\BADUID01')
        self.assertNotEqual(changed,self.raw)
        self.assertTrue(any('MCU1: schematic/PCB UID mismatch' in e for e in self.source_errors(changed)))


if __name__=='__main__':unittest.main(verbosity=2)
