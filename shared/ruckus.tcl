# Load RUCKUS environment and library
source $::env(RUCKUS_PROC_TCL)

# Get the family type
set family [getFpgaArch]

# Check for Vivado version 2021.1 (or later)
if { [VersionCheck 2021.1 ] < 0 } {
   exit -1
}

# Check for submodule tagging
if { [info exists ::env(OVERRIDE_SUBMODULE_LOCKS)] != 1 || $::env(OVERRIDE_SUBMODULE_LOCKS) == 0 } {
   if { [SubmoduleCheck {axi-pcie-core}    {3.12.0} ] < 0 } {exit -1}
   if { [SubmoduleCheck {l2si-core}        {3.3.3}  ] < 0 } {exit -1}
   if { [SubmoduleCheck {lcls-timing-core} {3.9.0}  ] < 0 } {exit -1}
   if { [SubmoduleCheck {ruckus}           {4.3.2}  ] < 0 } {exit -1}
   if { [SubmoduleCheck {surf}             {2.53.0} ] < 0 } {exit -1}
} else {
   puts "\n\n*********************************************************"
   puts "OVERRIDE_SUBMODULE_LOCKS != 0"
   puts "Ignoring the submodule locks in lcls2-pgp-fw-lib/shared/ruckus.tcl"
   puts "*********************************************************\n\n"
}

# Load local source Code
loadSource -lib lcls2_pgp_fw_lib -dir "$::DIR_PATH/rtl"

if { ${family} eq {kintexu} } {
   loadSource -lib lcls2_pgp_fw_lib -dir "$::DIR_PATH/rtl/UltraScale"
   loadSource -lib lcls2_pgp_fw_lib -sim_only -dir "$::DIR_PATH/tb"
}

if { ${family} eq {kintexuplus} ||
     ${family} eq {virtexuplus} ||
     ${family} eq {virtexuplusHBM} ||
     ${family} eq {zynquplus} ||
     ${family} eq {zynquplusRFSOC} } {
   loadSource -lib lcls2_pgp_fw_lib -dir "$::DIR_PATH/rtl/UltraScale+"
}
