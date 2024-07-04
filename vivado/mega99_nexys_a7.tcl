# Check file required for this script exists
proc checkRequiredFiles { origin_dir} {
  set status true
  set files [list \
 "[file normalize "$origin_dir/gateware/mega99_top_a7.v"]"\
 "[file normalize "$origin_dir/gateware/clkwiz_a7.v"]"\
 "[file normalize "$origin_dir/gateware/mig_wrapper_nexys.v"]"\
 "[file normalize "$origin_dir/gateware/cdc_flag.v"]"\
 "[file normalize "$origin_dir/gateware/ps2com.v"]"\
 "[file normalize "$origin_dir/gateware/keyboard_ps2.v"]"\
 "[file normalize "$origin_dir/gateware/sigmadelta.v"]"\
 "[file normalize "$origin_dir/gateware/sp.v"]"\
 "[file normalize "$origin_dir/gateware/spmem.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio_misc.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio_sdcard.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio_uart.v"]"\
 "[file normalize "$origin_dir/or1k_boot_code0.hex"]"\
 "[file normalize "$origin_dir/or1k_boot_code1.hex"]"\
 "[file normalize "$origin_dir/or1k_boot_code2.hex"]"\
 "[file normalize "$origin_dir/or1k_boot_code3.hex"]"\
 "[file normalize "$origin_dir/gateware/mainboard.v"]"\
 "[file normalize "$origin_dir/gateware/clkgen.v"]"\
 "[file normalize "$origin_dir/gateware/address_decoder.v"]"\
 "[file normalize "$origin_dir/gateware/multiplexer.v"]"\
 "[file normalize "$origin_dir/gateware/keymatrix.v"]"\
 "[file normalize "$origin_dir/gateware/groms.v"]"\
 "[file normalize "$origin_dir/gateware/cartridge_rom.v"]"\
 "[file normalize "$origin_dir/gateware/console_rom.v"]"\
 "[file normalize "$origin_dir/gateware/scratchpad_ram.v"]"\
 "[file normalize "$origin_dir/gateware/tms9900/tms9900_cpu.v"]"\
 "[file normalize "$origin_dir/gateware/tms9900/tms9901_psi.v"]"\
 "[file normalize "$origin_dir/gateware/tms9918/tms9918_vdp.v"]"\
 "[file normalize "$origin_dir/gateware/tms9918/tms9918_scandoubler.v"]"\
 "[file normalize "$origin_dir/gateware/tms9918/tms9918_color_to_rgb.v"]"\
 "[file normalize "$origin_dir/gateware/tms9918/tms9918_vdpram.v"]"\
 "[file normalize "$origin_dir/gateware/tms9918/tms9918_cpuifc.v"]"\
 "[file normalize "$origin_dir/gateware/tms9918/tms9918_wrapper.v"]"\
 "[file normalize "$origin_dir/gateware/tms9919/tms9919_sgc.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_bstack.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_chirp_rom.hex"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_crom.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_dac.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_fifo.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_kstack.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_multiplier.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_parameter_rom.hex"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_pram.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_prom.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_vsp.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms5200_wrapper.v"]"\
 "[file normalize "$origin_dir/gateware/tms5200/tms6100_vsm.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx-defines.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx-sprs.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_utils.vh"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_branch_predictor_gshare.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_branch_predictor_simple.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_branch_predictor_saturation_counter.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_branch_prediction.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_bus_if_wb32.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_cache_lru.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_cfgrs.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_cpu_cappuccino.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_cpu.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_ctrl_cappuccino.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_dcache.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_decode_execute_cappuccino.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_decode.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_execute_alu.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_execute_ctrl_cappuccino.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_fetch_cappuccino.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_icache.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_lsu_cappuccino.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_pcu.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_pic.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_rf_cappuccino.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_simple_dpram_sclk.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_store_buffer.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_ticktimer.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx.v"]"\
 "[file normalize "$origin_dir/mor1kx/rtl/verilog/mor1kx_wb_mux_cappuccino.v"]"\
 "[file normalize "$origin_dir/vivado/mega99_nexys_a7.xdc"]"\
 "[file normalize "$origin_dir/vivado/mig_a.prj"]"\
  ]
  foreach ifile $files {
    if { ![file isfile $ifile] } {
      puts " Could not find remote file $ifile "
      set status false
    }
  }

  return $status
}
# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "mega99_nexys_a7"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

set _xil_part_ "xc7a50ticsg324-1L"

variable script_file
set script_file "mega99_nexys_a7.tcl"

# Help information for this script
proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--project_name <name>\]"
  puts "$script_file -tclargs \[--part <part>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--origin_dir <path>\]  Determine source file paths wrt this path. Default"
  puts "                       origin_dir path value is \".\", otherwise, the value"
  puts "                       that was set with the \"-paths_relative_to\" switch"
  puts "                       when this script was generated.\n"
  puts "\[--project_name <name>\] Create project with the specified name. Default"
  puts "                       name is the name of the project from where this"
  puts "                       script was generated.\n"
  puts "\[--part <part>\]        Create project with the specified part. Default"
  puts "                       part is the part of the project from where this"
  puts "                       script was generated.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set _xil_proj_name_ [lindex $::argv $i] }
      "--part"         { incr i; set _xil_part_ [lindex $::argv $i] }
      "--help"         { print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/proj"]"

# Check for paths and files needed for project creation
set validate_required 0
if { $validate_required } {
  if { [checkRequiredFiles $origin_dir] } {
    puts "Tcl file $script_file is valid. All files required for project creation is accesable. "
  } else {
    puts "Tcl file $script_file is not valid. Not all files required for project creation is accesable. "
    return
  }
}

# Create project
create_project ${_xil_proj_name_} ./proj -part ${_xil_part_}

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Reconstruct message rules
# None

# Set project properties
set obj [current_project]
# set_property -name "board_part" -value "digilentinc.com:nexys-a7-50t:part0:1.0" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_resource_estimation" -value "0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/cache" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
# set_property -name "platform.board_id" -value "nexys-a7-50t" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "sim_compile_state" -value "1" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/gateware/mega99_top_a7.v"] \
 [file normalize "${origin_dir}/gateware/clkwiz_a7.v"] \
 [file normalize "${origin_dir}/gateware/mig_wrapper_nexys.v"] \
 [file normalize "${origin_dir}/gateware/cdc_flag.v"] \
 [file normalize "${origin_dir}/gateware/ps2com.v"] \
 [file normalize "${origin_dir}/gateware/keyboard_ps2.v"] \
 [file normalize "${origin_dir}/gateware/sigmadelta.v"] \
 [file normalize "${origin_dir}/gateware/sp.v"] \
 [file normalize "${origin_dir}/gateware/spmem.v"] \
 [file normalize "${origin_dir}/gateware/spmmio.v"] \
 [file normalize "${origin_dir}/gateware/spmmio_misc.v"] \
 [file normalize "${origin_dir}/gateware/spmmio_sdcard.v"] \
 [file normalize "${origin_dir}/gateware/spmmio_uart.v"] \
 [file normalize "${origin_dir}/or1k_boot_code0.hex"] \
 [file normalize "${origin_dir}/or1k_boot_code1.hex"] \
 [file normalize "${origin_dir}/or1k_boot_code2.hex"] \
 [file normalize "${origin_dir}/or1k_boot_code3.hex"] \
 [file normalize "${origin_dir}/gateware/mainboard.v"] \
 [file normalize "${origin_dir}/gateware/clkgen.v"] \
 [file normalize "${origin_dir}/gateware/address_decoder.v"] \
 [file normalize "${origin_dir}/gateware/multiplexer.v"] \
 [file normalize "${origin_dir}/gateware/keymatrix.v"] \
 [file normalize "${origin_dir}/gateware/groms.v"] \
 [file normalize "${origin_dir}/gateware/cartridge_rom.v"] \
 [file normalize "${origin_dir}/gateware/console_rom.v"] \
 [file normalize "${origin_dir}/gateware/scratchpad_ram.v"] \
 [file normalize "${origin_dir}/gateware/tms9900/tms9900_cpu.v"] \
 [file normalize "${origin_dir}/gateware/tms9900/tms9901_psi.v"] \
 [file normalize "${origin_dir}/gateware/tms9918/tms9918_vdp.v"] \
 [file normalize "${origin_dir}/gateware/tms9918/tms9918_scandoubler.v"] \
 [file normalize "${origin_dir}/gateware/tms9918/tms9918_color_to_rgb.v"] \
 [file normalize "${origin_dir}/gateware/tms9918/tms9918_vdpram.v"] \
 [file normalize "${origin_dir}/gateware/tms9918/tms9918_cpuifc.v"] \
 [file normalize "${origin_dir}/gateware/tms9918/tms9918_wrapper.v"] \
 [file normalize "${origin_dir}/gateware/tms9919/tms9919_sgc.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_bstack.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_chirp_rom.hex"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_crom.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_dac.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_fifo.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_kstack.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_multiplier.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_parameter_rom.hex"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_pram.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_prom.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_vsp.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms5200_wrapper.v"] \
 [file normalize "${origin_dir}/gateware/tms5200/tms6100_vsm.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx-defines.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx-sprs.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_utils.vh"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_branch_predictor_gshare.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_branch_predictor_simple.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_branch_predictor_saturation_counter.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_branch_prediction.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_bus_if_wb32.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_cache_lru.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_cfgrs.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_cpu_cappuccino.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_cpu.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_ctrl_cappuccino.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_dcache.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_decode_execute_cappuccino.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_decode.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_execute_alu.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_execute_ctrl_cappuccino.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_fetch_cappuccino.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_icache.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_lsu_cappuccino.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_pcu.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_pic.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_rf_cappuccino.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_simple_dpram_sclk.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_store_buffer.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_ticktimer.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx.v"] \
 [file normalize "${origin_dir}/mor1kx/rtl/verilog/mor1kx_wb_mux_cappuccino.v"] \
]
add_files -norecurse -fileset $obj $files


# Set 'sources_1' fileset file properties for remote files
# None

# Set 'sources_1' fileset file properties for local files
set_property file_type {Memory File} [get_files -of $obj *.hex]

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "dataflow_viewer_settings" -value "min_width=16" -objects $obj
set_property -name "top" -value "mega99_top_a7" -objects $obj


# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/vivado/mega99_nexys_a7.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$origin_dir/vivado/mega99_nexys_a7.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property -name "target_constrs_file" -value "[file normalize "$origin_dir/vivado/mega99_nexys_a7.xdc"]" -objects $obj
set_property -name "target_ucf" -value "[file normalize "$origin_dir/vivado/mega99_nexys_a7.xdc"]" -objects $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "mega99_top_a7" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj

set idrFlowPropertiesConstraints ""
catch {
 set idrFlowPropertiesConstraints [get_param runs.disableIDRFlowPropertyConstraints]
 set_param runs.disableIDRFlowPropertyConstraints 1
}

set obj [create_ip -vlnv xilinx.com:ip:mig_7series:4.2 -module_name mig]
set file [file join [get_property ip_dir [get_ips mig]] "mig_a.prj"]
set fp [open "${origin_dir}/vivado/mig_a.prj" r]
set prj [read $fp]
close $fp
set prj [regsub -all {(<TargetFPGA>)[^<]*(?=<)} "$prj" "\\1[regsub csg [regsub -- - "${_xil_part_}" /-] {-&}]"]
set fp [open "$file" w]
puts -nonewline $fp "$prj"
close $fp
set_property -dict [list \
  CONFIG.ARESETN.INSERT_VIP {0} \
  CONFIG.BOARD_MIG_PARAM {Custom} \
  CONFIG.C0_ARESETN.INSERT_VIP {0} \
  CONFIG.C1_ARESETN.INSERT_VIP {0} \
  CONFIG.C2_ARESETN.INSERT_VIP {0} \
  CONFIG.C3_ARESETN.INSERT_VIP {0} \
  CONFIG.C4_ARESETN.INSERT_VIP {0} \
  CONFIG.C5_ARESETN.INSERT_VIP {0} \
  CONFIG.C6_ARESETN.INSERT_VIP {0} \
  CONFIG.C7_ARESETN.INSERT_VIP {0} \
  CONFIG.CLOCK.INSERT_VIP {0} \
  CONFIG.DDR2_RESET.INSERT_VIP {0} \
  CONFIG.DDR3_RESET.INSERT_VIP {0} \
  CONFIG.LPDDR2_RESET.INSERT_VIP {0} \
  CONFIG.MIG_DONT_TOUCH_PARAM {Custom} \
  CONFIG.MMCM_CLKOUT0.INSERT_VIP {0} \
  CONFIG.MMCM_CLKOUT1.INSERT_VIP {0} \
  CONFIG.MMCM_CLKOUT2.INSERT_VIP {0} \
  CONFIG.MMCM_CLKOUT3.INSERT_VIP {0} \
  CONFIG.MMCM_CLKOUT4.INSERT_VIP {0} \
  CONFIG.QDRIIP_RESET.INSERT_VIP {0} \
  CONFIG.RESET.INSERT_VIP {0} \
  CONFIG.RESET_BOARD_INTERFACE {Custom} \
  CONFIG.RLDIII_RESET.INSERT_VIP {0} \
  CONFIG.RLDII_RESET.INSERT_VIP {0} \
  CONFIG.SYSTEM_RESET.INSERT_VIP {0} \
  CONFIG.SYS_CLK_I.INSERT_VIP {0} \
  CONFIG.XML_INPUT_FILE {mig_a.prj} \
] [get_ips mig]
set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $obj


# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part ${_xil_part_} -flow {Vivado Synthesis 2017} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2017" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Synthesis Default Reports} $obj
set_property set_report_strategy_name 0 $obj
set_property -name "auto_incremental_checkpoint" -value "1" -objects $obj
set_property -name "strategy" -value "Vivado Synthesis Defaults" -objects $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part ${_xil_part_} -flow {Vivado Implementation 2017} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2017" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Implementation Default Reports} $obj
set_property set_report_strategy_name 0 $obj

# set the current impl run
current_run -implementation [get_runs impl_1]
catch {
 if { $idrFlowPropertiesConstraints != {} } {
   set_param runs.disableIDRFlowPropertyConstraints $idrFlowPropertiesConstraints
 }
}

puts "INFO: Project created:${_xil_proj_name_}"
