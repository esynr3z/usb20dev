# check project existance
if {[catch { open_project usb20dev }]} {
  create_project usb20dev
} else {
  remove_files *
}

# get sources from external file and selected test tb.sv frome args
read_verilog -library work -sv [split [read [open "../src.files" "r"]]] [lindex $argv 0]
set_property include_dirs "../testbenches" [current_fileset]
update_compile_order -fileset sim_1

# prepare for simulation
launch_simulation
restart

# run
if {[lindex $argv 1] == "batch_mode"} {
  run -all
  if {[lindex $argv 2] == "exit_on_stop"} {
    exit
  }
} else {
  start_gui
}
