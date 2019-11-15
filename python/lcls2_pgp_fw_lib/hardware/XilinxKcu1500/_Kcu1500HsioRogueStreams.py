import rogue

class Kcu1500HsioRogueStreams(object):
    def __init__(self,
                 host     = 'localhost',
                 basePort = 7000,
                 numLanes = 4,
                 pgp3     = False,
                 **kwargs):

        trigIndex = 32 if pgp3 else 8
        self.pgpStreams = [[rogue.interfaces.stream.TcpClient(host, basePort+(34*lane)+2*vc)] for vc in range(4) for lane in range(numLanes)]
        self.pgpTriggers = [rogue.interfaces.stream.TcpClient(host, basePort+(34*lane)+trigIndex) for lane in range(numLanes)]
