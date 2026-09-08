# Setting up the environment on a different server

Which paths are hardcoded to this site (ee-mill2 for now), where they live, and when each one needs changing.
Not needed for the labs themselves; see the [README](../README.md) for those.

---

The labs assume the EEE teaching servers, where the Synopsys install and the TSMC libraries are already in place. On any other machine a handful of paths need changing. Each is marked in the scripts with a `SITE:` comment:

```bash
grep -rn "SITE:" ~/Labs/vlsi-tooling
```

| Value | File | Change it if |
|---|---|---|
| `SYN_DIR` | `synopsys_tools.cshrc` | The Synopsys install lives elsewhere, or the academic year has rolled over. |
| `SNPSLMD_LICENSE_FILE` | `synopsys_tools.cshrc` | Your licence is served from somewhere else. |
| `MGC_HOME` | `synopsys_tools.cshrc` | Calibre, used for signoff DRC and LVS, is installed elsewhere. |
| `TSMC65_HOME` | `kits/tsmc65LP.cshrc` | The TSMC back-end kit is installed elsewhere. |
| `SYN_MEMCOMP_LICENSE` | `kits/tsmc65LP.cshrc` | The memory compiler licence is served elsewhere. |
| `ndm_search` | `kits/tsmc65LP.cshrc` | The shared reference libraries are somewhere else, or there is no shared copy and each user builds their own. |
| PDK root | `kits/tsmc65LP.libdefs` | The front-end TSMC PDK is installed elsewhere. These paths are literal, as the file is copied verbatim. |

The reference libraries are the one thing you can redirect without editing anything. `ndm_search` in the kit file lists the directories that are looked in, and the first one holding both libraries wins. To use a location outside that list, export `SYN_NDM_DIR` before loading and it beats the search:

```bash
setenv SYN_NDM_DIR /path/to/shared/ndm
vlsi-tooling/syn tsmc65LP
```

Everything else in `kits/tsmc65LP.cshrc` is a choice of library rather than a path to a machine: the 9lmT2 metal stack, the 7-track standard-Vt cells and the matching TLUPlus files. Those three must stay consistent with each other.

---

## Building the reference libraries

Fusion Compiler reads NDM, and the TSMC kit ships Milkyway, so the reference libraries are
built rather than delivered. Students do not do this: one copy is built and shared, and the
Lab 0 README tells them to check it, not make it. Build it with the kit loaded:

```bash
lm_shell -f $SYN_TOOLS_DIR/build_ndm.tcl
fc_shell -f $SYN_TOOLS_DIR/check_ndm.tcl
```

The build takes a few minutes and writes about 36 MB. It ends with `BUILD OK` or
`BUILD FAILED`, then exits. Expect a large number of warnings on the way: the foundry
Liberty files do not declare every attribute the library builder wants. Only lines
beginning `Error` matter.

Two libraries come out, not one. Fillers and tap cells have no timing arcs, so they are
dropped by the timed pass and built separately by a physical-only pass. Both must be on
`ref_libs` or filler insertion fails late in place and route.

Put the result somewhere world-readable and add that path to the front of `ndm_search` in
`kits/tsmc65LP.cshrc`, so it is found without anyone exporting a variable.
