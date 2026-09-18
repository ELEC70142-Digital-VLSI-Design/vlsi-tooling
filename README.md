##### Imperial College London, Department of Electrical & Electronic Engineering


#### ELEC70142 Digital VLSI Design

### Lab 0 - EDA Environment Setup

##### *Peter Cheung, v2.0 - 15 September 2026*
---

**Synopsys** is one of the main suppliers of the software used to design integrated circuits. Their tools take a design written in SystemVerilog and turn it into the masks that a foundry can use to manufacture the silicon die. Across these labs you will use **_Fusion Compiler_**, **_VCS_**, **_Custom Compiler_**, **_TestMAX_** and **_Formality_**. You will also use tools from Siemens, mainly **_Calibre_**.  These tools are hosted on two powerful teaching servers: ee-flip and ee-flop.

A tool on its own knows nothing about the silicon fabrication process that is used to make the chip. That information comes from a **process design kit (PDK)**, supplied by the foundry itself. It describes the specific manufacturing process used: the transistor types, the interconnect layers, the design rules, and a library of logic gates already built and characterised for it. We use TSMC's 65nm low power CMOS process.

This lab puts the tools and a PDK on your `PATH`. The following labs depend on this setup.

---
### Before you start
---

>Before you even start this laboratory session, you must have signed the TSMC's **non-disclosure agreement (NDA)**, and have returned this to me.  Remember that you MUST abide by the restrictions stipulated in the NDA.

Although you could use the PCs provided by the Department in Room 507 for this lab, I recommend that you bring your own laptop. There are many display units in the room for you to plug in your laptop and use a larger screen for this lab. You will be working in pairs.

If you are using a Windows PC, you will need to have [MobaXterm](https://mobaxterm.mobatek.net) installed via College's [software hub](https://softwarehub.imperial.ac.uk). This provides a feature-rich terminal environment with built-in X server and ssh client.

If you are a MacBook user, you already have the Terminal application as part of OSX. You also need to install [XQuartz](https://www.xquartz.org) X server.

> You will open three graphical windows in this lab: the Fusion Compiler layout viewer, GTKWave, and optionally Verdi. All three need a working X server, so connect with `ssh -Y` and do not skip the X server installation.

You may also want to clone this repo onto your own laptop, so that you have a local copy of the instructions and related files. As part of the assessment, you are expected to keep and show your logbook to your assessor during the mid-term Lab Oral. You may keep your logbook using any application you wish, e.g. MS WORD, MS OneNote, Obsidian or Notion. However, one possible choice is to keep your logbook with your cloned repo.

If you are EE4 students, you may not have extensive exposure to Github and Markdown language. I am afraid you will have to learn these skills taking this module. Your final project submission will have to be in the form of a Github repo. In any case, all EEE graduates should be familiar with these skills.

---
### Task 1 - Connect to the Teaching Server
---

**_Step 1: Connect_**

To access Imperial College's resources from your personal laptop when you are not in College, you will need to connect to the Universal Access provision after running [Zscaler](https://www.imperial.ac.uk/admin-services/ict/self-service/connect-communicate/remote-access/unified-access/). After authentication, you will be able to access file systems and computer servers.

Synopsys is installed and runs on the EEE teaching servers, which you access via SSH. There are two servers available:

* ee-flip.ee.ic.ac.uk
* ee-flop.ee.ic.ac.uk

To balance the loading on these two servers, please use **_ee-flip_** if your group number is **odd**, and **_ee-flop_** if it is **even**. A list of groups can be found [here](group_allocation.txt).

For **Windows**: Use [MobaXterm](https://mobaxterm.mobatek.net) to create a new session by entering the server address with your username and password.

For **Mac**: Use [XQuartz](https://www.xquartz.org). After installation and opening XQuartz, enter:
```bash
ssh -Y <username>@ee-flip.ee.ic.ac.uk
```

---
### Task 2 - Get the files onto your home folder on the teaching server
---

**_Where to put this repository on the server_**

The lab instructions assume you clone it into a suitable folder in your home directory on one of the two teaching servers - e.g. `~/Labs`, alongside the lab directories:
```
~/Labs/
├── vlsi-tooling/     <- this repository
├── Lab_1/
├── Lab_2/
...
```

Clone the repository into `~/Labs`:

```bash
mkdir -p ~/Labs
cd ~/Labs
git clone https://github.com/ELEC70142-Digital-VLSI-Design/vlsi-tooling.git
```

> If you copied the files across with `scp` rather than cloning them, the executable bit is not always preserved. Restore it with `chmod +x ~/Labs/vlsi-tooling/syn`.

---
### Task 3 - Load the tools and a PDK
---

**_Step 1: See which PDKs are available_**

```bash
cd ~/Labs
vlsi-tooling/syn
```

This lists every kit the repository knows about with a one line description. It also confirms the wrapper runs at all.

**_Step 2: Load the TSMC 65nm low power kit_**

```bash
vlsi-tooling/syn tsmc65LP
```

> `syn` replaces your shell with a **fresh tcsh** carrying the environment. This is deliberate: it means the setup can never half-apply itself to the shell you were working in. It also loads **one PDK per shell**, so to switch PDK you type `exit` first.

You must run `syn` once in every terminal window, before the first Synopsys tool in that window. Nothing is written to your `~/.cshrc`.

**_Step 3: Read what it prints_**

The load prints three blocks. Read them rather than scrolling past.

| Block | What to look for |
|---|---|
| `tools` | The resolved path of each tool. `NOT ON PATH` against a tool means the install was not found, and that tool will not run. |
| `kit: tsmc65LP` | The technology file, reference libraries and Tcl setup for the PDK. The `ref libs` line is where the shared libraries were found. |
| `licences` | The licence servers being used. |

**_Step 4: Check the environment by hand_** (optional)

```bash
which fc_shell
echo $SYN_TOOLS_DIR
ls -l $SYN_TECH_FILE
```

`$SYN_TOOLS_DIR` is the path to this repository. Use it whenever a lab asks you to run a script from here, and the command will work from any directory.

---
### Task 4 - Check the reference libraries
---

Fusion Compiler does not read the foundry's Liberty and LEF files directly. It reads its own format, an **NDM** library, and the TSMC kit does not ship one. These have been built for you and put in a shared read-only location, so there is nothing here for you to build. The `ref libs` line printed in Task 2 is where they were found.

There are **five**. Two hold the standard cells, split because the fillers and tap cells have no timing arcs and so are absent from the timed library. The other three hold the IO cells and bond pads, which only the project uses.

Check that they are readable and complete before going any further:

```bash
fc_shell -x "source $SYN_TOOLS_DIR/check_ndm.tcl"
```

Expect:

```
 special cells       : all 28 present
 pad cells           : all 15 present

PASS
```

This checks the contents rather than the exit status, because a library can exist and still be empty or missing cells. The 28 are the cells the place and route scripts ask for **by name**: the tap cell, the tie cells, the fillers, and the clock tree buffers and inverters. A missing cell will otherwise surfaces much later as a confusing placement or clock tree error.

If you see `FAIL`, or the check reports a library that does not exist, stop and ask for help.

---
### Task 5 - Unload
---

```bash
exit
```

This drops you back into the shell you started from and removes the environment with it. Since only one PDK can be loaded per shell, this is also how you switch PDK.

---
### Files in this repository
---

| File | What it is |
|---|---|
| `syn` | Lists the available PDKs, or loads one into a fresh shell. |
| `custom` | Prepares the current directory, then launches Custom Compiler in it. |
| `memcomp` | Launches TSMC's MC2 memory compiler in the current directory. |
| `stil2verilog` | Wrapper round the TestMAX pattern translator, which needs a system library that is not on the default path. |
| `setup.cshrc` | Entry point: sources the tool file, then the kit file, then reports what resolved. |
| `synopsys_tools.cshrc` | Tool paths, version discovery and licence servers, independent of any PDK. |
| `kits/<kit>.cshrc` | Every filesystem path belonging to one PDK, exported into the environment. |
| `kits/<kit>.tcl` | The same paths under shorter names for Tcl scripts, plus cell names, corners and layers. |
| `kits/<kit>.libdefs` | The OpenAccess library list, copied into your working directory as `lib.defs`. |
| `build_ndm.tcl` | Builds the shared NDM reference libraries from the foundry's LEF and Liberty files, standard cells plus the IO and bond pad libraries a padring needs. Run once by a maintainer, not per student. |
| `check_ndm.tcl` | Reports whether those libraries are readable and hold the cells the labs and the project ask for by name. |

Load order is `syn` -> `setup.cshrc` -> `synopsys_tools.cshrc` -> `kits/<kit>.cshrc`.

No script in any lab contains a PDK path. They start with `source $env(SYN_KIT_TCL)` and use the names defined there, so changing PDK means loading a different kit and nothing else.

Running this anywhere else, e.g. other EEE teaching servers, needs a handful of paths changed. See [docs/site_setup.md](docs/site_setup.md).
