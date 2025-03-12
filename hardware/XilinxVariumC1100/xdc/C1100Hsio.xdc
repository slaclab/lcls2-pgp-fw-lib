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

create_generated_clock -name timingStableClk [get_pins {U_HSIO/U_TimingRx/U_stableClk/O}]

##############################################################################

#### GT[0] Clocks
create_generated_clock -name timingGtRxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTY/*/RXOUTCLK}]

create_generated_clock -name timingGtTxOutClk0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTY/*/TXOUTCLK}]

create_generated_clock -name timingGtTxOutClkPcs0 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTY/*/TXOUTCLKPCS}]

#### GT[1] Clocks
create_generated_clock -name timingGtRxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTY/*/RXOUTCLK}]

create_generated_clock -name timingGtTxOutClk1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTY/*/TXOUTCLK}]

create_generated_clock -name timingGtTxOutClkPcs1 \
    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTY/*/TXOUTCLKPCS}]

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

#### Cascaded clock muxing - GEN_VEC[0] TX mux --> refClkDiv2=txOutClk inside TimingGtCoreWrapper for GTY+ implementation

#create_generated_clock -name muxTxClk119 \
#    -divide_by 2 -add -master_clock clk238 \
#    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/I1}] \
#    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/O}]
#
#create_generated_clock -name muxTimingTxOutClk0 \
#    -divide_by 2 -add -master_clock clk238 \
#    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/I0}] \
#    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/O}]
#
#set_clock_groups -physically_exclusive -group muxTimingTxOutClk0 -group muxTxClk119
#set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[0].U_TXCLK/CE*}]


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

##### Cascaded clock muxing - GEN_VEC[1] TX mux --> refClkDiv2=txOutClk inside TimingGtCoreWrapper for GTY+ implementation

#create_generated_clock -name muxTxClk186 \
#    -divide_by 2 -add -master_clock clk371 \
#    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/I1}] \
#    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/O}]
#
#create_generated_clock -name muxTimingTxOutClk1 \
#    -divide_by 2 -add -master_clock clk371 \
#    -source [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/I0}] \
#    [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/O}]
#
#set_clock_groups -physically_exclusive -group muxTimingTxOutClk1 -group muxTxClk186
#set_false_path -to [get_pins -hier -filter {name =~ */U_TimingRx/GEN_VEC[1].U_TXCLK/CE*}]


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

set_false_path -to [get_pins {*/U_TimingRx/GEN_BOTH_CLK.U_RXCLK/CE*}]

###### Cascaded clock muxing - Final TX mux --> refClkDiv2=txOutClk inside TimingGtCoreWrapper for GTY+ implementation

#create_generated_clock -name casMuxTxClk119 \
#    -divide_by 1 -add -master_clock muxTxClk119 \
#    -source [get_pins {*/U_TimingRx/U_TXCLK/I0}] \
#    [get_pins {*/U_TimingRx/U_TXCLK/O}]
#
#create_generated_clock -name casMuxTimingTxOutClk0 \
#    -divide_by 1 -add -master_clock muxTimingTxOutClk0 \
#    -source [get_pins {*/U_TimingRx/U_TXCLK/I0}] \
#    [get_pins {*/U_TimingRx/U_TXCLK/O}]
#
#create_generated_clock -name casMuxTxClk186 \
#    -divide_by 1 -add -master_clock muxTxClk186 \
#    -source [get_pins {*/U_TimingRx/U_TXCLK/I1}] \
#    [get_pins {*/U_TimingRx/U_TXCLK/O}]
#
#create_generated_clock -name casMuxTimingTxOutClk1 \
#    -divide_by 1 -add -master_clock muxTimingTxOutClk1 \
#    -source [get_pins {*/U_TimingRx/U_TXCLK/I1}] \
#    [get_pins {*/U_TimingRx/U_TXCLK/O}]
#
#set_clock_groups -physically_exclusive \
#    -group casMuxTxClk119 \
#    -group casMuxTimingTxOutClk0 \
#    -group casMuxTxClk186 \
#    -group casMuxTimingTxOutClk1

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

set_clock_groups -asynchronous -group [get_clocks {clk156}] -group [get_clocks {timingStableClk}]

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
