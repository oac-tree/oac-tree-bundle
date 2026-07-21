#!/usr/bin/env bash
#
# Network-free smoke test for the oac-tree-bundle super-build.
#
# Purpose: prove that a completed build produced *working* artifacts, without
# relying on the unit-test suites (which need EPICS Channel Access/PVAccess, a
# soft IOC, a running server or an on-screen display -- none available on CI
# runners).
#
# After setting up the loader path, it runs the checks below -- each as its own
# log group, escalating from "installed" to "actually runs". The numbers match
# the '::group::' titles in the script:
#   1. Artifact existence       -- expected binaries and plugin libraries exist.
#   2. Shared-library resolution -- every binary/plugin's dependencies resolve
#      (no missing libs); this also covers the GUI/server binaries without
#      launching them.
#   3. oac-tree-cli --help      -- the CLI starts and its argument parser works.
#   4. oac-tree-cli --validate  -- a tiny plugin-free procedure parses/sets up.
#   5. oac-tree-cli run         -- the same procedure executes to completion.
#
# Usage: smoke-test.sh [install-prefix]
#   install-prefix defaults to ${GITHUB_WORKSPACE}/install
#
set -euo pipefail

prefix="${1:-${GITHUB_WORKSPACE:-$PWD}/install}"
here="$(cd "$(dirname "$0")" && pwd)"
fixture="${here}/local-only.xml"

fail() { echo "SMOKE FAIL: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Make the freshly-installed libraries loadable so the checks below (ldd/otool
# and the CLI runs) can resolve everything from the install tree.
echo "::group::Set up loader path"
# Prepend the install lib dirs -- oac-tree-path.sh only adds 'lib', so 'lib64'
# and the plugin dir are added explicitly -- plus, defensively, the EPICS/PVXS
# lib dirs that dependent libraries may reference.
# Indirect variable expansion (${!var}) is deliberately avoided: macOS ships
# bash 3.2, which rejects it when combined with a default value.
extra="${prefix}/lib:${prefix}/lib64:${prefix}/lib/oac-tree/plugins"
if [ -n "${EPICS_BASE:-}" ] && [ -n "${PVXS_DIR:-}" ] && [ -x "${EPICS_BASE}/startup/EpicsHostArch" ]; then
  arch="$(${EPICS_BASE}/startup/EpicsHostArch)"
  extra="${extra}:${EPICS_BASE}/lib/${arch}:${PVXS_DIR}/lib/${arch}"
fi
# Linux uses LD_LIBRARY_PATH, macOS uses DYLD_LIBRARY_PATH.
case "$(uname -s)" in
  Darwin) export DYLD_LIBRARY_PATH="${extra}:${DYLD_LIBRARY_PATH:-}"; loaderpath="${DYLD_LIBRARY_PATH}" ;;
  *)      export LD_LIBRARY_PATH="${extra}:${LD_LIBRARY_PATH:-}";     loaderpath="${LD_LIBRARY_PATH}" ;;
esac
# oac-tree-path.sh reads unguarded variables (e.g. DYLD_LIBRARY_PATH), which
# would trip 'set -u' and abort this script; source it with -e/-u disabled.
# It is only a convenience here -- the paths above already cover the CLI's needs.
set +eu
# shellcheck disable=SC1091
source "${prefix}/bin/oac-tree-path.sh" >/dev/null 2>&1 || true
set -eu
echo "loader path: ${loaderpath}"
echo "::endgroup::"

# ---------------------------------------------------------------------------
# Confirm the build installed the artifacts a working install must contain.
echo "::group::1. Artifact existence"
cli="${prefix}/bin/oac-tree-cli"
[ -x "${cli}" ] || fail "missing executable ${cli}"
[ -f "${prefix}/bin/oac-tree-path.sh" ] || fail "missing ${prefix}/bin/oac-tree-path.sh"

# Core shared library. Both the file extension (.so/.dylib) and the lib dir
# (lib/lib64) vary by platform, so match loosely.
if ! ls "${prefix}"/lib*/liboac-tree.* >/dev/null 2>&1; then
  fail "core library liboac-tree.* not found under ${prefix}/lib or lib64"
fi

# Plugins are optional (a COA_NO_PLUGINS build ships none), but if the plugin
# directory exists it must actually contain plugin libraries. Match both naming
# conventions -- macOS 'lib....X.Y.Z.dylib' and Linux 'lib....so.X.Y.Z' -- and
# count symlinks too (so do not restrict to -type f).
plugin_dir="${prefix}/lib/oac-tree/plugins"
if [ -d "${plugin_dir}" ]; then
  if [ -z "$(find "${plugin_dir}" -maxdepth 1 \( -name '*.so' -o -name '*.so.*' -o -name '*.dylib' -o -name '*.dylib.*' \) 2>/dev/null | head -n1)" ]; then
    fail "plugin directory ${plugin_dir} exists but contains no plugin libraries"
  fi
  echo "plugins found:"
  ls -1 "${plugin_dir}"
fi
echo "::endgroup::"

# ---------------------------------------------------------------------------
# Every installed binary and plugin must have all of its shared-library
# dependencies resolvable -- this catches broken RPATHs and missing libraries,
# and covers the GUI/server binaries without launching them.
echo "::group::2. Shared-library resolution"
# Report any dependency the dynamic loader lists as 'not found'.
resolve() {
  local f="$1" out
  case "$(uname -s)" in
    Darwin) out="$(otool -L "$f" 2>/dev/null || true)" ;;
    *)      out="$(ldd "$f" 2>/dev/null || true)" ;;
  esac
  if printf '%s\n' "$out" | grep -q 'not found'; then
    printf '%s\n' "$out" | grep 'not found' >&2
    fail "unresolved shared libraries in $f"
  fi
}
# All installed executables.
for f in "${prefix}"/bin/*; do
  [ -f "$f" ] && [ -x "$f" ] || continue
  echo "checking $f"
  resolve "$f"
done
# All plugin libraries (versioned files and symlinks alike).
if [ -d "${plugin_dir}" ]; then
  shopt -s nullglob
  for f in "${plugin_dir}"/*.so "${plugin_dir}"/*.so.* "${plugin_dir}"/*.dylib "${plugin_dir}"/*.dylib.*; do
    [ -e "$f" ] || continue
    echo "checking $f"
    resolve "$f"
  done
  shopt -u nullglob
fi
echo "::endgroup::"

# ---------------------------------------------------------------------------
# The CLI starts and its argument parser works.
echo "::group::3. oac-tree-cli --help"
"${cli}" --help >/dev/null || fail "oac-tree-cli --help returned non-zero"
echo "::endgroup::"

# ---------------------------------------------------------------------------
# The procedure parses and sets up: exercises the XML parser, the instruction
# registry and workspace wiring -- without executing anything.
echo "::group::4. oac-tree-cli --validate"
out="$("${cli}" --validate -f "${fixture}")" || fail "validate returned non-zero"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qi 'successful' || fail "validate output missing success message"
echo "::endgroup::"

# ---------------------------------------------------------------------------
# The procedure runs to completion: proves the executor and core instructions
# actually work end to end.
echo "::group::5. oac-tree-cli run"
"${cli}" -f "${fixture}" || fail "running the procedure returned non-zero"
echo "::endgroup::"

echo "SMOKE PASS: build artifacts validated via oac-tree-cli"
