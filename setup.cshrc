#############################################################
#
#  Entry point for the Synopsys tool environment.
#  Loads the tools, then one PDK kit, then reports both.
#
#  Author:   Sne Samal
#  Date:     2026-08-23
#  Version:  1.0
#
#  Normally reached through the wrapper:  vlsi-tooling/syn tsmc65LP
#  By hand:
#    setenv SYN_TOOLS_DIR <path to this directory>
#    setenv SYN_KIT tsmc65LP
#    source $SYN_TOOLS_DIR/setup.cshrc
#
#############################################################

if ( $?SYN_ENV_LOADED ) then

    echo "Synopsys environment already loaded (kit: $SYN_KIT)."
    echo "Type 'exit' to unload it, then load another."

else if ( ! $?SYN_TOOLS_DIR ) then

    echo "ERROR: SYN_TOOLS_DIR is not set."
    echo "       setenv SYN_TOOLS_DIR <path to labs_synopsys/tools>"

else

    if ( ! $?SYN_KIT ) setenv SYN_KIT tsmc65LP

    if ( ! -f "$SYN_TOOLS_DIR/kits/$SYN_KIT.cshrc" ) then

        echo "ERROR: no kit file $SYN_TOOLS_DIR/kits/$SYN_KIT.cshrc"

    else

        source "$SYN_TOOLS_DIR/synopsys_tools.cshrc"
        source "$SYN_TOOLS_DIR/kits/$SYN_KIT.cshrc"

        setenv SYN_ENV_LOADED 1

        echo "--- tools ---"
        # calibre is Siemens, not Synopsys, still used for DRC and LVS.
        foreach t ( fc_shell dc_shell icc2_shell custom_compiler vcs vlogan verdi icv lc_shell lm_shell pt_shell fm_shell StarXtract calibre )
            set p = `which $t |& head -1`
            if ( -x "$p" ) then
                printf '  %-15s %s\n' "$t" "$p"
            else
                printf '  %-15s NOT ON PATH\n' "$t"
            endif
        end
        unset t p

        echo "--- kit: $SYN_KIT ---"
        echo "  tech file   $SYN_TECH_FILE"
        echo "  ref libs    $SYN_REF_LIBS"
        echo "  pad libs    $SYN_PAD_REF_LIBS"

        # The reference libraries are built once, not shipped. All five
        # are checked: a lab loads only the first two, but a half-built
        # set is a broken install either way.
        #
        # TODO once ndm_search names the shared copy, reword this: the
        # build is not something every user should run.
        foreach l ( $SYN_REF_LIBS $SYN_PAD_REF_LIBS )
            if ( ! -e "$l" ) then
                echo "  NOT BUILT   run: lm_shell -f \$SYN_TOOLS_DIR/build_ndm.tcl"
                break
            endif
        end
        unset l

        echo "  tcl setup   $SYN_KIT_TCL"
        echo "  lib.defs    $SYN_LIBDEFS"
        if ( $?SYN_MEMCOMP_DIR ) echo "  memcomp     $SYN_MEMCOMP_DIR"
        echo "--- licences ---"
        echo "  $SNPSLMD_LICENSE_FILE"

    endif

endif
