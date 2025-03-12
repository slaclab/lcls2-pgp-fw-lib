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

create_generated_clock -name clk119 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_refClkDiv2/O}]
create_generated_clock -name clk186 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_refClkDiv2/O}]

create_clock -period 4.201 -name clk238 [get_ports {sfpRefClkP[0]}]
create_clock -period 2.691 -name clk371 [get_ports {sfpRefClkP[1]}]

##############################################################################

#### GT[0] Clocks
create_generated_clock -name timingGtRxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTH/*/RXOUTCLK}]

create_generated_clock -name timingGtTxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTH/*/TXOUTCLK}]

create_generated_clock -name timingTxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTH/LOCREF_G.TIMING_TXCLK_BUFG_GT/O}]

#### GT[1] Clocks
create_generated_clock -name timingGtRxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTH/*/RXOUTCLK}]

create_generated_clock -name timingGtTxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTH/*/TXOUTCLK}]

create_generated_clock -name timingTxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTH/LOCREF_G.TIMING_TXCLK_BUFG_GT/O}]

##############################################################################
# https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Overlapping-Clocks-Driven-by-a-Clock-Multiplexer
# https://adaptivesupport.amd.com/s/article/59484?language=en_US
##############################################################################

#### Cascaded clock muxing - GEN_VEC[0] RX mux
create_generated_clock -name muxRxClk119 \
    -divide_by 2 -add -master_clock clk238 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_RXCLK/I1}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_RXCLK/O}]

create_generated_clock -name muxTimingGtRxOutClk0 \
    -divide_by 1 -add -master_clock timingGtRxOutClk0 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_RXCLK/I0}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_RXCLK/O}]

set_clock_groups -physically_exclusive -group muxTimingGtRxOutClk0 -group muxRxClk119
set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_RXCLK/CE*}]

#### Cascaded clock muxing - GEN_VEC[0] TX mux
create_generated_clock -name muxTxClk119 \
    -divide_by 2 -add -master_clock clk238 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/I1}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/O}]

create_generated_clock -name muxTimingTxOutClk0 \
    -divide_by 2 -add -master_clock timingGtTxOutClk0 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/I0}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/O}]

set_clock_groups -physically_exclusive -group muxTimingTxOutClk0 -group muxTxClk119
set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/CE*}]


##### Cascaded clock muxing - GEN_VEC[1] RX mux
create_generated_clock -name muxRxClk186 \
    -divide_by 2 -add -master_clock clk371 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_RXCLK/I1}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_RXCLK/O}]

create_generated_clock -name muxTimingGtRxOutClk1 \
    -divide_by 1 -add -master_clock timingGtRxOutClk1 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_RXCLK/I0}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_RXCLK/O}]

set_clock_groups -physically_exclusive -group muxTimingGtRxOutClk1 -group muxRxClk186
set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_RXCLK/CE*}]

##### Cascaded clock muxing - GEN_VEC[1] TX mux
create_generated_clock -name muxTxClk186 \
    -divide_by 2 -add -master_clock clk371 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/I1}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/O}]

create_generated_clock -name muxTimingTxOutClk1 \
    -divide_by 2 -add -master_clock timingGtTxOutClk1 \
    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/I0}] \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/O}]

set_clock_groups -physically_exclusive -group muxTimingTxOutClk1 -group muxTxClk186
set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/CE*}]


###### Cascaded clock muxing - Final RX mux
create_generated_clock -name casMuxRxClk119 \
    -divide_by 1 -add -master_clock muxRxClk119 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/I0}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/O}]

create_generated_clock -name casMuxTimingGtRxOutClk0 \
    -divide_by 1 -add -master_clock muxTimingGtRxOutClk0 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/I0}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/O}]

create_generated_clock -name casMuxRxClk186 \
    -divide_by 1 -add -master_clock muxRxClk186 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/I1}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/O}]

create_generated_clock -name casMuxTimingGtRxOutClk1 \
    -divide_by 1 -add -master_clock muxTimingGtRxOutClk1 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/I1}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/O}]

set_clock_groups -physically_exclusive \
    -group casMuxRxClk119 \
    -group casMuxTimingGtRxOutClk0 \
    -group casMuxRxClk186 \
    -group casMuxTimingGtRxOutClk1

set_false_path -to [get_pins {*/U_TimingRx/U_RXCLK/CE*}]

###### Cascaded clock muxing - Final TX mux
create_generated_clock -name casMuxTxClk119 \
    -divide_by 1 -add -master_clock muxTxClk119 \
    -source [get_pins {*/U_TimingRx/U_TXCLK/I0}] \
    [get_pins {*/U_TimingRx/U_TXCLK/O}]

create_generated_clock -name casMuxTimingTxOutClk0 \
    -divide_by 1 -add -master_clock muxTimingTxOutClk0 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/I0}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/O}]

create_generated_clock -name casMuxTxClk186 \
    -divide_by 1 -add -master_clock muxTxClk186 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/I1}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/O}]

create_generated_clock -name casMuxTimingTxOutClk1 \
    -divide_by 1 -add -master_clock muxTimingTxOutClk1 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/I1}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/O}]

set_clock_groups -physically_exclusive \
    -group casMuxTxClk119 \
    -group casMuxTimingTxOutClk0
    -group casMuxTxClk186 \
    -group casMuxTimingTxOutClk1

set_false_path -to [get_pins {*/U_TimingRx/U_TXCLK/CE*}]

##############################################################################

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {clk156}] \
    -group [get_clocks -include_generated_clocks {timingGtRxOutClk0}] \
    -group [get_clocks -include_generated_clocks {timingGtRxOutClk1}] \
    -group [get_clocks -include_generated_clocks {timingGtTxOutClk0}] \
    -group [get_clocks -include_generated_clocks {timingGtTxOutClk1}] \
    -group [get_clocks -include_generated_clocks {clk238}]  \
    -group [get_clocks -include_generated_clocks {clk371}] \
    -group [get_clocks -include_generated_clocks {dmaClk}]
