# Check file required for this script exists
proc checkRequiredFiles { origin_dir} {
  set status true
  set files [list \
 "[file normalize "$origin_dir/gateware/mega99_mega65r3_top.v"]"\
 "[file normalize "$origin_dir/gateware/mega65_clkwiz.v"]"\
 "[file normalize "$origin_dir/gateware/hyperram_wrapper.v"]"\
 "[file normalize "$origin_dir/gateware/hyperram.v"]"\
 "[file normalize "$origin_dir/gateware/artix7_hyperphy.v"]"\
 "[file normalize "$origin_dir/gateware/keyboard_mk1.v"]"\
 "[file normalize "$origin_dir/gateware/kbdmk1com.v"]"\
 "[file normalize "$origin_dir/gateware/max10_reset_button.v"]"\
 "[file normalize "$origin_dir/gateware/ak4432_audio.v"]"\
 "[file normalize "$origin_dir/gateware/sigmadelta.v"]"\
 "[file normalize "$origin_dir/gateware/tmds_10to1ddr.v"]" \
 "[file normalize "$origin_dir/gateware/hdmi/vga_to_hdmi.vhdl"]" \
 "[file normalize "$origin_dir/gateware/hdmi/hdmi_tx_encoder.vhdl"]" \
 "[file normalize "$origin_dir/gateware/hdmi/types_pkg.vhdl"]" \
 "[file normalize "$origin_dir/gateware/sp.v"]"\
 "[file normalize "$origin_dir/gateware/spmem.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio_misc.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio_sdcard.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio_uart.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio_overlay.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio_keyboard.v"]"\
 "[file normalize "$origin_dir/gateware/spmmio_tape.v"]"\
 "[file normalize "$origin_dir/gateware/icap_wrapper.v"]"\
 "[file normalize "$origin_dir/gateware/qspi_controller.v"]"\
 "[file normalize "$origin_dir/or1k_boot_code.hex"]"\
 "[file normalize "$origin_dir/gateware/mainboard.v"]"\
 "[file normalize "$origin_dir/gateware/clkgen.v"]"\
 "[file normalize "$origin_dir/gateware/address_decoder.v"]"\
 "[file normalize "$origin_dir/gateware/multiplexer.v"]"\
 "[file normalize "$origin_dir/gateware/keymatrix.v"]"\
 "[file normalize "$origin_dir/gateware/groms.v"]"\
 "[file normalize "$origin_dir/gateware/cartridge_rom.v"]"\
 "[file normalize "$origin_dir/gateware/console_rom.v"]"\
 "[file normalize "$origin_dir/gateware/scratchpad_ram.v"]"\
 "[file normalize "$origin_dir/gateware/peb.v"]"\
 "[file normalize "$origin_dir/gateware/peb_ram32k.v"]"\
 "[file normalize "$origin_dir/gateware/peb_fdc.v"]"\
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
 "[file normalize "$origin_dir/gateware/fdc1771/fdc1771.v"]"\
 "[file normalize "$origin_dir/gateware/fdc1771/fdc1771_mockdrive.v"]"\
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
 "[file normalize "$origin_dir/vivado/mega99_mega65r3.xdc"]"\
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
set _xil_proj_name_ "mega99_mega65r3"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

set _xil_part_ "xc7a200tfbg484-2"

variable script_file
set script_file "mega99_mega65r3.tcl"

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

# Check Vivado version
package require Vivado 1.2024.2

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
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_resource_estimation" -value "0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/cache" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
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
 [file normalize "${origin_dir}/gateware/mega99_mega65r3_top.v"] \
 [file normalize "${origin_dir}/gateware/mega65_clkwiz.v"] \
 [file normalize "${origin_dir}/gateware/hyperram_wrapper.v"] \
 [file normalize "${origin_dir}/gateware/hyperram.v"] \
 [file normalize "${origin_dir}/gateware/artix7_hyperphy.v"] \
 [file normalize "${origin_dir}/gateware/keyboard_mk1.v"] \
 [file normalize "${origin_dir}/gateware/kbdmk1com.v"] \
 [file normalize "${origin_dir}/gateware/max10_reset_button.v"] \
 [file normalize "${origin_dir}/gateware/ak4432_audio.v"] \
 [file normalize "${origin_dir}/gateware/sigmadelta.v"] \
 [file normalize "${origin_dir}/gateware/tmds_10to1ddr.v"] \
 [file normalize "${origin_dir}/gateware/hdmi/vga_to_hdmi.vhdl"] \
 [file normalize "${origin_dir}/gateware/hdmi/hdmi_tx_encoder.vhdl"] \
 [file normalize "${origin_dir}/gateware/hdmi/types_pkg.vhdl"] \
 [file normalize "${origin_dir}/gateware/sp.v"] \
 [file normalize "${origin_dir}/gateware/spmem.v"] \
 [file normalize "${origin_dir}/gateware/spmmio.v"] \
 [file normalize "${origin_dir}/gateware/spmmio_misc.v"] \
 [file normalize "${origin_dir}/gateware/spmmio_sdcard.v"] \
 [file normalize "${origin_dir}/gateware/spmmio_uart.v"] \
 [file normalize "${origin_dir}/gateware/spmmio_overlay.v"] \
 [file normalize "${origin_dir}/gateware/spmmio_keyboard.v"] \
 [file normalize "${origin_dir}/gateware/spmmio_tape.v"] \
 [file normalize "${origin_dir}/gateware/icap_wrapper.v"] \
 [file normalize "${origin_dir}/gateware/qspi_controller.v"] \
 [file normalize "${origin_dir}/or1k_boot_code.hex"] \
 [file normalize "${origin_dir}/gateware/mainboard.v"] \
 [file normalize "${origin_dir}/gateware/clkgen.v"] \
 [file normalize "${origin_dir}/gateware/address_decoder.v"] \
 [file normalize "${origin_dir}/gateware/multiplexer.v"] \
 [file normalize "${origin_dir}/gateware/keymatrix.v"] \
 [file normalize "${origin_dir}/gateware/groms.v"] \
 [file normalize "${origin_dir}/gateware/cartridge_rom.v"] \
 [file normalize "${origin_dir}/gateware/console_rom.v"] \
 [file normalize "${origin_dir}/gateware/scratchpad_ram.v"] \
 [file normalize "${origin_dir}/gateware/peb.v"] \
 [file normalize "${origin_dir}/gateware/peb_ram32k.v"] \
 [file normalize "${origin_dir}/gateware/peb_fdc.v"] \
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
 [file normalize "${origin_dir}/gateware/fdc1771/fdc1771.v"] \
 [file normalize "${origin_dir}/gateware/fdc1771/fdc1771_mockdrive.v"] \
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
set_property -name "top" -value "mega99_mega65r3_top" -objects $obj


# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/vivado/mega99_mega65r3.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$origin_dir/vivado/mega99_mega65r3.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property -name "target_constrs_file" -value "[file normalize "$origin_dir/vivado/mega99_mega65r3.xdc"]" -objects $obj
set_property -name "target_ucf" -value "[file normalize "$origin_dir/vivado/mega99_mega65r3.xdc"]" -objects $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "mega99_mega65r3_top" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj

set idrFlowPropertiesConstraints ""
catch {
 set idrFlowPropertiesConstraints [get_param runs.disableIDRFlowPropertyConstraints]
 set_param runs.disableIDRFlowPropertyConstraints 1
}

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part ${_xil_part_} -flow {Vivado Synthesis 2022} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2022" [get_runs synth_1]
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
    create_run -name impl_1 -part ${_xil_part_} -flow {Vivado Implementation 2022} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2022" [get_runs impl_1]
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


# Suppress inconsequential warnings
set_msg_config -suppress -id {Synth 8-3917} -string {VDAC_SYNC_N}
set_msg_config -suppress -id {Synth 8-3917} -string {VDAC_BLANK_N}
set_msg_config -suppress -id {Synth 8-3917} -string {AUDIO_MCLK}
set_msg_config -suppress -id {Synth 8-3917} -string {AUDIO_BCLK}
set_msg_config -suppress -id {Synth 8-3917} -string {AUDIO_SDATA}
set_msg_config -suppress -id {Synth 8-3917} -string {AUDIO_LRCLK}
set_msg_config -suppress -id {Synth 8-3917} -string {AUDIO_PDN}
set_msg_config -suppress -id {Synth 8-3917} -string {CEC_A}
set_msg_config -suppress -id {Synth 8-3917} -string {CT_HPD}
set_msg_config -suppress -id {Synth 8-3917} -string {LS_OE}
set_msg_config -suppress -id {Synth 8-3917} -string {FPGA_TX}
set_msg_config -suppress -id {Synth 8-3917} -string {FPGA_RX}
set_msg_config -id {Synth 8-7129} -string {{.*Port wb_adr_i\[.\] in module cartridge_rom.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{Port grclk_en in module groms}} -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port grom_set\[.\] in module groms.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port a\[.\] in module scratchpad_ram.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port a\[.\] in module console_rom.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port wb_adr_i\[.\] in module console_rom.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port a\[.*\] in module address_decoder.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port sp_i_adr\[3.\] in module spmem.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port sp_i_sel\[.\] in module spmem.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port sel\[.\] in module spmmio_keyboard.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port d\[.*\] in module spmmio_keyboard.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port sel\[.\] in module spmmio_uart.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port d\[.*\] in module spmmio_uart.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port d\[.*\] in module spmmio_sdcard.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port sel\[.\] in module spmmio_misc.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port d\[.*\] in module spmmio_misc.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port adr\[.\] in module spmmio_tape.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{Port adr_i[22] in module spmmio}} -suppress
set_msg_config -id {Synth 8-7129} -string {{Port adr_i[23] in module spmmio}} -suppress
set_msg_config -id {Synth 8-7129} -string {{Port dbin in module peb}} -suppress
set_msg_config -id {Synth 8-7129} -string {{Port clk_3mhz_en in module peb}} -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port wb_adr_i\[.\] in module peb.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{Port reset in module peb_ram32k}} -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port dat_i\[.*\] in module qspi_controller.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{.*Port sel_i\[.\] in module qspi_controller.*}} -regexp -suppress
set_msg_config -id {Synth 8-7129} -string {{Port adr_i[26] in module qspi_controller}} -suppress
set_msg_config -id {Synth 8-7129} -string {{Port adr_i[27] in module qspi_controller}} -suppress
set_msg_config -id {Synth 8-4446} -new_severity "INFO"


# Suppress hdmi warnings
set_msg_config -id {Synth 8-6014} -string {vga_to_hdmi.vhdl} -suppress
set_msg_config -id {Synth 8-6014} -string {xpm_cdc.sv} -suppress
set_msg_config -id {Synth 8-7129} -string {{in module xpm_}} -suppress
set_msg_config -id {Route 35-462} -string {hdmi_encoder} -suppress

# Suppress mor1kx warnings
set_msg_config -id {Synth 8-693} -string {mor1kx/rtl} -suppress
set_msg_config -id {Synth 8-3332} -string {mor1kx} -suppress
set_msg_config -id {Synth 8-3848} -string {mor1kx/rtl} -suppress
set_msg_config -id {Synth 8-6014} -string {mor1kx/rtl} -suppress
set_msg_config -id {DRC DPOP-1} -string {mor1kx_cpu} -suppress
set_msg_config -id {DRC DPOP-2} -string {mor1kx_cpu} -suppress

set_msg_config -id {Synth 8-5974} -new_severity "INFO"
set_msg_config -id {Synth 8-7080} -new_severity "INFO"


puts "INFO: Project created:${_xil_proj_name_}"
