# oac-tree-bundle

[![Linux](../../actions/workflows/linux-build.yml/badge.svg)](../../actions/workflows/linux-build.yml)
[![macOS](../../actions/workflows/macos-build.yml/badge.svg)](../../actions/workflows/macos-build.yml)

Super build for all `oac-tree` packages.

## Requirements

`epics-base` and `pvxs` (with the `EPICS_BASE` and `PVXS_DIR` environment variables set),
`cmake`, `git`, `libxml2`, `gtest`, `libevent` and, for the GUI, `qt6`.

## Build from source

Will build the latest release of the bundle.

```bash
git clone https://github.com/oac-tree/oac-tree-bundle.git
cd oac-tree-bundle
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=<INSTALL_PREFIX>
cmake --build build -j
cmake --install build
source <INSTALL_PREFIX>/bin/oac-tree-path.sh
```

Modules are cloned from GitHub and built during `cmake --build`. Each one is installed into
`build/stage/<INSTALL_PREFIX>`, where the next modules find it. `cmake --install` copies
that tree to `<INSTALL_PREFIX>`. Set `CMAKE_INSTALL_PREFIX` at configure time: some modules
compile the install path in.

### Build different versions of the bundle

The `versions/` directory holds one file per bundle release, plus `develop.cmake` for the
development branches. Each file gives the git tag or branch of every module.

```bash
cmake -S . -B build                              # release of this bundle version
cmake -S . -B build -DOAC_TREE_VERSIONS=1.5      # older release
cmake -S . -B build -DOAC_TREE_VERSIONS=develop  # develop branches
cmake -S . -B build -DOAC_TREE_VERSIONS=/path/to/my-versions.cmake
```

Use a new build directory when switching versions.

### Options

| Option | Default | Description |
|---|---|---|
| `OAC_TREE_VERSIONS` | bundle version | Name of a file in `versions/`, or a path to a file. |
| `OAC_TREE_GIT_BASE_URL` | `https://github.com/oac-tree` | Base URL of module repositories. |
| `OAC_TREE_SOURCE_DIR_<module>` | | Local source directory of a module, e.g. `-DOAC_TREE_SOURCE_DIR_oac-tree=$HOME/src/oac-tree`. |
| `OAC_TREE_UPDATE` | `OFF` | Fetch new commits of git branches on every build. |
| `COA_BUILD_TESTS` | `ON` | Build unit tests of all modules. |
| `COA_NO_PLUGINS` | `OFF` | Do not build oac-tree plugins. |
| `COA_NO_GUI` | `OFF` | Do not build the GUI. |

### Source location

For each module, the build uses the first of:

1. `OAC_TREE_SOURCE_DIR_<module>`, if set.
2. `modules/<module>`, if present.
3. A git clone of the version from `OAC_TREE_VERSIONS`.

## Offline build

Each GitHub release has an `oac-tree-bundle-<version>-src.tar.gz` asset with the sources of
all modules in `modules/`. It builds without network access:

```bash
tar -xzf oac-tree-bundle-1.6-src.tar.gz
cd oac-tree-bundle-1.6
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=<INSTALL_PREFIX>
cmake --build build -j
cmake --install build
```

To fill `modules/` yourself:

```bash
cmake -DOAC_TREE_VERSIONS=develop -P scripts/fetch_sources.cmake
```

To create a tarball: `scripts/make_source_tarball.sh <versions> [output_dir]`.

## Continuous integration

Manually triggered (`workflow_dispatch`) workflows build the whole stack from source,
including `epics-base` and `pvxs`:

- **Linux**: Ubuntu LTS, GCC.
- **macOS**: Apple Silicon, Clang.

Run them from the **Actions** tab with **Run workflow**. The `versions` input selects the
module versions: `develop` (default) or a release such as `1.6`.

The **Source tarball** workflow attaches the source tarball to each published release.

## Release

1. Add `versions/<X.Y>.cmake` with the module tags.
2. Set `project(oac-tree-bundle VERSION <X.Y>.0)` in `CMakeLists.txt`.
3. Commit, push, and publish a GitHub release with tag `v<X.Y>`.
