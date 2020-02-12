##############################################################################
## This file is part of LCLS2 PGP Firmware Library'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of LCLS2 PGP Firmware Library', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#### Base Clocks 
create_generated_clock -name clk156 [get_pins {U_axilClk/PllGen.U_Pll/CLKOUT0}] 

create_generated_clock -name clk119 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_REFCLK[0].U_refClkDiv2/O}] 
create_generated_clock -name clk186 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_REFCLK[1].U_refClkDiv2/O}] 

#### GT Out Clocks
create_clock -name timingGtRxOutClk  -period 5.382 \
    [get_pins -hier -filter {name =~ */U_TimingRx/REAL_PCIE.U_GTH/*/RXOUTCLK}]

create_clock -name timingGtTxOutClk  -period 5.382 \
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

set_clock_groups -physically_exclusive -group [get_clocks timingGtRxOutClk] -group [get_clocks muxRxClk186]
set_clock_groups -physically_exclusive -group [get_clocks muxRxClk186] -group [get_clocks muxTimingGtRxOutClk]
set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/U_RXCLK/CE*}]

##### Cascaded clock muxing - TX mux
create_generated_clock -name muxTxClk186 \
    -divide_by 1 -add -master_clock clk186 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/I1}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/O}]

create_generated_clock -name muxTimingTxOutClk \
    -divide_by 1 -add -master_clock timingTxOutClk \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/I0}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/O}]

set_clock_groups -physically_exclusive -group [get_clocks muxTimingTxOutClk] -group [get_clocks muxTxClk186]
set_clock_groups -physically_exclusive -group [get_clocks muxTxClk186] -group [get_clocks -of_objects [get_pins U_HSIO/U_TimingRx/REAL_PCIE.U_GTH/LOCREF_G.TIMING_TXCLK_BUFG_GT/O]]
set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/U_TXCLK/CE*}]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks muxTxClk186]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks muxRxClk186]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks muxTimingGtRxOutClk]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks muxTimingTxOutClk]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks timingGtRxOutClk]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_HSIO/U_TimingRx/REAL_PCIE.U_GTH/LOCREF_G.TIMING_TXCLK_BUFG_GT/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Core/REAL_PCIE.U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/U0/gt_top_i/phy_clk_i/bufg_gt_userclk/O]]

set_clock_groups -asynchronous -group [get_clocks sfpRefClkP0] -group [get_clocks -of_objects [get_pins {U_HSIO/U_TimingRx/GEN_REFCLK[0].U_refClkDiv2/O}]]
set_clock_groups -asynchronous -group [get_clocks sfpRefClkP1] -group [get_clocks -of_objects [get_pins {U_HSIO/U_TimingRx/GEN_REFCLK[1].U_refClkDiv2/O}]]

set_clock_groups -asynchronous -group [get_clocks muxRxClk186] -group [get_clocks muxTimingTxOutClk]
set_clock_groups -asynchronous -group [get_clocks muxTimingGtRxOutClk] -group [get_clocks muxTimingTxOutClk]
set_clock_groups -asynchronous -group [get_clocks muxTimingGtRxOutClk] -group [get_clocks muxTxClk186]
