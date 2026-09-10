# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

###############################################################################
# DEPRECATED: This WORKSPACE file is kept for backward compatibility only.
# New projects should use MODULE.bazel (Bzlmod) instead.
# To use WORKSPACE mode, add `common --enable_workspace=true` to .bazelrc
###############################################################################

workspace(name = "typedb_dependencies")

load("//library/crates:crate_versions.bzl", "crate_versions_repository")
crate_versions_repository(
    name = "crate_versions",
    manifest = "//library/crates:Cargo.toml",
)

################################
# Load @typedb_dependencies #
################################

# Load //builder/rust (includes rules_cc and rules_rust)
load("//builder/rust:deps.bzl", rust_deps = "deps")
rust_deps()
load("@rules_cc//cc:repositories.bzl", "rules_cc_dependencies", "rules_cc_toolchains")
rules_cc_dependencies()
rules_cc_toolchains()
load("@rules_rust//rust:repositories.bzl", "rules_rust_dependencies")
rules_rust_dependencies()
load("@rules_rust//tools/rust_analyzer:deps.bzl", "rust_analyzer_dependencies")
rust_analyzer_dependencies()
load("//builder/rust:versions.bzl", "rust_toolchain_versioned")
rust_toolchain_versioned()

# Load //builder/python
load("//builder/python:deps.bzl", "rules_python")
rules_python()
load("@rules_python//python:repositories.bzl", "py_repositories")
py_repositories()

# Load //builder/java
load("//builder/java:deps.bzl", "rules_java", "rules_jvm_external")
rules_java()
rules_jvm_external()
load("//library/maven:rules.bzl", "maven")

# Load //builder/kotlin
load("//builder/kotlin:deps.bzl", "io_bazel_rules_kotlin")
io_bazel_rules_kotlin()
load("@io_bazel_rules_kotlin//kotlin:repositories.bzl", "kotlin_repositories")
kotlin_repositories()
load("@io_bazel_rules_kotlin//kotlin:core.bzl", "kt_register_toolchains")
kt_register_toolchains()

# Load //common
load("//common/java:artifacts.bzl", typedb_common_maven_artifacts = "maven_artifacts")

load("//library/ortools/cc:deps.bzl", "google_or_tools_mac", "google_or_tools_linux", "google_or_tools_windows")
google_or_tools_mac()
google_or_tools_linux()
google_or_tools_windows()

# Load //tool/common
load("//tool/common:deps.bzl", "typedb_dependencies_ci_pip", common_tool_maven_artifacts = "maven_artifacts")
typedb_dependencies_ci_pip()
load("@typedb_dependencies_ci_pip//:requirements.bzl", "install_deps")
install_deps()

# Load //tool/checkstyle
load("//tool/checkstyle:deps.bzl", checkstyle_deps = "deps")
checkstyle_deps()

# Load //tool/unuseddeps
load("//tool/unuseddeps:deps.bzl", unuseddeps_deps = "deps")
unuseddeps_deps()

# Load //tool/sonarcloud
load("//tool/sonarcloud:deps.bzl", "sonarcloud_dependencies")
sonarcloud_dependencies()

# Load //tool/swig
load("//tool/swig:deps.bzl", "swig")
swig()

###################################
# Load @typedb_bazel_distribution #
###################################

# Load @typedb_bazel_distribution
load("//distribution:deps.bzl", "typedb_bazel_distribution")
typedb_bazel_distribution()

# Load //@typedb_bazel_distribution//common
load("@typedb_bazel_distribution//common:deps.bzl", "rules_pkg")
rules_pkg()
load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")
rules_pkg_dependencies()

# Load @typedb_bazel_distribution_cloudsmith
load("@typedb_bazel_distribution//common/uploader:deps.bzl", "typedb_bazel_distribution_uploader")
typedb_bazel_distribution_uploader()
load("@typedb_bazel_distribution_uploader//:requirements.bzl", uploader_install_deps = "install_deps")
uploader_install_deps()

# Load Maven artifacts
maven(
    typedb_common_maven_artifacts +
    common_tool_maven_artifacts
)

# Load Rust Crate dependencies
load("@rules_rust//crate_universe:repositories.bzl", "crate_universe_dependencies")
crate_universe_dependencies()

load("//library/crates:crates.bzl", "fetch_crates")
fetch_crates()
load("@crates//:defs.bzl", "crate_repositories")
crate_repositories()

###############################################
# Create @typedb_dependencies_workspace_refs  #
###############################################

load("@typedb_bazel_distribution//common:rules.bzl", "workspace_refs")
workspace_refs(name = "typedb_dependencies_workspace_refs")
