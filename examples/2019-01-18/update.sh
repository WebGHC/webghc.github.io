#!/usr/bin/env bash

set -xeuo pipefail

mkdir roots
trap "rm -r roots" EXIT

nix build -f '<wasm-cross/release.nix>' examples -o roots/root
for f in roots/root*; do
    n=$(readlink "$f" | sed 's|/nix/store/\w*-\(.*\)|\1|')
    rm -r "$n"
    cp -rL --no-preserve=all "$f" "$n"
done
