#------------------------------------------------------------------------------
# (c) Jason Wilden 2025
#------------------------------------------------------------------------------

# Design
set DESIGN trivius
set TOP_MODULE ${DESIGN}_top

# Board
set DEVICE GW1NR-LV9QN88PC6/I5
set FAMILY GW1N-9C
set PACKAGE QN88P
set DEVICE_VER C
set BOARD tangnano9k

# Directories
set BASE_DIR [file dirname [file normalize [file dirname [info script]]]]
set RTL_DIR $BASE_DIR/rtl
set PROJ_DIR $BASE_DIR/project
set IMPL_DIR $PROJ_DIR/$DESIGN/impl

# Bitstream output file
set BITSTREAM $IMPL_DIR/pnr/$DESIGN.fs

# This parses the HTML report files that Gowin EDA generates, it extracts some
# basic values that are useful to see during each build.  
proc parse_reports {} {
    global IMPL_DIR DESIGN BASE_DIR
    
    set main_report_file "${IMPL_DIR}/pnr/${DESIGN}.rpt.html"
    set timing_file "${IMPL_DIR}/pnr/${DESIGN}_tr_content.html"
    
    # Call Python script to extract data - easier than doing with TCL (at least for me)
    catch {exec python3 "${BASE_DIR}/scripts/parse_reports.py" "$main_report_file" "$timing_file"} report_output
    puts $report_output
    puts "==================================\n"
}


# Diagnostics
puts "=================================================================="
puts "## Building $DESIGN ($TOP_MODULE)"
puts "## DEVICE: $DEVICE"
puts "## FAMILY: $FAMILY"
puts "## Base directory:  $BASE_DIR"
puts "## RTL directory: $RTL_DIR"
puts "## Project directory: $PROJ_DIR"
puts "## Bitstream: $BITSTREAM"
puts "=================================================================="

# Clear any existing project
if {[file exists $PROJ_DIR]} {
    file delete -force $PROJ_DIR    
    file mkdir $PROJ_DIR
    puts "## Cleared existing project directory prior to new build"
}

# Create project 
create_project -name $DESIGN -dir $PROJ_DIR -pn $DEVICE -device_version $DEVICE_VER

# Global configuration
set_option -output_base_name $DESIGN
set_option -use_sspi_as_gpio 1

# Synthesis configuration
set_option -top_module $TOP_MODULE
set_option -verilog_std sysv2017 
set_option -synthesis_tool gowinsynthesis
set_option -include_path $RTL_DIR

# All warnings on
set_option -print_all_synthesis_warning 1

# PNR: No need to register io blocks, no high-speed signals and all module
# outputs are registered in fabric.
set_option -oreg_in_iob 0                

# Constraints
add_file "$RTL_DIR/${DESIGN}.cst"
add_file "$RTL_DIR/${DESIGN}.sdc"
   
# RTL 
add_file "$RTL_DIR/${DESIGN}_top.sv"
add_file "$RTL_DIR/clock_gen.sv"
add_file "$RTL_DIR/i2s_tx.sv"
add_file "$RTL_DIR/uart_tick_gen.sv"
add_file "$RTL_DIR/uart_rx.sv"
add_file "$RTL_DIR/test_tone.sv"

#Build
puts "## Building"
run all
parse_reports

#Program
puts "## Writing bitstream to device"
exec openFPGALoader -b $BOARD $BITSTREAM

# All done.
puts "## Completed."

