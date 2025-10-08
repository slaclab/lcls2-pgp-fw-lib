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
import click

import pyrogue as pr

import LclsTimingCore

import l2si_core

import lcls2_pgp_fw_lib.shared as shared
import surf.xilinx             as xil

class TimingRx(pr.Device):
    def __init__(
            self,
            enLclsI  = False,
            enLclsII = True,
            numDetectors = 8,
            **kwargs):
        super().__init__(**kwargs)

        self.add(xil.GtRxAlignCheck(
            name   = "GtRxAlignCheck[0]",
            offset = 0x0000_0000,
            expand = False,
            hidden = False,
        ))

        self.add(xil.GtRxAlignCheck(
            name   = "GtRxAlignCheck[1]",
            offset = 0x0001_0000,
            expand = False,
            hidden = False,
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
            offset       = 0x0004_0000,
            numDetectors = numDetectors,
            enLclsI      = enLclsI,
            enLclsII     = enLclsII,
            expand       = True,
        ))

        self.add(shared.TimingPhyMonitor(
            offset  = 0x0002_0000,
            expand  = False,
        ))

        @self.command(description="Configure for LCLS-I Timing (119 MHz based)")
        def ConfigLclsTimingV1():
            print ( 'ConfigLclsTimingV1()' )
            self.ConfigLclsTimingBase(ClkSel=0, UseMiniTpg=False)

        @self.command(description="Configure for LCLS-II Timing (186 MHz based)")
        def ConfigLclsTimingV2():
            print ( 'ConfigLclsTimingV2()' )
            self.ConfigLclsTimingBase(ClkSel=1, UseMiniTpg=False)

        @self.command()
        def ConfigureXpmMini():
            print ( 'ConfigureXpmMini()' )
            self.ConfigLclsTimingBase(ClkSel=1, UseMiniTpg=True)
            self.XpmMiniWrapper.XpmMini.HwEnable.set(True)
            self.XpmMiniWrapper.XpmMini.Link.set(0)
            self.XpmMiniWrapper.XpmMini.Config_L0Select_RateSel.set(5)
            self.XpmMiniWrapper.XpmMini.Config_L0Select_Enabled.set(False)

        @self.command()
        def ConfigureTpgMiniStream():
            print ( 'ConfigureTpgMiniStream()' )
            self.ConfigLclsTimingBase(ClkSel=0, UseMiniTpg=True)

    def LockProc(self, cmd, var, lockValue, stable10ms=10, timeout10ms=500, retry=1):
        retryCnt = 0
        while retryCnt < retry:

            # Execute the command
            cmd()

            # Stability condition
            stable_required = stable10ms
            stable_counter = 0

            # Abort after timeout10ms if stability not achieved
            timeout_limit = timeout10ms
            timeout_counter = 0

            while timeout_counter < timeout_limit:
                if var.get() == lockValue:
                    stable_counter += 1
                    if stable_counter >= stable_required:
                        return False  # Link is stable for 1 second
                else:
                    stable_counter = 0  # Reset if unstable

                timeout_counter += 1
                time.sleep(0.01)

            # Increment the counter
            retryCnt += 1

        click.secho( f'{self.path}.LockProc[{var.name}] - Timeout: variable not locked or stable', fg='red')
        return True

    def ConfigLclsTimingBase(self, ClkSel, UseMiniTpg):
        # Configure the timing mode
        self.TimingFrameRx.ModeSelEn.setDisp('UseClkSel')
        self.TimingFrameRx.ClkSel.set(ClkSel)
        self.TimingPhyMonitor.UseMiniTpg.set(UseMiniTpg)

        # Reset the MMCM (reference clocks)
        self.LockProc(
            cmd        = self.TimingPhyMonitor.MmcmRst,
            var        = self.TimingPhyMonitor.MmcmLocked,
            lockValue  = 0x3,
        )

        # Reset the TX PHY
        self.LockProc(
            cmd        = self.TimingPhyMonitor.TxPhyPllReset,
            var        = self.TimingPhyMonitor.TxRstStatus,
            lockValue  = 0x0,
        )
        self.LockProc(
            cmd        = self.TimingPhyMonitor.TxPhyReset,
            var        = self.TimingPhyMonitor.TxRstStatus,
            lockValue  = 0x0,
        )

        # Reset the TX User Logic
        self.LockProc(
            cmd        = self.TimingPhyMonitor.TxUserRst,
            var        = self.TimingPhyMonitor.TxRstStatus,
            lockValue  = 0x0,
        )

        # Reset the RX User logic
        self.LockProc(
            cmd        = self.TimingPhyMonitor.RxUserRst,
            var        = self.TimingPhyMonitor.RxRstStatus,
            lockValue  = 0x0,
            stable10ms = 50,
        )

        # Wait for RX link lock
        self.LockProc(
            cmd        = self.TimingPhyMonitor.RxUserRst,
            var        = self.TimingFrameRx.RxLinkUp,
            lockValue  = 0x1,
            stable10ms = 50,
            retry      = 3,
        )

        # Reset the latching register
        self.TimingFrameRx.RxDown.set(0)
