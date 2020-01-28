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

import lcls2_pgp_fw_lib.hardware.shared as shared

import surf.protocols.pgp as pgp
import surf.axi           as axi

class XilinxKcu1500Hsio(pr.Device):
    def __init__(self,       
                 numLanes = 4,
                 pgp3     = False,
                 **kwargs):
        
        super().__init__(**kwargs)

        # Add PGP Core 
        for i in range(numLanes):
        
            if (pgp3):
                self.add(pgp.Pgp3AxiL(            
                    name    = (f'PgpMon[{i}]'), 
                    offset  = (i*0x00010000), 
                    numVc   = 4,
                    writeEn = True,
                ))
                
            else:
                self.add(pgp.Pgp2bAxi(            
                    name    = (f'PgpMon[{i}]'), 
                    offset  = (i*0x00010000), 
                    writeEn = True,
                ))
        
            self.add(axi.AxiStreamMonAxiL(            
                name        = (f'PgpTxAxisMon[{i}]'), 
                offset      = (i*0x00010000 + 1*0x2000), 
                numberLanes = 4,
            ))        

            self.add(axi.AxiStreamMonAxiL(            
                name        = (f'PgpRxAxisMon[{i}]'), 
                offset      = (i*0x00010000 + 2*0x2000), 
                numberLanes = 4,
            ))           
            
        # Add Timing Core
        self.add(shared.TimingRx(
            offset   = 0x0010_0000,
            numLanes = numLanes,
        ))
        