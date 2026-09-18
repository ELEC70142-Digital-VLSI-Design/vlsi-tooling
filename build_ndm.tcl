####################################################################
##
##  One-time NDM reference library build for tsmc65LP.
##
##  Author:   Sne Samal
##  Date:     2026-08-23
##  Version:  1.1
##
##  Run with Library Manager, NOT fc_shell, once the kit is loaded:
##
##      lm_shell -f $SYN_TOOLS_DIR/build_ndm.tcl
##
##  Built from LEF plus db because the kit ships Milkyway, not NDM.
##  Writes five libraries: two for the standard cells, about 36 MB,
##  and three for the IO and bond pads. Point create_lib at them.
##
##  On failure, rerun lm_shell interactively and use
##  "check_workspace -details all".
##
####################################################################

source $env(SYN_KIT_TCL)

set LIB_NAME $env(TSMC65_STDCELL)
set NDM_DIR  $env(SYN_NDM_DIR)

file mkdir $NDM_DIR

####################################################################
## Application options
####################################################################
# TSMC Liberty does not declare related_power_pin on every cell.
set_app_options -as_user_default \
    -name lib.workspace.allow_missing_related_pg_pins -value true

# Keep the LEF metal blockages instead of merging them.
set_app_options -as_user_default \
    -name lib.physical_model.preserve_metal_blockage -value auto

# Match the bus naming used by the Verilog and SDC.
set_app_options -as_user_default -name design.bus_delimiters -value {[]}

####################################################################
## Build helper
####################################################################
# One workspace, written out and discarded. An empty process label
# reads the db without one, which a physical-only pass needs.

proc build_pass {workspace output flow lef dbs} {
    global TECH_FILE SCALE_FACTOR NDM_DIR

    create_workspace $workspace \
        -technology   $TECH_FILE \
        -flow         $flow \
        -scale_factor $SCALE_FACTOR

    read_lef $lef

    foreach {db label} $dbs {
        if { ![file exists $db] } {
            puts "ERROR: missing $db"
            continue
        }
        if { $label eq "" } {
            read_db $db
        } else {
            read_db $db -process_label $label
        }
    }

    process_workspaces -force -directory $NDM_DIR -output $output
    remove_workspace
}

####################################################################
## Standard cells
####################################################################
# Two libraries, because -flow normal emits only cells found in both
# the LEF and the db, which drops the untimed tap and FILL cells.
# -flow physical_only recovers those. It reads one db as well, or the
# timed cells would appear in both libraries; any corner will do, all
# three hold the same cell set.

set STD_DB_SUFFIX "_ccs"

set std_dbs {}
foreach corner $CORNER_LABELS {
    lappend std_dbs $STD_DB_DIR/${LIB_NAME}${corner}${STD_DB_SUFFIX}.db $corner
}

build_pass $LIB_NAME ${LIB_NAME}_frame_timing.ndm normal \
    $STD_LEF $std_dbs

build_pass ${LIB_NAME}_po ${LIB_NAME}_physical_only.ndm physical_only \
    $STD_LEF [list \
        $STD_DB_DIR/${LIB_NAME}[lindex $CORNER_LABELS 0]${STD_DB_SUFFIX}.db ""]

####################################################################
## IO cells and bond pads
####################################################################
# The IO library splits the same way the standard cells do, PCORNER and
# the PFILLER family having no timing. The bond pads ship no db at all,
# so one physical-only pass from the LEF.

set io_dbs {}
foreach corner $CORNER_LABELS {
    lappend io_dbs [io_db $corner] $corner
}

build_pass $IO_LIB_NAME ${IO_LIB_NAME}_frame_timing.ndm normal \
    $IO_LEF $io_dbs

build_pass ${IO_LIB_NAME}_po ${IO_LIB_NAME}_physical_only.ndm physical_only \
    $IO_LEF [list [io_db [lindex $CORNER_LABELS 0]] ""]

build_pass $BPAD_LIB_NAME ${BPAD_LIB_NAME}_physical_only.ndm physical_only \
    $BPAD_LEF {}

####################################################################
## Result
####################################################################
# process_workspaces can return without writing anything, so check the
# files are on disk before reporting success.

set missing {}
foreach lib [concat $REF_LIBS $PAD_REF_LIBS] {
    if { ![file exists $lib] } { lappend missing $lib }
}

puts "=========================================="
puts " NDM directory : $NDM_DIR"
puts "   ${LIB_NAME}_frame_timing.ndm   corners: $CORNER_LABELS"
puts "   ${LIB_NAME}_physical_only.ndm  taps and fillers"
puts "   ${IO_LIB_NAME}_frame_timing.ndm   corners: $CORNER_LABELS"
puts "   ${IO_LIB_NAME}_physical_only.ndm  corner and IO fillers"
puts "   ${BPAD_LIB_NAME}_physical_only.ndm  bond pads"
puts "------------------------------------------"

if { [llength $missing] } {
    puts " BUILD FAILED. Not written:"
    foreach lib $missing { puts "   $lib" }
    puts ""
    puts " Search this log upwards for the first \"Error\" line."
    puts "=========================================="
    exit 1
}

puts " BUILD OK. Now check the contents:"
puts "   fc_shell -f \$SYN_TOOLS_DIR/check_ndm.tcl"
puts "=========================================="
exit 0
