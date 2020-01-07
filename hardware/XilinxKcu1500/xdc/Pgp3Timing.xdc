##############################################################################
## This file is part of 'Camera link gateway'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'Camera link gateway', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#######
# PGP #
#######

create_generated_clock -name pgp3PhyRxClk0  [get_pins -hier -filter {name =~ */GEN_LANE[0].GEN_PGP3.U_Lane/REAL_PGP.U_Pgp/*/RXOUTCLK}]
create_generated_clock -name pgp3PhyRxClk1  [get_pins -hier -filter {name =~ */GEN_LANE[1].GEN_PGP3.U_Lane/REAL_PGP.U_Pgp/*/RXOUTCLK}]
create_generated_clock -name pgp3PhyRxClk2  [get_pins -hier -filter {name =~ */GEN_LANE[2].GEN_PGP3.U_Lane/REAL_PGP.U_Pgp/*/RXOUTCLK}]
create_generated_clock -name pgp3PhyRxClk3  [get_pins -hier -filter {name =~ */GEN_LANE[3].GEN_PGP3.U_Lane/REAL_PGP.U_Pgp/*/RXOUTCLK}]

create_generated_clock -name pgp3PhyTxClk0  [get_pins -hier -filter {name =~ */GEN_LANE[0].GEN_PGP3.U_Lane/REAL_PGP.U_Pgp/*/TXOUTCLK}]
create_generated_clock -name pgp3PhyTxClk1  [get_pins -hier -filter {name =~ */GEN_LANE[1].GEN_PGP3.U_Lane/REAL_PGP.U_Pgp/*/TXOUTCLK}]
create_generated_clock -name pgp3PhyTxClk2  [get_pins -hier -filter {name =~ */GEN_LANE[2].GEN_PGP3.U_Lane/REAL_PGP.U_Pgp/*/TXOUTCLK}]
create_generated_clock -name pgp3PhyTxClk3  [get_pins -hier -filter {name =~ */GEN_LANE[3].GEN_PGP3.U_Lane/REAL_PGP.U_Pgp/*/TXOUTCLK}]

######################
# Timing Constraints #
######################

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp3PhyRxClk0}] \
    -group [get_clocks -include_generated_clocks {pgp3PhyTxClk0}] \
    -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}] \
    -group [get_clocks -include_generated_clocks {pciRefClkP}] \
    -group [get_clocks -include_generated_clocks {userClkP}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp3PhyRxClk1}] \
    -group [get_clocks -include_generated_clocks {pgp3PhyTxClk1}] \
    -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}] \
    -group [get_clocks -include_generated_clocks {pciRefClkP}] \
    -group [get_clocks -include_generated_clocks {userClkP}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp3PhyRxClk2}] \
    -group [get_clocks -include_generated_clocks {pgp3PhyTxClk2}] \
    -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}] \
    -group [get_clocks -include_generated_clocks {pciRefClkP}] \
    -group [get_clocks -include_generated_clocks {userClkP}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp3PhyRxClk3}] \
    -group [get_clocks -include_generated_clocks {pgp3PhyTxClk3}] \
    -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}] \
    -group [get_clocks -include_generated_clocks {pciRefClkP}] \
    -group [get_clocks -include_generated_clocks {userClkP}]
