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

from lcls2_pgp_fw_lib.hardware.shared import Hsio
from lcls2_pgp_fw_lib.hardware.XilinxKcu1500 import Kcu1500TimingRx


class Kcu1500Hsio(Hsio):
    def __init__(self,
                 numLanes = 4,
                 enLclsI  = False,
                 enLclsII = True,
                 pgp3     = False,
                 **kwargs):
        
        super().__init__(timingRxCls=Kcu1500TimingRx,
                         numLanes=numLanes,
                         enLclsI=enLclsI,
                         enLclsII=enLclsII,
                         pgp3=pgp3,
                         **kwargs)

