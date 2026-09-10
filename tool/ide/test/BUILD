# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@rules_rust//rust:defs.bzl", "rust_library")
load("@typedb_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

rust_library(
    name = "test-lib",
    srcs = ["lib.rs"],
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = [".bazelversion", ".bazelrc", "Cargo.toml", "Cargo.lock", "MODULE.bazel.lock"],
    license_type = "mpl-header",
    size = "small",
)
