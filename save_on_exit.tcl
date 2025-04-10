# Hook into the "exit" and "close_project" procedure to
# ensure that tcl build script is generated each time Vivado GUI is closed

# Check changes with git, and pick what to commit/discard
# This should help keep local projects up to date with the repo

proc save_build_file args {
    write_project_tcl -internal -force {./build_project.tcl}
}

if {[llength [namespace which {exit_}]]==0} {
    rename ::exit exit_
    proc ::exit args {
    puts "Writing TCL before closing..."
    save_build_file
    uplevel 1 ::exit_ $args
    }
}

if {[llength [namespace which {close_project_}]]==0} {
    rename ::close_project close_project_
    proc ::close_project args {
    puts "Writing TCL before closing..."
    save_build_file
    uplevel 1 ::close_project_ $args
    }
}
