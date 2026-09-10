# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


_TARGET_TYPES = {
    "rust_library": "lib",
    "rust_shared_library": "lib",
    "rust_static_library": "lib",
    "rust_binary": "bin",
    "rust_proc_macro": "lib",
    "rust_test": "test",
    "_build_script_run": "build"
}

_CRATE_TYPES = {
    "rust_library": "lib",
    "rust_shared_library": "cdylib",
    "rust_static_library": "staticlib",
    "rust_binary": "bin",
    "rust_proc_macro": "proc-macro",
    "rust_test": "test",
    "_build_script_run": "N/A"
}

_DEFAULT_RUST_EDITION = "2024"

_BIN_ENTRY_POINT = "main.rs"
_LIB_ENTRY_POINT = "lib.rs"

CrateInfo = provider(fields = [
    "kind",                   # str
    "crate_name",             # str
    "workspace_name",         # str
    "crate_path",             # str
    "version",                # str
    "enabled_features",       # List[str]
    "features",               # List[str]
    "deps",                   # List[target]
    "transitive_deps",        # List[target]
    "build_deps",             # List[target]
    "cargo_entry_point",      # str | None
    "cargo_build_script",     # str | None
    "cargo_build_deps",       # List[str]: "name@version[+feature...]"
])

CargoProjectInfo = provider(fields = [
    "manifest",         # File
    "sources",          # Map[relpath:str, File]
    "workspace_files",  # List[File]
])

def _rust_cargo_project_aspect_impl(target, ctx):
    if ctx.rule.kind not in _TARGET_TYPES.keys():
        # not a crate
        return []

    crate_info = _crate_info(ctx, target)
    sources = [f for src in getattr(ctx.rule.attr, "srcs", []) + getattr(ctx.rule.attr, "compile_data", []) for f in src.files.to_list()]
    properties_file = _build_cargo_properties_file(target, ctx, sources, crate_info)

    if _should_generate_cargo_project(ctx, target):
        cargo_project_info = _generate_cargo_project(ctx, target, crate_info, properties_file, sources)
        return [
            crate_info,
            cargo_project_info,
            OutputGroupInfo(
                rust_cargo_properties = depset([properties_file]),
                rust_cargo_project = depset(cargo_project_info.workspace_files),
            ),
        ]
    else:
        return [
            crate_info,
            OutputGroupInfo(rust_cargo_properties = depset([properties_file])),
        ]

rust_cargo_project_aspect = aspect(
    attr_aspects = ["deps", "proc_macro_deps", "crate"],
    implementation = _rust_cargo_project_aspect_impl,
    attrs = {
        "_manifest_writer" : attr.label(
            default = Label("@typedb_dependencies//builder/rust/cargo:manifest-writer"),
            executable = True,
            cfg = "exec",
        )
    }
)

# TODO: Consider merging with `rust_cargo_project_aspect`
# (isolate from `if _should_generate_cargo_project(ctx, target)`)
def _rust_cargo_properties_aspect_impl(target, ctx):
    if ctx.rule.kind not in _TARGET_TYPES.keys():
        # not a crate
        return []

    crate_info = _crate_info(ctx, target)
    sources = [f for src in getattr(ctx.rule.attr, "srcs", []) + getattr(ctx.rule.attr, "compile_data", []) for f in src.files.to_list()]
    properties_file = _build_cargo_properties_file(target, ctx, sources, crate_info)

    return [
        crate_info,
        OutputGroupInfo(rust_cargo_properties = depset([properties_file])),
    ]

rust_cargo_properties_aspect = aspect(
    attr_aspects = ["deps", "proc_macro_deps", "crate"],
    implementation = _rust_cargo_properties_aspect_impl,
    attrs = {
        "_manifest_writer" : attr.label(
            default = Label("@typedb_dependencies//builder/rust/cargo:manifest-writer"),
            executable = True,
            cfg = "exec",
        )
    }
)

def _tag_value(tag, target):
    parts = tag.split("=", 1)
    if len(parts) != 2 or not parts[1]:
        fail("malformed tag '{}' on target '{}': expected <name>=<value>".format(tag, target.label))
    return parts[1]

def _crate_info(ctx, target):
    features = []
    cargo_entry_point = None
    cargo_build_script = None
    cargo_build_deps = []
    if _is_universe_crate(target):
        crate_name = target.label.name
        for tag in ctx.rule.attr.tags:
            if tag.startswith("crate-name"):
                crate_name = _tag_value(tag, target)
    else:
        crate_name = ctx.rule.attr.name
        for tag in ctx.rule.attr.tags:
            if tag.startswith("crate-name"):
                crate_name = _tag_value(tag, target)
            elif tag.startswith("declared-features"):
                features = [f.strip() for f in _tag_value(tag, target).split(",") if f.strip()]
            elif tag.startswith("cargo-entry-point"):
                cargo_entry_point = _tag_value(tag, target)
            elif tag.startswith("cargo-build-script"):
                cargo_build_script = _tag_value(tag, target)
            elif tag.startswith("cargo-build-dep"):
                cargo_build_deps.append(_tag_value(tag, target))
            elif tag.startswith("cargo-"):
                fail("unrecognized cargo sync tag '{}' on target '{}'".format(tag, target.label))

    workspace_name = target.label.workspace_name
    crate_path = target.label.package
    deps = _crate_deps(ctx, target)
    transitive_deps = _transitive_crate_deps(deps)

    return CrateInfo(
        kind = ctx.rule.kind,
        crate_name = crate_name,
        workspace_name = workspace_name,
        crate_path = crate_path,
        version = getattr(ctx.rule.attr, "version", "0.0.0"),
        enabled_features = getattr(ctx.rule.attr, "crate_features", []),
        features = features,
        deps = deps,
        transitive_deps = transitive_deps,
        build_deps = _crate_build_deps(ctx, target),
        cargo_entry_point = cargo_entry_point,
        cargo_build_script = cargo_build_script,
        cargo_build_deps = cargo_build_deps,
    )

def _generate_cargo_project(ctx, target, crate_info, properties_file, sources):
    workspace_root = target.label.name + "-cargo-workspace"

    manifest_file = ctx.actions.declare_file(workspace_root + "/" + crate_info.crate_name + "/Cargo.toml")
    build_deps = []
    args = ["--properties", properties_file.path, "--output", manifest_file.path] + [f.path for f in build_deps]
    ctx.actions.run(
        inputs = build_deps + [properties_file],
        outputs = [manifest_file],
        executable = ctx.executable._manifest_writer,
        arguments = args,
    )

    project_sources = {}

    for src in sources:
        src_path = _src_relpath(target, ctx, src)
        dst = ctx.actions.declare_file(workspace_root + "/" + crate_info.crate_name + "/" + src_path)
        _copy_to_bin(ctx, src, dst)
        project_sources[src_path] = dst

    workspace_files = [manifest_file] + list(project_sources.values())

    for dep in crate_info.transitive_deps + crate_info.build_deps:
        if CargoProjectInfo in dep:
            dep_info = dep[CrateInfo]
            project_info = dep[CargoProjectInfo]
            dep_manifest = ctx.actions.declare_file(workspace_root + "/" + dep_info.crate_name + "/" + project_info.manifest.basename)
            workspace_files.append(dep_manifest)
            _copy_to_bin(ctx, project_info.manifest, dep_manifest)
            for path, file in project_info.sources.items():
                dst = ctx.actions.declare_file(workspace_root + "/" + dep_info.crate_name + "/" + path)
                _copy_to_bin(ctx, file, dst)
                workspace_files.append(dst)

    return CargoProjectInfo(
        manifest = manifest_file,
        sources = project_sources,
        workspace_files = workspace_files,
    )

def _transitive_crate_deps(deps):
    transitive_deps = deps[:]
    for dep in deps:
        if CrateInfo in dep:
            for tdep in dep[CrateInfo].transitive_deps:
                if tdep not in transitive_deps:
                    transitive_deps.append(tdep)
    return transitive_deps

def _crate_deps(ctx, target):
    return [dep for dep in _all_deps(ctx) if _TARGET_TYPES[dep[CrateInfo].kind] in ["bin", "lib"]]

def _crate_build_deps(ctx, target):
    return [dep for dep in _deps(ctx) if _TARGET_TYPES[dep[CrateInfo].kind] == "build"]

def _deps(ctx):
    return [dep for dep in getattr(ctx.rule.attr, "deps", []) if CrateInfo in dep]

def _all_deps(ctx):
    return [
        dep for dep in
        _deps(ctx) + getattr(ctx.rule.attr, "proc_macro_deps", []) + ([ctx.rule.attr.crate] if hasattr(ctx.rule.attr, "crate") and ctx.rule.attr.crate else [])
        if CrateInfo in dep
    ]

def _copy_to_bin(ctx, src, dst):
    ctx.actions.run_shell(
        inputs = [src],
        outputs = [dst],
        command = "cp -f '{}' '{}'".format(src.path, dst.path),
    )

def _should_generate_cargo_project(ctx, target):
    label_str = str(target.label)
    if _is_universe_crate(target):
        return False
    is_local_or_typedb = (label_str.startswith("@typedb") or label_str.startswith("//")
        or label_str.startswith("@//") or label_str.startswith("@@//") or label_str.startswith("@@typedb"))
    return is_local_or_typedb and \
        ctx.rule.kind in _TARGET_TYPES and _TARGET_TYPES[ctx.rule.kind] in ["bin", "lib", "test"]

def _is_universe_crate(target):
    label_str = str(target.label)
    return (label_str.startswith("@crates__") or
            "crate+crates__" in label_str or
            label_str.startswith("@@crates//") or label_str.startswith("@crates//"))

def _build_cargo_properties_file(target, ctx, source_files, crate_info):
    properties_file = ctx.actions.declare_file("{}.cargo.properties".format(ctx.rule.attr.name))
    properties = _get_properties(target, ctx, source_files, crate_info)

    content = ""
    for prop in properties.items():
        content = content + ("{}: {}\n".format(prop[0], prop[1]))
    ctx.actions.write(
        output = properties_file,
        content = content
    )
    return properties_file

def _get_properties(target, ctx, source_files, crate_info):
    target_type = "build" if _looks_like_cargo_build_script(target) else _TARGET_TYPES[ctx.rule.kind]

    properties = {}
    properties["name"] = crate_info.crate_name
    properties["path"] = crate_info.crate_path
    properties["enabled.features"] = ",".join(crate_info.enabled_features)
    properties["features"] = ",".join(crate_info.features)
    properties["target.name"] = target.label.name
    properties["crate_type"] = _CRATE_TYPES[ctx.rule.kind]
    properties["type"] = target_type
    properties["version"] = crate_info.version
    if target_type in ["bin", "lib"]:
        properties["edition"] = ctx.rule.attr.edition or _DEFAULT_RUST_EDITION
        if crate_info.cargo_entry_point != None:
            properties["entry.point.path"] = crate_info.cargo_entry_point
        else:
            entry_point_file = _entry_point_file(target, ctx, source_files)
            properties["entry.point.path"] = _src_relpath(target, ctx, entry_point_file)
        if crate_info.cargo_build_script != None:
            properties["build.script"] = crate_info.cargo_build_script
            for build_dep in crate_info.cargo_build_deps:
                properties["build.dep." + _build_dep_name(build_dep)] = _build_dep_location(build_dep)
        elif len(crate_info.cargo_build_deps) > 0:
            fail("cargo-build-dep tags declared without a cargo-build-script tag on target '{}'".format(target.label))
        if len(_crate_build_deps_info(crate_info)) > 0:
            fail("Build deps support unimplemented")
    if target_type == "test" and ctx.rule.attr.crate == None:
       entry_point_file = _entry_point_file(target, ctx, source_files)
       properties["entry.point.path"] = _src_relpath(target, ctx, entry_point_file)
    for dep in _crate_deps_info(target, crate_info).items():
        properties["deps." + dep[0]] = dep[1]
    return properties

def _crate_deps_info(target, crate_info):
    deps_info = {}

    for dependency in crate_info.deps:
        dependency_info = dependency[CrateInfo]
        if _is_universe_crate(dependency):
            location = "version={}".format(dependency_info.version)
        elif not _is_external_target(target) and _is_external_target(dependency):
            location = "path=../{};workspace_name={}".format(dependency_info.crate_name, dependency_info.workspace_name)
        else:
            root_to_dep = _package_path_from_root(dependency.label)
            location = "path=../{};repopath={}".format(dependency_info.crate_name, root_to_dep)

        enabled_features = ",".join(dependency_info.enabled_features)
        info = location + (";enabled.features={}".format(enabled_features) if enabled_features else "")
        deps_info[dependency_info.crate_name] = info
    return deps_info

def _is_external_target(target):
    return target.label.workspace_root.startswith("external/")

def _package_relative_path_to_root(label):
    package_path = label.package.strip()
    if len(package_path) == 0:
        return "."
    else:
        dirs_to_root = package_path.count("/") + 1
        return "/".join([".."] * dirs_to_root)

def _package_path_from_root(label):
    return label.package

def _crate_build_deps_info(crate_info):
    return [build_dep[CrateInfo].crate_name for build_dep in crate_info.build_deps]

def _build_dep_name(build_dep):
    return _build_dep_parts(build_dep)[0]

def _build_dep_location(build_dep):
    version_and_features = _build_dep_parts(build_dep)[1].split("+")
    location = "version={}".format(version_and_features[0])
    if len(version_and_features) > 1:
        location += ";enabled.features={}".format(",".join(version_and_features[1:]))
    return location

def _build_dep_parts(build_dep):
    parts = build_dep.split("@")
    if len(parts) != 2 or not parts[0] or not parts[1].split("+")[0]:
        fail("cargo-build-dep tag value '{}' must be of the form 'name@version[+feature...]'".format(build_dep))
    return parts

def _looks_like_cargo_build_script(target):
    return str(target.label).endswith("_")

def _entry_point_file(target, ctx, source_files):
    if getattr(ctx.rule.attr, "crate_root", None):
        return ctx.rule.file.crate_root
    else:
        return _find_entry_point_in_sources(target, ctx, source_files)

def _find_entry_point_in_sources(target, ctx, source_files):
    if len(source_files) == 1:
        return source_files[0]

    standard_entry_point_name = _BIN_ENTRY_POINT if ctx.rule.kind == "rust_binary" else _LIB_ENTRY_POINT
    alternative_entry_point_name = "{}.rs".format(ctx.rule.attr.name)

    standard_entry_points = [f for f in source_files if f.basename == standard_entry_point_name]
    if len(standard_entry_points) == 1:
        return standard_entry_points[0]
    elif len(standard_entry_points) > 1:
        fail("cannot determine entry point for {} target '{}': multiple files named '{}' found in srcs, and no explicit crate_root".format(
            ctx.rule.kind, target.label.name, standard_entry_point_name
        ))

    alternative_entry_points = [f for f in source_files if f.basename == alternative_entry_point_name]
    if len(alternative_entry_points) == 1:
        return alternative_entry_points[0]
    elif len(alternative_entry_points) > 1:
        fail("cannot determine entry point for {} target '{}': multiple files named '{}' found in srcs, and no explicit crate_root".format(
            ctx.rule.kind, target.label.name, alternative_entry_point_name
        ))

    fail("cannot determine entry point for {} target '{}': no files named '{}' or '{}' found in srcs, and no explicit crate_root".format(
        ctx.rule.kind, target.label.name, standard_entry_point_name, alternative_entry_point_name
    ))

def _src_relpath(target, ctx, src):
    path = src.path

    if "external" in path:
        path = path[path.find("external"):].split("/", 2)[2]

    if "bazel-out" in path:
        path = path[path.find("bazel-out"):].split("/", 3)[3]

    if "/" in ctx.build_file_path:
        build_file_directory = ctx.build_file_path.rsplit("/", 1)[0] + "/"
        if not path.startswith(build_file_directory):
            fail("source file {} of the target '{}' is not located under the target path ({})".format(
                src.path, target.label.name, build_file_directory
            ))

        return path[len(build_file_directory):]
    else: # BUILD in root
        return path
