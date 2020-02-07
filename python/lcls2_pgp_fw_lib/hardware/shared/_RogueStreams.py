#-----------------------------------------------------------------------------
# This file is part of the LCLS2 PGP Firmware Library'. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the LCLS2 PGP Firmware Library', including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import rogue
import pyrogue.interfaces.simulation

class RogueStreams(object):
    def __init__(self,
                 host     = 'localhost',
                 basePort = 7000,
                 numLanes = 4,
                 pgp3     = False,
                 **kwargs):

        trigIndex = 32 if pgp3 else 8
        self.pgpStreams = [[rogue.interfaces.stream.TcpClient(host, basePort+(34*lane)+2*vc) for vc in range(4)] for lane in range(numLanes)]
        self.pgpTriggers = [pyrogue.interfaces.simulation.SideBandSim(host, basePort+(34*lane)+trigIndex) for lane in range(numLanes)]
