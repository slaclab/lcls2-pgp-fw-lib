##############################################################################
## This file is part of 'Camera link gateway'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'Camera link gateway', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

create_generated_clock -name pgp2bPhyRxClk0 [get_pins -hier -filter {name =~ */GEN_LANE[0].GEN_PGP2b.U_Lane/*/RXOUTCLK}] 
create_generated_clock -name pgp2bPhyTxClk0 [get_pins -hier -filter {name =~ */GEN_LANE[0].GEN_PGP2b.U_Lane/*/TXOUTCLK}]      

create_generated_clock -name pgp2bPhyRxClk1 [get_pins -hier -filter {name =~ */GEN_LANE[1].GEN_PGP2b.U_Lane/*/RXOUTCLK}] 
create_generated_clock -name pgp2bPhyTxClk1 [get_pins -hier -filter {name =~ */GEN_LANE[1].GEN_PGP2b.U_Lane/*/TXOUTCLK}]      

create_generated_clock -name pgp2bPhyRxClk2 [get_pins -hier -filter {name =~ */GEN_LANE[2].GEN_PGP2b.U_Lane/*/RXOUTCLK}] 
create_generated_clock -name pgp2bPhyTxClk2 [get_pins -hier -filter {name =~ */GEN_LANE[2].GEN_PGP2b.U_Lane/*/TXOUTCLK}]      

create_generated_clock -name pgp2bPhyRxClk3 [get_pins -hier -filter {name =~ */GEN_LANE[3].GEN_PGP2b.U_Lane/*/RXOUTCLK}] 
create_generated_clock -name pgp2bPhyTxClk3 [get_pins -hier -filter {name =~ */GEN_LANE[3].GEN_PGP2b.U_Lane/*/TXOUTCLK}]  

create_generated_clock -name pgp2bPhyRxClk4 [get_pins -hier -filter {name =~ */GEN_LANE[4].GEN_PGP2b.U_Lane/*/RXOUTCLK}] 
create_generated_clock -name pgp2bPhyTxClk4 [get_pins -hier -filter {name =~ */GEN_LANE[4].GEN_PGP2b.U_Lane/*/TXOUTCLK}]      

create_generated_clock -name pgp2bPhyRxClk5 [get_pins -hier -filter {name =~ */GEN_LANE[5].GEN_PGP2b.U_Lane/*/RXOUTCLK}] 
create_generated_clock -name pgp2bPhyTxClk5 [get_pins -hier -filter {name =~ */GEN_LANE[5].GEN_PGP2b.U_Lane/*/TXOUTCLK}]      

create_generated_clock -name pgp2bPhyRxClk6 [get_pins -hier -filter {name =~ */GEN_LANE[6].GEN_PGP2b.U_Lane/*/RXOUTCLK}] 
create_generated_clock -name pgp2bPhyTxClk6 [get_pins -hier -filter {name =~ */GEN_LANE[6].GEN_PGP2b.U_Lane/*/TXOUTCLK}]      

create_generated_clock -name pgp2bPhyRxClk7 [get_pins -hier -filter {name =~ */GEN_LANE[7].GEN_PGP2b.U_Lane/*/RXOUTCLK}] 
create_generated_clock -name pgp2bPhyTxClk7 [get_pins -hier -filter {name =~ */GEN_LANE[7].GEN_PGP2b.U_Lane/*/TXOUTCLK}]      

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp2bPhyRxClk0}] \
    -group [get_clocks -include_generated_clocks {pgp2bPhyTxClk0}] 

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp2bPhyRxClk1}] \
    -group [get_clocks -include_generated_clocks {pgp2bPhyTxClk1}] 

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp2bPhyRxClk2}] \
    -group [get_clocks -include_generated_clocks {pgp2bPhyTxClk2}] 

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp2bPhyRxClk3}] \
    -group [get_clocks -include_generated_clocks {pgp2bPhyTxClk3}] 

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp2bPhyRxClk4}] \
    -group [get_clocks -include_generated_clocks {pgp2bPhyTxClk4}] 

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp2bPhyRxClk5}] \
    -group [get_clocks -include_generated_clocks {pgp2bPhyTxClk5}] 

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp2bPhyRxClk6}] \
    -group [get_clocks -include_generated_clocks {pgp2bPhyTxClk6}] 

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {pgp2bPhyRxClk7}] \
    -group [get_clocks -include_generated_clocks {pgp2bPhyTxClk7}] 
