# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("//tool/checkstyle:rules.bzl", "checkstyle_test")

exports_files(["ValidateDeps.kt", "ValidateNodeJsDeps.kt", "ValidatePythonDeps.kt"])

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    license_type = "mpl-header",
    size = "small",
)
