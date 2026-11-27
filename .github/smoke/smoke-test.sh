#!/usr/bin/env bash
#
# Network-free smoke test of an installed oac-tree bundle.
#
# Checks:
#   1. Artifact existence: CLI, core library and plugins are installed.
#   2. Shared-library resolution: no missing dependencies of binaries and plugins.
#   3. oac-tree-cli --help
#   4. oac-tree-cli --validate on a plugin-free procedure.
#   5. oac-tree-cli runs the same procedure.
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
echo "::group::Set up loader path"
# Install lib dirs, plugin dir and EPICS/PVXS lib dirs.
# No ${!var}: macOS bash 3.2 rejects it with a default value.
extra="${prefix}/lib:${prefix}/lib64:${prefix}/lib/oac-tree/plugins"
if [ -n "${EPICS_BASE:-}" ] && [ -n "${PVXS_DIR:-}" ] && [ -x "${EPICS_BASE}/startup/EpicsHostArch" ]; then
  arch="$(${EPICS_BASE}/startup/EpicsHostArch)"
  extra="${extra}:${EPICS_BASE}/lib/${arch}:${PVXS_DIR}/lib/${arch}"
fi
case "$(uname -s)" in
  Darwin) export DYLD_LIBRARY_PATH="${extra}:${DYLD_LIBRARY_PATH:-}"; loaderpath="${DYLD_LIBRARY_PATH}" ;;
  *)      export LD_LIBRARY_PATH="${extra}:${LD_LIBRARY_PATH:-}";     loaderpath="${LD_LIBRARY_PATH}" ;;
esac
# oac-tree-path.sh reads unset variables, so source it without -e/-u.
set +eu
# shellcheck disable=SC1091
source "${prefix}/bin/oac-tree-path.sh" >/dev/null 2>&1 || true
set -eu
echo "loader path: ${loaderpath}"
echo "::endgroup::"

# ---------------------------------------------------------------------------
echo "::group::1. Artifact existence"
cli="${prefix}/bin/oac-tree-cli"
[ -x "${cli}" ] || fail "missing executable ${cli}"
[ -f "${prefix}/bin/oac-tree-path.sh" ] || fail "missing ${prefix}/bin/oac-tree-path.sh"

# Extension (.so/.dylib) and lib dir (lib/lib64) vary by platform.
if ! ls "${prefix}"/lib*/liboac-tree.* >/dev/null 2>&1; then
  fail "core library liboac-tree.* not found under ${prefix}/lib or lib64"
fi

# Plugin dir is absent with COA_NO_PLUGINS. If present, it must contain plugins.
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
echo "::group::2. Shared-library resolution"
# Fails if the loader reports a dependency as 'not found'.
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
for f in "${prefix}"/bin/*; do
  [ -f "$f" ] && [ -x "$f" ] || continue
  echo "checking $f"
  resolve "$f"
done
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
echo "::group::3. oac-tree-cli --help"
"${cli}" --help >/dev/null || fail "oac-tree-cli --help returned non-zero"
echo "::endgroup::"

# ---------------------------------------------------------------------------
echo "::group::4. oac-tree-cli --validate"
out="$("${cli}" --validate -f "${fixture}")" || fail "validate returned non-zero"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qi 'successful' || fail "validate output missing success message"
echo "::endgroup::"

# ---------------------------------------------------------------------------
echo "::group::5. oac-tree-cli run"
"${cli}" -f "${fixture}" || fail "running the procedure returned non-zero"
echo "::endgroup::"

echo "SMOKE PASS: build artifacts validated via oac-tree-cli"
