##############################################################################
## This file is part of LCLS2 PGP Firmware Library'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of LCLS2 PGP Firmware Library', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

#######
# PGP #
#######

create_generated_clock -name pgp4PhyRxClk0  [get_pins -hier -filter {name =~ */GEN_LANE[0].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/*/RXOUTCLK}]
create_generated_clock -name pgp4PhyRxClk1  [get_pins -hier -filter {name =~ */GEN_LANE[1].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/*/RXOUTCLK}]
create_generated_clock -name pgp4PhyRxClk2  [get_pins -hier -filter {name =~ */GEN_LANE[2].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/*/RXOUTCLK}]
create_generated_clock -name pgp4PhyRxClk3  [get_pins -hier -filter {name =~ */GEN_LANE[3].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/*/RXOUTCLK}]

create_generated_clock -name pgp4PhyTxClk0  [get_pins -hier -filter {name =~ */GEN_LANE[0].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/*/TXOUTCLK}]
create_generated_clock -name pgp4PhyTxClk1  [get_pins -hier -filter {name =~ */GEN_LANE[1].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/*/TXOUTCLK}]
create_generated_clock -name pgp4PhyTxClk2  [get_pins -hier -filter {name =~ */GEN_LANE[2].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/*/TXOUTCLK}]
create_generated_clock -name pgp4PhyTxClk3  [get_pins -hier -filter {name =~ */GEN_LANE[3].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/*/TXOUTCLK}]

######################
# Timing Constraints #
######################

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp4PhyRxClk0}] \
    -group [get_clocks -include_generated_clocks {pgp4PhyTxClk0}] \
    -group [get_clocks -include_generated_clocks {qsfpRefClkP}] \
    -group [get_clocks -include_generated_clocks {pciRefClkP}] \
    -group [get_clocks -include_generated_clocks {userClkP}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp4PhyRxClk1}] \
    -group [get_clocks -include_generated_clocks {pgp4PhyTxClk1}] \
    -group [get_clocks -include_generated_clocks {qsfpRefClkP}] \
    -group [get_clocks -include_generated_clocks {pciRefClkP}] \
    -group [get_clocks -include_generated_clocks {userClkP}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp4PhyRxClk2}] \
    -group [get_clocks -include_generated_clocks {pgp4PhyTxClk2}] \
    -group [get_clocks -include_generated_clocks {qsfpRefClkP}] \
    -group [get_clocks -include_generated_clocks {pciRefClkP}] \
    -group [get_clocks -include_generated_clocks {userClkP}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp4PhyRxClk3}] \
    -group [get_clocks -include_generated_clocks {pgp4PhyTxClk3}] \
    -group [get_clocks -include_generated_clocks {qsfpRefClkP}] \
    -group [get_clocks -include_generated_clocks {pciRefClkP}] \
    -group [get_clocks -include_generated_clocks {userClkP}]
