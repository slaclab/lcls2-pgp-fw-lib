#-----------------------------------------------------------------------------
# This file is part of the LCLS2 PGP Firmware Library'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the LCLS2 PGP Firmware Library', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

from lcls2_pgp_fw_lib.hardware.shared import TimingRx

class SlacPgpCardG4TimingRx(TimingRx):
    def __init__(self, numLanes = 4, **kwargs):
        super().__init__(numLanes=numLanes, dualGTH=False, **kwargs)
