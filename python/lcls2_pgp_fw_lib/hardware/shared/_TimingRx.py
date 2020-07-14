#-----------------------------------------------------------------------------
# This file is part of the LCLS2 PGP Firmware Library'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the LCLS2 PGP Firmware Library', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------
import time

import pyrogue as pr

import LclsTimingCore

import l2si_core

import lcls2_pgp_fw_lib.hardware.shared as shared

class TimingRx(pr.Device):
    def __init__(
            self,
            numLanes = 4,
            dualGTH  = True,
            enLclsI  = False,
            enLclsII = True,
            **kwargs):
        super().__init__(**kwargs)

        self.add(LclsTimingCore.GthRxAlignCheck(
            name   = "GthRxAlignCheck[0]",
            offset = 0x0000_0000,
            expand = False,
            hidden = True,
        ))

        if dualGTH:
            self.add(LclsTimingCore.GthRxAlignCheck(
                name   = "GthRxAlignCheck[1]",
                offset = 0x0001_0000,
                expand = False,
                hidden = True,
            ))

        # TimingCore
        self.add(LclsTimingCore.TimingFrameRx(
            offset = 0x0008_0000,
            expand = False,
        ))

        # XPM Mini Core
        self.add(l2si_core.XpmMiniWrapper(
            offset = 0x0003_0000,
            expand = True,
        ))

        self.add(l2si_core.TriggerEventManager(
            offset  = 0x0004_0000,
            numDetectors = numLanes,
            enLclsI = enLclsI,
            enLclsII = enLclsII,
            expand  = True,
        ))

        self.add(shared.TimingPhyMonitor(
            offset  = 0x0002_0000,
            numLanes = numLanes,
            expand  = False,
        ))

        @self.command(description="Configure for LCLS-I Timing (119 MHz based)")
        def ConfigLclsTimingV1():
            print ( 'ConfigLclsTimingV1()' )
            self.TimingPhyMonitor.UseMiniTpg.set(False)
            self.TimingFrameRx.ModeSelEn.setDisp('UseClkSel')
            self.TimingFrameRx.RxPllReset.set(1)
            time.sleep(1.0)
            self.TimingFrameRx.RxPllReset.set(0)
            self.TimingFrameRx.ClkSel.set(0x0)
            self.TimingFrameRx.C_RxReset()
            time.sleep(0.1)
            self.TimingFrameRx.RxDown.set(0) # Reset the latching register

        @self.command(description="Configure for LCLS-II Timing (186 MHz based)")
        def ConfigLclsTimingV2():
            print ( 'ConfigLclsTimingV2()' )
            self.TimingPhyMonitor.UseMiniTpg.set(False)
            self.TimingFrameRx.ModeSelEn.setDisp('UseClkSel')
            self.TimingFrameRx.RxPllReset.set(1)
            time.sleep(1.0)
            self.TimingFrameRx.RxPllReset.set(0)
            self.TimingFrameRx.ClkSel.set(0x1)
            self.TimingFrameRx.C_RxReset()
            time.sleep(0.1)
            self.TimingFrameRx.RxDown.set(0) # Reset the latching register

        @self.command()
        def ConfigureXpmMini():
            print ( 'ConfigureXpmMini()' )
            self.ConfigLclsTimingV2()
            self.TimingPhyMonitor.UseMiniTpg.set(True)
            self.XpmMiniWrapper.XpmMini.HwEnable.set(True)
            self.XpmMiniWrapper.XpmMini.Link.set(0)
            self.XpmMiniWrapper.XpmMini.Config_L0Select_RateSel.set(5)
            self.XpmMiniWrapper.XpmMini.Config_L0Select_Enabled.set(False)

        @self.command()
        def ConfigureTpgMiniStream():
            print ( 'ConfigureTpgMiniStream()' )
            self.ConfigLclsTimingV1()
            self.TimingPhyMonitor.UseMiniTpg.set(True)
