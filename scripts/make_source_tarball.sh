#!/usr/bin/env bash
#
# Creates oac-tree-bundle-<versions>-src.tar.gz: the bundle at HEAD plus all module sources.
#
# Usage: scripts/make_source_tarball.sh <versions> [output_dir]

set -euo pipefail

versions=${1:?"usage: $0 <versions> [output_dir]"}
out_dir=${2:-.}
mkdir -p "${out_dir}"
out_dir=$(cd "${out_dir}" && pwd)
bundle_dir=$(cd "$(dirname "$0")/.." && pwd)
name=oac-tree-bundle-${versions}

work_dir=$(mktemp -d)
trap 'rm -rf "${work_dir}"' EXIT

git -C "${bundle_dir}" archive --format=tar --prefix="${name}/" HEAD | tar -x -C "${work_dir}"
cmake -DOAC_TREE_VERSIONS="${versions}" -DDEST="${work_dir}/${name}/modules" -DKEEP_GIT=OFF \
  -P "${bundle_dir}/scripts/fetch_sources.cmake"

tar -czf "${out_dir}/${name}-src.tar.gz" -C "${work_dir}" "${name}"
echo "Created ${out_dir}/${name}-src.tar.gz"
