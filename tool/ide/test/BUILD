# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@rules_rust//rust:defs.bzl", "rust_library")
load("@vaticle_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

rust_library(
    name = "test-lib",
    srcs = ["lib.rs"],
    deps = ["@vaticle_extern//:a"],
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = [".bazelversion"],
    license_type = "mpl-header",
    size = "small",
)
