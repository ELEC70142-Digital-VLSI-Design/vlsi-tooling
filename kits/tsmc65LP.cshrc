# DESCRIPTION: TSMC 65nm Low Power, 9 metal, 7-track standard cells
#############################################################
#
#  Kit paths for tsmc65LP. Sourced by setup.cshrc.
#
#  Author:   Sne Samal
#  Date:     2026-08-23
#  Version:  1.0
#
#  Paths only. The Tcl half, kits/tsmc65LP.tcl, reads these back out
#  of the environment so there is one source of truth.
#
#  Everything is pinned to ONE metal stack: technology file, cell LEF
#  and TLUPlus must describe the same stack or the library build fails
#  with "cannot find via" errors.
#
#############################################################

# SITE: TSMC libraries on ee-mill2. Change for another machine.
# Two deliveries. TSMCHOME/digital is the back-end kit: LEF, Milkyway,
# Liberty, Verilog. 65n_LP is the front-end PDK: OpenAccess technology
# library, Calibre decks, display file.
setenv TSMC65_TSMCHOME /eda/cadence_tools/kits/tsmc/beLibs/65nm/TSMCHOME
setenv TSMC65_HOME     $TSMC65_TSMCHOME/digital
setenv TSMC65_PDK      /eda/cadence_tools/kits/tsmc/65n_LP

# beLibs/65nm ships frame-only layout views, so the OpenAccess cell
# library and cell GDS come from 65nm_tmp instead. Kept separate because
# the NDM build is pinned to 65nm.
# TODO: 65nm_tmp used here, change when a non-tmp solution is found.
setenv TSMC65_OA_TSMCHOME /eda/cadence_tools/kits/tsmc/beLibs/65nm_tmp/TSMCHOME

# tsmcBE.lib, which lib.defs INCLUDEs, expands this to reach the
# standard cell libraries.
setenv TSMC_PDK_PATH   $TSMC65_PDK

# 9 metal layers, top 2 thick.
setenv TSMC65_STACK   9lmT2

# 7-track standard Vt cells. The kit's other standard cell libraries
# are hvt and lvt variants, which nothing here uses.
setenv TSMC65_STDCELL tcbn65lpbwp7t
setenv TSMC65_MW      $TSMC65_HOME/Back_End/milkyway/tcbn65lpbwp7t_141a

# IO cells and the bond pads that sit above them. Loaded only by a
# design with a padring, but built and checked with the rest.
setenv TSMC65_IO   tphn65lpnv2od3_sl
setenv TSMC65_BPAD tpbn65v

# --- Inputs to the one-time NDM build -------------------------------

setenv SYN_TECH_FILE  $TSMC65_MW/techfiles/tsmcn65_${TSMC65_STACK}.tf
setenv SYN_STD_LEF    $TSMC65_HOME/Back_End/lef/tcbn65lpbwp7t_141a/lef/${TSMC65_STDCELL}_${TSMC65_STACK}.lef
# CCS (Composite Current Source) - a Synopsys format modelling the electrical behaviour of a cell
setenv SYN_STD_DB_DIR $TSMC65_HOME/Front_End/timing_power_noise/CCS/tcbn65lpbwp7t_141a

# The IO delivery splits by bond option and metal count, so mt_2/9lm
# rather than the flat directory the standard cells use.
setenv SYN_IO_LEF     $TSMC65_HOME/Back_End/lef/${TSMC65_IO}_200b/mt_2/9lm/lef/${TSMC65_IO}_9lm.lef

# Unlike the standard cells, whose db sits under milkyway/frame_only,
# the IO db is delivered beside its Liberty.
setenv SYN_IO_DB_DIR  $TSMC65_HOME/Front_End/timing_power_noise/NLDM/${TSMC65_IO}_200b

# The IO library is characterised at one core voltage and several IO
# supply voltages, all holding the same 60 cells. The suffix picks the
# IO supply, and an empty suffix is the 3.3V overdrive domain, whose
# wc/tc/bc are 3.0V/3.3V/3.6V. "1" is 2.5V and "2" is 1.8V.
#
# Empty is deliberate: it makes the IO db names line up with the
# standard cell corners, so one process label covers both libraries.
# Changing it changes the IO supply the whole chip is signed off at.
setenv TSMC65_IO_SUFFIX ""

# cup is circuit-under-pad, which is what puts the bond pad directly on
# top of the IO cell. 9M_6X2Z is the same stack as TSMC65_STACK above;
# the kit also ships 6X1Z1U and four others that are not ours.
setenv SYN_BPAD_LEF   $TSMC65_HOME/Back_End/lef/${TSMC65_BPAD}_200b/cup/9m/9M_6X2Z/lef/${TSMC65_BPAD}_9lm.lef

# --- Built NDM reference library ------------------------------------

# Where to look for the built libraries, in order. The first directory
# holding all five wins, so a shared read-only copy is used without
# anyone exporting anything. All five, not just the standard cell pair:
# a directory left over from before the pad libraries would otherwise
# be picked and then fail check_ndm.tcl. Nothing found means the last
# entry, which is where build_ndm.tcl then writes. An exported
# SYN_NDM_DIR always wins and is never overwritten.
#
# SITE: TODO add the shared read-only path to the front of ndm_search,
# e.g.  set ndm_search = ( /eda/shared/vlsi_ndm $HOME/vlsi_ndm )
# Until then the search finds nothing and falls back to a per-user
# build of about 36 MB.
if ( ! $?SYN_NDM_DIR ) then
    set ndm_search = ( $HOME/vlsi_ndm )
    # Keep in step with SYN_REF_LIBS and SYN_PAD_REF_LIBS below, which
    # cannot be reused here: they need SYN_NDM_DIR, set by this search.
    set ndm_files = ( ${TSMC65_STDCELL}_frame_timing.ndm \
                      ${TSMC65_STDCELL}_physical_only.ndm \
                      ${TSMC65_IO}_frame_timing.ndm \
                      ${TSMC65_IO}_physical_only.ndm \
                      ${TSMC65_BPAD}_physical_only.ndm )
    setenv SYN_NDM_DIR $ndm_search[$#ndm_search]
    foreach d ( $ndm_search )
        set complete = 1
        foreach f ( $ndm_files )
            if ( ! -e "$d/$f" ) set complete = 0
        end
        if ( $complete ) then
            setenv SYN_NDM_DIR $d
            break
        endif
    end
    unset ndm_search ndm_files complete d f
endif

# Two libraries, not one. Taps and fillers have no timing, so they are
# absent from the timed build and only exist in the physical-only one.
# Both must be on ref_libs or placement and filler insertion fail late.
setenv SYN_REF_LIBS   "$SYN_NDM_DIR/${TSMC65_STDCELL}_frame_timing.ndm $SYN_NDM_DIR/${TSMC65_STDCELL}_physical_only.ndm"

# Three more for a padring, kept off SYN_REF_LIBS so a lab without one
# does not load them or see their cells. A chip-level script appends
# them itself. The IO library splits the same way the standard cells
# do, because the corner and PFILLER cells have no timing either. The
# bond pads have no timing at all, so there is only the one.
setenv SYN_PAD_REF_LIBS "$SYN_NDM_DIR/${TSMC65_IO}_frame_timing.ndm $SYN_NDM_DIR/${TSMC65_IO}_physical_only.ndm $SYN_NDM_DIR/${TSMC65_BPAD}_physical_only.ndm"

# --- RC extraction ---------------------------------------------------
# TLUPlus belongs to the metal stack, not the cell library.
# 1p09m+alrdl = 1 poly, 9 metal, aluminium redistribution; top2 pairs
# with the T2 in the stack name above.
#
# No -layermap is passed: the kit ships no tf-to-ITF map, so layer names
# are assumed identical on both sides.

setenv SYN_TLUPLUS_DIR $TSMC65_MW/techfiles/tluplus
setenv SYN_TLUPLUS_MAX $SYN_TLUPLUS_DIR/cln65lp_1p09m+alrdl_rcworst_top2.tluplus
setenv SYN_TLUPLUS_MIN $SYN_TLUPLUS_DIR/cln65lp_1p09m+alrdl_rcbest_top2.tluplus
setenv SYN_TLUPLUS_TYP $SYN_TLUPLUS_DIR/cln65lp_1p09m+alrdl_typical_top2.tluplus

# --- Simulation models ----------------------------------------------

setenv SYN_SIM_MODELS $TSMC65_HOME/Front_End/verilog/tcbn65lpbwp7t_141a/${TSMC65_STDCELL}.v

# Needed to simulate a netlist that reaches the pads. The Verilog is a
# 200a delivery where everything else here is 200b.
setenv SYN_IO_SIM_MODELS $TSMC65_HOME/Front_End/verilog/${TSMC65_IO}_200a/${TSMC65_IO}.v

# --- OpenAccess, for Custom Compiler --------------------------------
# Custom Compiler reads lib.defs from its launch directory and nowhere
# else, so "custom" copies this file there. It INCLUDEs tsmcBE.lib for
# the cell libraries, which expands $TSMC_PDK_PATH to reach them.
#
# Add a library by adding a DEFINE line to the .libdefs, not by editing
# a working directory.

setenv SYN_LIBDEFS     $SYN_TOOLS_DIR/kits/tsmc65LP.libdefs

# Layer colours and fill patterns, read from the launch directory.
setenv SYN_DISPLAY_DRF $TSMC65_PDK/display.drf

# --- SRAM memory compiler --------------------------------------------
# TSMC's MC2, delivered inside the back-end kit rather than by Synopsys.
# Emits the .lib/.lef/.gds/.v views for a hard macro.

setenv SYN_MEMCOMP_DIR  $TSMC65_TSMCHOME/sram/Compiler
setenv SYN_MEMCOMP_DOCS $TSMC65_TSMCHOME/sram/Documentation/documents

# SITE: MC2 licence. Same machine cshrc.mc2 names by short hostname.
setenv SYN_MEMCOMP_LICENSE 7007@ee-llic01.ee.ic.ac.uk

# --- GDS stream out --------------------------------------------------
# The map belongs to the metal stack: 9lmT2 is 6X2Z, the same code the
# DRC deck below uses. The wrong map streams every shape to the wrong
# GDS layer without complaining.
#
# Without merging the cell GDS, write_gds emits every standard cell as
# an empty reference.

setenv SYN_GDS_MAP  $TSMC65_MW/gdsout_6X2Z.map
setenv SYN_CELL_GDS $TSMC65_OA_TSMCHOME/digital/Back_End/gds/${TSMC65_STDCELL}_141a/${TSMC65_STDCELL}.gds

# The same again for the pads. Both must be merged or the padring
# streams out as empty boxes and the chip cannot be bonded. Directory
# depth follows each library's own delivery, and the metal count and
# stack code must match TSMC65_STACK.
setenv SYN_IO_GDS   $TSMC65_OA_TSMCHOME/digital/Back_End/gds/${TSMC65_IO}_200b/mt_2/9lm/${TSMC65_IO}.gds
setenv SYN_BPAD_GDS $TSMC65_OA_TSMCHOME/digital/Back_End/gds/${TSMC65_BPAD}_200b/cup/9m/9M_6X2Z/${TSMC65_BPAD}.gds

# --- Signoff rule decks ----------------------------------------------
# Calibre decks. Its install root and licence are in
# synopsys_tools.cshrc.
#
# The DRC deck must match the metal stack. Calibre/drc/calibre.drc is
# the 6X1Z1U deck; ours is 9lmT2 = 1p9m_6X2Z0U, so the per-stack deck
# under Calibre/online is the correct one. The wrong deck checks the
# wrong via and thickness rules without complaining.

setenv TSMC65_DRC_RULES $TSMC65_PDK/Calibre/online/drc_online/1p9m_6X2Z0U/calibre.drc
setenv TSMC65_LVS_RULES $TSMC65_PDK/Calibre/lvs/calibre.lvs

# LVS source netlist. Must come from the same delivery as the layout
# views in tsmc65LP.libdefs, or LVS compares against different cells.
setenv TSMC65_LVS_SPICE $TSMC65_OA_TSMCHOME/digital/Back_End/spice/tcbn65lpbwp7t_141a/tcbn65lpbwp7t_141a.spi

# The same for the IO cells, needed by v2lvs at chip level. The kit
# ships _1_2 and _3; _3 is the one the Cadence signoff guide used and
# the one matching the 3.3V domain TSMC65_IO_SUFFIX selects. Change
# both together.
#
# The bond pads ship no SPICE at all, which is why the signoff guide
# says to comment out the PAD60LU_SL instances before running v2lvs.
setenv TSMC65_IO_LVS_SPICE $TSMC65_OA_TSMCHOME/digital/Back_End/spice/${TSMC65_IO}_200b/${TSMC65_IO}_3.spi

# Needed when Calibre reads the design straight out of OpenAccess.
setenv TSMC65_OA_LAYERMAP $TSMC65_PDK/tsmcN65/tsmcN65.layermap

# --- Tcl half --------------------------------------------------------

setenv SYN_KIT_TCL $SYN_TOOLS_DIR/kits/tsmc65LP.tcl
