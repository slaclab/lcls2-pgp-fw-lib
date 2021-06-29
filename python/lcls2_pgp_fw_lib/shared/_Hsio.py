#-----------------------------------------------------------------------------
# This file is part of the LCLS2 PGP Firmware Library'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the LCLS2 PGP Firmware Library', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

import surf.protocols.pgp      as pgp
import surf.axi                as axi
import lcls2_pgp_fw_lib.shared as shared

class Hsio(pr.Device):
    def __init__(
            self,
            laneConfig = {0: 'Opal1000'},
            enLclsI     = False,
            enLclsII    = True,
            pgp4        = False,
            **kwargs):

        super().__init__(**kwargs)

        # Add PGP Core
        for i in laneConfig:

            if (pgp4):
                self.add(pgp.Pgp4AxiL(
                    name            = (f'PgpMon[{i}]'),
                    offset          = (i*0x00010000),
                    numVc           = 4,
                    statusCountBits = 12,
                    errorCountBits  = 8,
                    writeEn         = True,
                ))

            else:
                self.add(pgp.Pgp2bAxi(
                    name            = (f'PgpMon[{i}]'),
                    offset          = (i*0x00010000),
                    statusCountBits = 12,
                    errorCountBits  = 8,
                    writeEn         = True,
                ))

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'PgpRxAxisMon[{i}]'),
                offset      = (i*0x00010000 + 1*0x2000),
                numberLanes = 4,
            ))

        # Add Timing Core
        self.add(shared.TimingRx(
            name     = 'TimingRx',
            offset   = 0x0010_0000,
            enLclsI  = enLclsI,
            enLclsII = enLclsII,
        ))
