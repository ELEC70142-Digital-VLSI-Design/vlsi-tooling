####################################################################
##
##  Sanity check on the NDM built by build_ndm.tcl.
##
##  Author:   Sne Samal
##  Date:     2026-08-23
##  Version:  1.1
##
##  Run once the kit is loaded:
##
##      fc_shell -f $SYN_TOOLS_DIR/check_ndm.tcl
##
##  Checks contents, not exit status: a build that printed no obvious
##  error can still produce an empty library.
##
####################################################################

source $env(SYN_KIT_TCL)

####################################################################
## Open the libraries
####################################################################
# All five are required, pads included. A missing one means
# build_ndm.tcl never ran, or stopped part way through.

foreach lib [concat $REF_LIBS $PAD_REF_LIBS] {
    if { ![file exists $lib] } {
        puts "FAIL: $lib does not exist. Run build_ndm.tcl first."
        exit 1
    }
    open_lib $lib
    report_lib [current_lib]
}

####################################################################
## Cell check
####################################################################
# open_lib accumulates, so */ searches every library opened above.

proc check_cells {label wanted} {
    set missing {}
    foreach c $wanted {
        if { [sizeof_collection [get_lib_cells -quiet */$c]] == 0 } {
            lappend missing $c
        }
    }
    set n [llength $wanted]
    if { [llength $missing] } {
        puts [format " %-20s: %d of %d" $label [expr {$n - [llength $missing]}] $n]
    } else {
        puts [format " %-20s: all %d present" $label $n]
    }
    return $missing
}

set all    [sizeof_collection [get_lib_cells -quiet */*]]
set frames [sizeof_collection [get_lib_cells -quiet */*/frame]]

puts "----------------------------------------"
puts [format " %-20s: %d" "library cells" $all]
puts [format " %-20s: %d" "with a frame view" $frames]

# Both lists are cells the scripts ask for by name. A missing one
# otherwise surfaces much later as a placement, CTS or padring error.

set missing [check_cells "special cells" \
    [concat [list $TAP_CELL $TIE_HI_CELL $TIE_LO_CELL] \
            $FILLER_CELLS $CTS_BUFFERS $CTS_INVERTERS]]

set missing [concat $missing [check_cells "pad cells" \
    [concat $IO_CELLS [list $IO_CORNER_CELL $BPAD_CELL] \
            $IO_FILLER_CELLS]]]

if { [llength $missing] } {
    puts ""
    puts "FAIL: these cells are not in the library:"
    foreach c $missing { puts "  $c" }
    puts "----------------------------------------"
    exit 1
}

puts ""
puts "PASS"
puts "----------------------------------------"
exit 0
