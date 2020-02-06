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

from lcls2_pgp_fw_lib.hardware.shared import Hsio
from lcls2_pgp_fw_lib.hardware.SlacPgpCardG4 import SlacPgpCardG4TimingRx


class SlacPgpCardG4Hsio(Hsio):
    def __init__(self,       
                 numLanes = 8,
                 pgp3     = False,
                 **kwargs):
        
        super().__init__(timingRxCls=SlacPgpCardG4TimingRx,
                         numLanes=numLanes,
                         pgp3=pgp3,
                         **kwargs)
