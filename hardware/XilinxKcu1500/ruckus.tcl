# Load RUCKUS environment and library
source $::env(RUCKUS_PROC_TCL)

# Load local source Code
loadSource      -lib lcls2_pgp_fw_lib -dir  "$::DIR_PATH/rtl"
loadConstraints -path "$::DIR_PATH/xdc/Kcu1500Hsio.xdc"

# Case the timing on communication protocol
if { [info exists ::env(INCLUDE_PGP4_6G)] == 1 || [info exists ::env(INCLUDE_PGP4_10G)] == 1 } {
   loadConstraints -path "$::DIR_PATH/xdc/Pgp4Timing.xdc"
} else {
   loadConstraints -path "$::DIR_PATH/xdc/Pgp2bTiming.xdc"
}

# Load shared source code
loadRuckusTcl "$::DIR_PATH/../../shared"
