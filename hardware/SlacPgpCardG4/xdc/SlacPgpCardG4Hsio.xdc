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

##############################################################################

#### GT[0] Clocks
create_generated_clock -name timingGtRxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].GEN_GT.U_GTH/*/RXOUTCLK}]

create_generated_clock -name timingGtTxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].GEN_GT.U_GTH/*/TXOUTCLK}]

create_generated_clock -name timingTxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].GEN_GT.U_GTH/LOCREF_G.TIMING_TXCLK_BUFG_GT/O}]

#### GT[1] Clocks
create_generated_clock -name timingGtRxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].GEN_GT.U_GTH/*/RXOUTCLK}]

create_generated_clock -name timingGtTxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].GEN_GT.U_GTH/*/TXOUTCLK}]

create_generated_clock -name timingTxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].GEN_GT.U_GTH/LOCREF_G.TIMING_TXCLK_BUFG_GT/O}]

##############################################################################
# https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Overlapping-Clocks-Driven-by-a-Clock-Multiplexer
##############################################################################

###### RX MUX
create_generated_clock -name muxTimingGtRxOutClk0 \
    -divide_by 1 -add -master_clock timingGtRxOutClk0 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/I0}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/O}]

create_generated_clock -name muxTimingGtRxOutClk1 \
    -divide_by 1 -add -master_clock timingGtRxOutClk1 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/I1}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/O}]

set_clock_groups -physically_exclusive -group [get_clocks {muxTimingGtRxOutClk0}] -group [get_clocks {muxTimingGtRxOutClk1}]
set_false_path -to [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/CE*}]

###### TX MUX
create_generated_clock -name muxTimingGtTxOutClk0 \
    -divide_by 2 -add -master_clock timingGtTxOutClk0 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/I0}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/O}]

create_generated_clock -name muxTimingGtTxOutClk1 \
    -divide_by 2 -add -master_clock timingGtTxOutClk1 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/I1}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/O}]

set_clock_groups -physically_exclusive -group [get_clocks {muxTimingGtTxOutClk0}] -group [get_clocks {muxTimingGtTxOutClk1}]
set_false_path -to [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/CE*}]

##############################################################################

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {clk156}] \
    -group [get_clocks -include_generated_clocks {timingGtRxOutClk0}] \
    -group [get_clocks -include_generated_clocks {timingGtRxOutClk1}] \
    -group [get_clocks -include_generated_clocks {timingGtTxOutClk0}] \
    -group [get_clocks -include_generated_clocks {timingGtTxOutClk1}] \
    -group [get_clocks -include_generated_clocks {sfpRefClkP0}]  \
    -group [get_clocks -include_generated_clocks {sfpRefClkP1}] \
    -group [get_clocks -include_generated_clocks {dmaClk}]
