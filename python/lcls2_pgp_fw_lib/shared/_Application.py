#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# This file is part of the 'Camera link gateway'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Camera link gateway', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

import surf.protocols.batcher as batcher

class AppLane(pr.Device):
    def __init__(   self,
            name        = "AppLane",
            description = "PCIe Application Lane Container",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        #######################################
        # SLAVE[INDEX=0][TDEST=0] = XPM Trigger
        # SLAVE[INDEX=0][TDEST=1] = XPM Event Transition
        # SLAVE[INDEX=1][TDEST=2] = Camera Image
        # SLAVE[INDEX=2][TDEST=3] = XPM Timing
        #######################################
        self.add(batcher.AxiStreamBatcherEventBuilder(
            name         = 'EventBuilder',
            offset       = 0x0_0000,
            numberSlaves = 3, # Total number of slave indexes (not necessarily same as TDEST)
            tickUnit     = '156.25MHz',
            expand       = True,
        ))

        self.add(pr.RemoteVariable(
            name         = 'VcDataTap',
            description  = 'Selects the VC used for the AxiStreamBatcherEventBuilder',
            offset       = 0x1_0100,
            bitSize      = 2,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'XpmPauseThresh',
            description  = 'Threshold in unit of AXIS words (8 bytes per word).  The XPM is 48byte message. So setting this register to 0x7 would NOT back pressure until there is two message in the pipeline',
            offset       = 0x1_0104,
            bitSize      = 9,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'ClinkDecaMode',
            description  = '0: normal mode (no touching data), 1: cameralink-gateway DECA mode data that needs PCIe FW to add zero padding',
            offset       = 0x1_0108,
            bitSize      = 1,
            mode         = 'RW',
        ))

class Application(pr.Device):
    def __init__(   self,
            name        = "Application",
            description = "PCIe Lane Container",
            numLanes    = 4, # number of PGP Lanes
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        for i in range(numLanes):

            self.add(AppLane(
                name   = ('AppLane[%i]' % i),
                offset = (i*0x0008_0000),
                expand = True,
            ))

class ApplicationLaneConfigDict(pr.Device):
    def __init__(   self,
            name        = "Application",
            description = "PCIe Lane Container",
            laneConfig  = {0: 'Opal1000'},
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        for i in laneConfig:
            self.add(AppLane(
                name   = f'AppLane[{i}]',
                offset = (i*0x0008_0000),
                expand = True,
            ))
