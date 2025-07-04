# Load RUCKUS environment and library
source $::env(RUCKUS_PROC_TCL)

# Load local source Code
loadSource      -lib lcls2_pgp_fw_lib -dir  "$::DIR_PATH/rtl"
loadConstraints -path "$::DIR_PATH/xdc/Kcu1500Hsio.xdc"

# Case the timing on communication protocol
if { [info exists ::env(INCLUDE_PGP4_6G)] != 1 || $::env(INCLUDE_PGP4_6G) == 0 } {
   loadConstraints -path "$::DIR_PATH/xdc/Pgp2bTiming.xdc"
} else {
   loadConstraints -path "$::DIR_PATH/xdc/Pgp4Timing.xdc"
}

# Load shared source code
loadRuckusTcl "$::DIR_PATH/../../shared"
