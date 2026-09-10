# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Exposes the crate versions pinned in the crate universe manifest (library/crates/Cargo.toml)
# as a loadable Starlark dict (@crate_versions//:versions.bzl%CRATE_VERSIONS), so BUILD files
# can reference a pin instead of duplicating a version literal.

def _parse_version(value):
    if value.startswith("\""):
        return value[1:].split("\"")[0]
    if value.startswith("{"):
        # drop [...] arrays so that e.g. a feature string containing "version" cannot
        # be mistaken for the version key, then locate the version entry by key
        for part in _strip_arrays(value.strip("{}")).split(","):
            key, _, rawValue = part.partition("=")
            if key.strip() == "version":
                rawValue = rawValue.strip()
                if rawValue.startswith("\""):
                    return rawValue[1:].split("\"")[0]
        return None
    return None

def _strip_arrays(value):
    result = ""
    depth = 0
    for char in value.elems():
        if char == "[":
            depth += 1
        elif char == "]":
            depth -= 1
        elif depth == 0:
            result += char
    return result

def _crate_versions_repository_impl(repository_ctx):
    manifest = repository_ctx.read(repository_ctx.attr.manifest)
    versions = {}
    section = ""
    for line in manifest.splitlines():
        stripped = line.strip()
        if stripped.startswith("["):
            section = stripped
            continue
        if section not in ["[dependencies]", "[dev-dependencies]", "[build-dependencies]"]:
            continue
        if stripped.startswith("#") or "=" not in stripped:
            continue
        name = stripped.split("=", 1)[0].strip().strip("\"")
        version = _parse_version(stripped.split("=", 1)[1].strip())
        if version:
            versions[name] = version
    repository_ctx.file("BUILD", "")
    repository_ctx.file("versions.bzl", "CRATE_VERSIONS = {}\n".format(str(versions)))

crate_versions_repository = repository_rule(
    implementation = _crate_versions_repository_impl,
    attrs = {
        "manifest": attr.label(allow_single_file = True, mandatory = True),
    },
)

def _crate_versions_extension_impl(_module_ctx):
    crate_versions_repository(
        name = "crate_versions",
        manifest = Label("//library/crates:Cargo.toml"),
    )

crate_versions_extension = module_extension(implementation = _crate_versions_extension_impl)
