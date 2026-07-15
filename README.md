# oac-tree-bundle

[![Linux](../../actions/workflows/linux-build.yml/badge.svg)](../../actions/workflows/linux-build.yml)
[![macOS](../../actions/workflows/macos-build.yml/badge.svg)](../../actions/workflows/macos-build.yml)

Super build for all `oac-tree` packages.

## Continuous integration

Two manually triggered (`workflow_dispatch`) GitHub Actions workflows build the
whole stack from source, including the EPICS `epics-base` and `pvxs`
dependencies, and run the unit tests of every module:

- **Linux** — Ubuntu LTS, GCC.
- **macOS** — Apple Silicon, Clang.

Run them from the **Actions** tab via the **Run workflow** button.

## Build from source

```bash
git clone --recurse-submodules https://github.com/oac-tree/oac-tree-bundle.git
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=<INSTALL_PREFIX> ..
make
```

Building requires a working installation of `epics-base` and `pvxs` (with the
`EPICS_BASE` and `PVXS_DIR` environment variables set), plus `cmake`, `libxml2`,
`gtest`, `libevent` and, for the GUI, `qt6`.
