#
# Copyright (C) 2022 Vaticle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

def deps():
    http_archive(
        name = "rules_rust",
        sha256 = "aaaa4b9591a5dad8d8907ae2dbe6e0eb49e6314946ce4c7149241648e56a1277",
        urls = ["https://github.com/bazelbuild/rules_rust/releases/download/0.16.1/rules_rust-v0.16.1.tar.gz"],
    )
    http_file(
        name = "cxxbridge_linux",
        urls = [
            "https://repo.vaticle.com/repository/meta/cxxbridge-v1.0.55-linux"
        ],
        executable = True,
    )
    http_file(
        name = "cxxbridge_mac",
        urls = [
            "https://repo.vaticle.com/repository/meta/cxxbridge-v1.0.55-mac"
        ],
        executable = True,
    )
    http_file(
        name = "cxxbridge_windows",
        urls = [
            "https://repo.vaticle.com/repository/meta/cxxbridge-v1.0.55-windows.exe",
        ],
        executable = True,
    )
