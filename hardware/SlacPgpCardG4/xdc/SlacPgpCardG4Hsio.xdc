##############################################################################
## This file is part of 'Camera link gateway'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'Camera link gateway', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################


#### Base Clocks 
create_generated_clock -name clk156 [get_pins {U_axilClk/PllGen.U_Pll/CLKOUT0}] 

create_generated_clock -name clk238 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_REFCLK[0].U_BUFG_GT/O}] 
create_generated_clock -name clk371 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_REFCLK[1].U_BUFG_GT/O}] 

create_generated_clock -name clk119 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_REFCLK[0].U_refClkDiv2/O}] 
create_generated_clock -name clk186 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_REFCLK[1].U_refClkDiv2/O}] 

#### GT Out Clocks
create_clock -name timingGtRxOutClk  -period 5.384 \
    [get_pins -hier -filter {name =~ */U_TimingRx/REAL_PCIE.U_GTH/*/RXOUTCLK}]

create_generated_clock -name timingGtTxOutClk \
    [get_pins -hier -filter {name =~ */U_TimingRx/REAL_PCIE.U_GTH/*/TXOUTCLK}]

create_generated_clock -name timingTxOutClk \
    [get_pins -hier -filter {name =~ */U_TimingRx/REAL_PCIE.U_GTH/LOCREF_G.TIMING_TXCLK_BUFG_GT/O}]

##### Cascaded clock muxing - RX mux
create_generated_clock -name muxRxClk186 \
    -divide_by 1 -add -master_clock clk186 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/U_RXCLK/I1}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/U_RXCLK/O}]

create_generated_clock -name muxTimingGtRxOutClk \
    -divide_by 1 -add -master_clock timingGtRxOutClk \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/U_RXCLK/I0}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/U_RXCLK/O}]

set_clock_groups -physically_exclusive -group muxTimingGtRxOutClk -group muxRxClk186
set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/U_RXCLK/CE*}]

set_clock_groups -physically_exclusive \
    -group muxRxClk186 \
    -group muxTimingGtRxOutClk

##### Cascaded clock muxing - TX mux
create_generated_clock -name muxTxClk186 \
    -divide_by 1 -add -master_clock clk186 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/I1}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/O}]

create_generated_clock -name muxTimingTxOutClk \
    -divide_by 1 -add -master_clock timingTxOutClk \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/I0}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/O}]

set_clock_groups -physically_exclusive -group muxTimingTxOutClk -group muxTxClk186
set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/CE*}]

set_clock_groups -physically_exclusive \
    -group muxTxClk186 \
    -group muxTimingTxOutClk

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {clk156}] \
    -group [get_clocks -include_generated_clocks {timingGtRxOutClk}] \    
    -group [get_clocks -include_generated_clocks {timingGtTxOutClk}] \
    -group [get_clocks -include_generated_clocks {clk238}]  \
    -group [get_clocks -include_generated_clocks {clk371}] \
    -group [get_clocks -include_generated_clocks {dmaClk}] 
