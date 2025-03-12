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
create_generated_clock -name clk156 [get_pins {U_axilClk/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name clk25  [get_pins {U_userClk25/PllGen.U_Pll/CLKOUT0}]

set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets U_userClk25/clkOut[0]]

create_generated_clock -name clk238 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_MMCM.U_238MHz/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name clk371 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_MMCM.U_371MHz/MmcmGen.U_Mmcm/CLKOUT0}]

create_generated_clock -name clk119 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_refClkDiv2/O}]
create_generated_clock -name clk186 [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_refClkDiv2/O}]

##############################################################################

#### GT[0] Clocks
create_generated_clock -name timingGtRxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].GEN_GT.U_GTY/*/RXOUTCLK}]

create_generated_clock -name timingGtTxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].GEN_GT.U_GTY/*/TXOUTCLK}]

create_generated_clock -name timingGtTxOutClkPcs0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].GEN_GT.U_GTY/*/TXOUTCLKPCS}]

#### GT[1] Clocks
create_generated_clock -name timingGtRxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].GEN_GT.U_GTY/*/RXOUTCLK}]

create_generated_clock -name timingGtTxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].GEN_GT.U_GTY/*/TXOUTCLK}]

create_generated_clock -name timingGtTxOutClkPcs1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].GEN_GT.U_GTY/*/TXOUTCLKPCS}]




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
    -divide_by 2 -add -master_clock clk238 \
    -source [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/I0}] \
    [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_TXCLK/O}]

create_generated_clock -name muxTimingGtTxOutClk1 \
    -divide_by 2 -add -master_clock clk371 \
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
    -group [get_clocks -include_generated_clocks {clk238}]  \
    -group [get_clocks -include_generated_clocks {clk371}] \
    -group [get_clocks -include_generated_clocks {dmaClk}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {clk119}] \
    -group [get_clocks -include_generated_clocks {timingGtTxOutClkPcs0}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {clk186}] \
    -group [get_clocks -include_generated_clocks {timingGtTxOutClkPcs1}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {clk156}] \
    -group [get_clocks -of_objects [get_pins {*/U_TimingRx/U_stableClk/O}]]
