#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


# Script for regenerating BUILD files after Cargo.toml update
# Fetches a standalone cargo binary (no rust toolchain)

set -ex

if [ ! -x cargo ]; then
    arch=$(bash --version | head -n1 | grep -o '\S\+$')  # (arch-vendor-os)
    arch=${arch#(} && arch=${arch%)} # strip parentheses
    if [[ $arch == x86_64-apple-darwin* ]]; then
        curl -o cargo https://repo.typedb.com/public/public-tools/raw/versions/1.66.0_darwin_x86_64/cargo
    elif [[ $arch == arm64-apple-darwin* ]]; then
        curl -o cargo https://repo.typedb.com/public/public-tools/raw/versions/1.66.0_darwin_arm64/cargo
    elif [[ $arch == x86_64-*-linux* ]]; then
        curl -o cargo https://repo.typedb.com/public/public-tools/raw/versions/1.66.0_linux_x86_64/cargo
    else
        echo "Unsupported architecture: $arch"
        exit 1
    fi
    chmod +x cargo
fi
