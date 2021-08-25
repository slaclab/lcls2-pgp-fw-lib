# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Check for Vivado version 2018.2 (or later)
if { [VersionCheck 2018.2 ] < 0 } {
   exit -1
}

# Check for submodule tagging
if { [info exists ::env(OVERRIDE_SUBMODULE_LOCKS)] != 1 || $::env(OVERRIDE_SUBMODULE_LOCKS) == 0 } {
   if { [SubmoduleCheck {axi-pcie-core}    {3.5.3}  ] < 0 } {exit -1}
   if { [SubmoduleCheck {l2si-core}        {3.3.2}  ] < 0 } {exit -1}
   if { [SubmoduleCheck {lcls-timing-core} {3.2.4}  ] < 0 } {exit -1}
   if { [SubmoduleCheck {ruckus}           {2.9.2}  ] < 0 } {exit -1}
   if { [SubmoduleCheck {surf}             {2.13.0} ] < 0 } {exit -1}
} else {
   puts "\n\n*********************************************************"
   puts "OVERRIDE_SUBMODULE_LOCKS != 0"
   puts "Ignoring the submodule locks in lcls2-pgp-fw-lib/shared/ruckus.tcl"
   puts "*********************************************************\n\n"
}

# Load local source Code
loadSource -lib lcls2_pgp_fw_lib -dir "$::DIR_PATH/rtl"

# Load Simulation
loadSource -lib lcls2_pgp_fw_lib -sim_only -dir "$::DIR_PATH/tb"