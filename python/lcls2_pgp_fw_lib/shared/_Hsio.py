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
import axipcie                 as pcie
import lcls2_pgp_fw_lib.shared as shared

class Hsio(pr.Device):
    def __init__(
            self,
            laneConfig = {0: 'Opal1000'},
            enLclsI     = False,
            enLclsII    = True,
            pgp4        = False,
            boardType   = None,
            **kwargs):

        if (boardType is not None) and (boardType not in pcie.GT_CHANNEL_CLASS):
            raise ValueError(f'boardType={boardType} not in {list(pcie.GT_CHANNEL_CLASS)}')

        super().__init__(**kwargs)

        # Add PGP Core
        for i in laneConfig:

            if (pgp4):
                pgpMon = pgp.Pgp4AxiL(
                    name            = (f'PgpMon[{i}]'),
                    offset          = (i*0x00010000),
                    numVc           = 4,
                    statusCountBits = 12,
                    errorCountBits  = 8,
                    writeEn         = True,
                )
                self.add(pgpMon)

            else:
                self.add(pgp.Pgp2bAxi(
                    name            = (f'PgpMon[{i}]'),
                    offset          = (i*0x00010000),
                    statusCountBits = 12,
                    errorCountBits  = 8,
                    writeEn         = True,
                ))

            # Add GT DRP (skipped if boardType=None)
            if (boardType is not None):
                gt = pcie.GT_CHANNEL_CLASS[boardType](
                    name    = (f'PgpGtDrp[{i}]'),
                    offset  = (i*0x00010000 + 0x1000),
                    expand  = False,
                )
                self.add(gt)

                # Eye scan resets the PGP4 RX path to bring its sampler alive (registration only, no hardware access)
                if pgp4 and hasattr(gt, 'EyeScan'):
                    pgp.Pgp4EyeScanLink.connectRxReset(gt, pgpMon)

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'PgpRxVcMon[{i}]'),
                offset      = (i*0x00010000 + 1*0x2000),
                numberLanes = 4,
            ))

            self.add(axi.AxiStreamMonAxiL(
                name        = (f'PgpTxVcMon[{i}]'),
                offset      = (i*0x00010000 + 2*0x2000),
                numberLanes = 4,
            ))

        # Add Timing Core
        self.add(shared.TimingRx(
            name     = 'TimingRx',
            offset   = 0x0010_0000,
            enLclsI  = enLclsI,
            enLclsII = enLclsII,
        ))
