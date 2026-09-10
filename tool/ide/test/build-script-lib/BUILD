# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@rules_rust//rust:defs.bzl", "rust_library")
load("@typedb_dependencies//library/crates:defs.bzl", "cargo_build_dep_tag")
load("@typedb_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

# Mimics a crate whose Bazel build compiles a generated source (e.g. protobuf codegen) while the
# cargo build uses a checked-in entry point plus a build script with its own build dependencies.
genrule(
    name = "build_script_lib_gen_src",
    outs = ["build_script_lib_gen.rs"],
    cmd = "echo 'pub fn generated() {}' > $@",
)

rust_library(
    name = "build-script-lib",
    srcs = [":build_script_lib_gen_src"],
    crate_root = ":build_script_lib_gen_src",
    tags = [
        "cargo-entry-point=lib.rs",
        "cargo-build-script=build.rs",
        cargo_build_dep_tag("tonic-build"),
    ],
    visibility = ["//visibility:public"],
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = ["Cargo.toml"],
    license_type = "mpl-header",
    size = "small",
)
