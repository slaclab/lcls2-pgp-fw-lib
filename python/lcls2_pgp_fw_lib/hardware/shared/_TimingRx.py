#!/usr/bin/env python
##############################################################################
## This file is part of 'camera-link-gen1'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'camera-link-gen1', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################
import time

import pyrogue as pr

import LclsTimingCore 

import l2si_core

import lcls2_pgp_fw_lib.hardware.shared as shared
  
class TimingRx(pr.Device):
    def __init__(self, 
        numLanes = 4, 
        dualGTH  = True, 
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
            self.TimingFrameRx.RxPllReset.set(1)
            time.sleep(1.0)
            self.TimingFrameRx.RxPllReset.set(0)
            self.TimingFrameRx.ClkSel.set(0x0)
            self.TimingFrameRx.RxReset.set(1)
            self.TimingFrameRx.RxReset.set(0)
            time.sleep(0.1)
            self.TimingFrameRx.RxDown.set(0) # Reset the latching register
            
        @self.command(description="Configure for LCLS-II Timing (186 MHz based)")
        def ConfigLclsTimingV2():
            print ( 'ConfigLclsTimingV2()' ) 
            self.TimingFrameRx.RxPllReset.set(1)
            time.sleep(1.0)
            self.TimingFrameRx.RxPllReset.set(0)
            self.TimingFrameRx.ClkSel.set(0x1)
            self.TimingFrameRx.RxReset.set(1)
            self.TimingFrameRx.RxReset.set(0)     
            time.sleep(0.1)
            self.TimingFrameRx.RxDown.set(0) # Reset the latching register

        @self.command()
        def ConfigureXpmMiniSim():
            #self.readBlocks()
            self.TimingPhyMonitor.UseMiniTpg.set(True)
            self.XpmMiniWrapper.XpmMini.HwEnable.set(True)
            self.XpmMiniWrapper.XpmMini.Link.set(0)
            self.XpmMiniWrapper.XpmMini.Pipeline_Depth_Fids.set(70)
            self.XpmMiniWrapper.XpmMini.Config_L0Select_RateSel.set(2)
            self.XpmMiniWrapper.XpmMini.Config_L0Select_Enabled.set(0x0)
            self.TriggerEventManager.TriggerEventBuffer[0].MasterEnable.set(True)
            self.TriggerEventManager.TriggerEventBuffer[0].EventBufferEnable.set(True)
