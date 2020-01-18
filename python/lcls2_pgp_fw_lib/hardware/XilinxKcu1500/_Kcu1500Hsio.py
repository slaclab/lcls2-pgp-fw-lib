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

import lcls2_pgp_fw_lib.hardware.XilinxKcu1500

import surf.protocols.pgp 
import surf.axi


class Kcu1500Hsio(pr.Device):
    def __init__(self,       
                 numLanes = 4,
                 pgp3     = False,
                 **kwargs):
        
        super().__init__(**kwargs)

        # Add PGP Core 
        for i in range(numLanes):
        
            if (pgp3):
                self.add(surf.protocols.pgp.Pgp3AxiL(            
                    name    = (f'PgpMon[{i}]'), 
                    offset  = (i*0x00010000), 
                    numVc   = 4,
                    writeEn = True,
                    expand  = False,
                ))
                
            else:
                self.add(surf.protocols.pgp.Pgp2bAxi(            
                    name    = (f'PgpMon[{i}]'), 
                    offset  = (i*0x00010000), 
                    writeEn = True,
                    expand  = False,
                ))
        
            self.add(surf.axi.AxiStreamMonAxiL(            
                name        = (f'PgpTxAxisMon[{i}]'), 
                offset      = (i*0x00010000 + 1*0x2000), 
                numberLanes = 4,
                expand      = False,
            ))        

            self.add(surf.axi.AxiStreamMonAxiL(            
                name        = (f'PgpRxAxisMon[{i}]'), 
                offset      = (i*0x00010000 + 2*0x2000), 
                numberLanes = 4,
                expand      = False,
            ))           
            
        # Add Timing Core
        self.add(lcls2_pgp_fw_lib.hardware.XilinxKcu1500.Kcu1500TimingRx(
            offset  = 0x0010_0000,
            numLanes = numLanes,
            expand  = True,
        ))
        
