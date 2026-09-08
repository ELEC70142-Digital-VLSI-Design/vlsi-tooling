#############################################################
#
#  Synopsys tool environment: PATH, licences, tool versions.
#  Sourced by setup.cshrc. Do not source on its own.
#
#  Author:   Sne Samal
#  Date:     2026-08-23
#  Version:  1.0
#
#  Versions are discovered from the install tree, so a tool upgrade
#  needs no edit here.
#    add a tool     add a row to the table below
#    pin a version  setenv <VAR>_VERSION <dirname> before loading,
#                   e.g. setenv SNPS_FC_VERSION FS-COMPILER_2025.06-SP2a
#
#############################################################

# SITE: install root on ee-mill2. Change for another machine.
setenv SYN_DIR /eda/synopsys/2025-26/RHELx86
setenv CDSHOME /eda/cadence/2025-26/RHELx86/IC_25.10.030
setenv CDS_INST_DIR /eda/cadence/2025-26/RHELx86/IC_25.10.030

# Warn rather than exit: this file is sourced, so "exit" would kill the
# user's shell.
if ( ! -d "$SYN_DIR" ) then
    echo "ERROR: $SYN_DIR does not exist. The Synopsys install has moved."
endif

# --- Licences -------------------------------------------------------
# SITE: Imperial EEE licence servers.
setenv SNPSLMD_LICENSE_FILE 27020@ee-llic01.ee.ic.ac.uk:27020@ee-cas-licenses.ee.ic.ac.uk:7182@ee-fs1.ee.ic.ac.uk

# Verdi/Novas falls back to the generic FlexLM variable. Append so
# another vendor's servers are not clobbered.
if ( $?LM_LICENSE_FILE ) then
    setenv LM_LICENSE_FILE "${LM_LICENSE_FILE}:${SNPSLMD_LICENSE_FILE}"
else
    setenv LM_LICENSE_FILE "$SNPSLMD_LICENSE_FILE"
endif

# --- Tool table -----------------------------------------------------
# "<install directory prefix>:<variable to set>"
#
# The trailing underscore in the glob matters: TESTMAX_* must not match
# TESTMAX-ALE_*, ICV_* must not match ICVWB_*, PRIMEPOWER_* must not
# match PRIMEPOWER-RTL_*.
#
# Never put "*" in this list. csh globs the word list of a foreach, and
# a pattern matching no file aborts the script with "foreach: No match."

set snps_tools = ( \
    "FS-COMPILER:SNPS_FC"      \
    "SYN:SNPS_SYN"             \
    "ICC2:SNPS_ICC2"           \
    "VCS:SNPS_VCS"             \
    "VERDI:SNPS_VERDI"         \
    "ICV:SNPS_ICV"             \
    "STARRC:SNPS_STARRC"       \
    "LC:SNPS_LC"               \
    "PT:SNPS_PT"               \
    "FM:SNPS_FM"               \
    "TESTMAX:SNPS_TESTMAX"     \
    "CUSTOM-COMP:SNPS_CUSTOM"  \
)

# Belt and braces against the same trap if someone adds a "*" later.
set noglob

foreach row ( $snps_tools )
    set tpfx  = `echo "$row" | cut -d: -f1`
    set tvar  = `echo "$row" | cut -d: -f2`

    # An explicit pin wins over discovery.
    set tdir = `printenv ${tvar}_VERSION`

    # Otherwise take the newest matching directory. -V sorts SP10 above
    # SP2, which plain -r gets wrong.
    if ( "$tdir" == "" || ! -d "$SYN_DIR/$tdir" ) then
        set tdir = `find $SYN_DIR -maxdepth 1 -type d -name "${tpfx}_*" -printf "%f\n" | sort -Vr | head -1`
    endif

    # Export <VAR> as the tool home and append its bin to PATH.
    if ( "$tdir" == "" ) then
        echo "  WARNING: no directory matching ${tpfx}_* under $SYN_DIR"
    else
        eval "setenv $tvar $SYN_DIR/$tdir"
        if ( -d "$SYN_DIR/$tdir/bin" ) then
            setenv PATH "${PATH}:$SYN_DIR/$tdir/bin"
        else
            echo "  WARNING: $SYN_DIR/$tdir/bin not found, skipping"
        endif
    endif
end

unset noglob
unset snps_tools row tpfx tvar tdir

# --- Tools needing a home variable, not just a PATH entry -----------
# VCS and Verdi read these at startup and will not run without them.

if ( $?SNPS_VCS )   setenv VCS_HOME   "$SNPS_VCS"
if ( $?SNPS_VERDI ) setenv VERDI_HOME "$SNPS_VERDI"
if ( $?SNPS_VERDI ) setenv NOVAS_HOME "$SNPS_VERDI"

# stil2verilog is not on the tool table's PATH and is linked against a
# newer libstdc++ than this machine ships, so it runs through the
# wrapper of the same name. Not put on PATH itself: $SYN_TOOLS_DIR is
# appended last, so the real binary would shadow the wrapper.
if ( $?SNPS_TESTMAX ) then
    setenv SNPS_STIL2VERILOG "$SNPS_TESTMAX/linux64/syn/bin/stil2verilog"
endif

# TODO check whether the borrowed libstdc++ below is needed at all, and
# why TestMAX's own copy under embedit/linux64/lib_cc was unusable.

# stil2verilog needs GLIBCXX_3.4.29; the system libstdc++ is 3.4.25.
# SITE: borrowed from Custom Compiler's Tcl script debugger.
if ( $?SNPS_CUSTOM ) then
    setenv SNPS_LIBSTDCXX_DIR "$SNPS_CUSTOM/apps/tclscriptdebugger/TCLIDE/lib/linux64"
endif

# TestMAX ATPG builds the path to its message files as
# $SYNOPSYS/auxx/syn/dc.err and will not start without this. It wants
# the synthesis install, not the TestMAX one.
if ( $?SNPS_SYN ) setenv SYNOPSYS "$SNPS_SYN"

# --- Calibre (Siemens, not Synopsys) --------------------------------
# Signoff DRC and LVS. Here rather than in a kit file because the
# install root and licence are the same whichever PDK is loaded; the
# rule decks are kit-specific and live in kits/<kit>.cshrc.
#
# Custom Compiler's "Tools > Calibre" menu needs MGC_HOME set before
# launch, or every action in it fails.
#
# SITE: install root.
setenv MGC_HOME /eda/Siemens/2025-26/RHELx86/CALIBRE_2025.4/aok_cal_2025.4_18.11
setenv CALIBRE_HOME "$MGC_HOME"

if ( -d "$MGC_HOME/bin" ) then
    setenv PATH "${PATH}:$MGC_HOME/bin"
    setenv MGC_DOC_PATH "$MGC_HOME/docs"
    # The 32-bit binary is the default and is unusable on this server.
    setenv USE_CALIBRE_64 YES
    # Keeps the Calibre menu in the host tool between invocations.
    setenv MGC_CALIBRE_PRESERVE_MENU_TRIGGER YES
else
    echo "  WARNING: MGC_HOME=$MGC_HOME not found; DRC and LVS will not run"
endif

# Siemens uses its own FlexLM variable, so this never collides with
# SNPSLMD_LICENSE_FILE. Append in case another Siemens tool is loaded.
if ( $?MGLS_LICENSE_FILE ) then
    setenv MGLS_LICENSE_FILE "${MGLS_LICENSE_FILE}:1717@ee-fs1.ee.ic.ac.uk:1717@ib-artemis.ib.ic.ac.uk"
else
    setenv MGLS_LICENSE_FILE 1717@ee-fs1.ee.ic.ac.uk:1717@ib-artemis.ib.ic.ac.uk
endif

# --- Wrapper scripts ------------------------------------------------
# Puts "custom", "memcomp", "stil2verilog" and "syn" itself on PATH, so
# they can be run from any working directory.

if ( $?SYN_TOOLS_DIR ) setenv PATH "${PATH}:$SYN_TOOLS_DIR"

# Rebuild the command hash table so the new PATH takes effect now.
rehash
