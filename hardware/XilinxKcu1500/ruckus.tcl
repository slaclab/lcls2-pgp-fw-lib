# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local source Code 
loadSource      -dir "$::DIR_PATH/rtl"
loadConstraints -dir "$::DIR_PATH/xdc"

# Load shared source code
loadRuckusTcl "$::DIR_PATH/../../shared"
