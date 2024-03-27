load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def deps():
    http_archive(
        name = "gtest",
        sha256 = "24564e3b712d3eb30ac9a85d92f7d720f60cc0173730ac166f27dda7fed76cb2",
        strip_prefix = "googletest-release-1.12.1",
        urls = ["https://github.com/google/googletest/archive/refs/tags/release-1.12.1.zip"],
    )

    http_archive(
        name = "gherkin_cpp",
        urls = ["https://github.com/cucumber/gherkin/archive/refs/tags/v28.0.0.zip"],
        strip_prefix = "gherkin-28.0.0/cpp",
        sha256 = "30eba0790c3aafeea5be25e5e4bf1e0628bc9546539227c0a793987f87eca6a1",
        build_file_content = """
cc_library(
  name = "gherkin-lib",
  deps = ["@nlohmann_json//:json", "@cucumber_messages//:cucumber-messages-lib"],
  hdrs = glob(["include/**/*.hpp"]),
  strip_include_prefix = "include/gherkin",
  srcs = glob(["src/lib/gherkin/**/*.cpp"]),
  copts = ["--std=c++17"],
  visibility= ["//visibility:public"],
)
        """
    )

    http_archive(
        name = "cucumber_messages",
        urls = ["https://github.com/cucumber/messages/archive/refs/tags/v24.1.0.zip"],
        strip_prefix = "messages-24.1.0/cpp",
        sha256 = "90922751ec690b2a561303d2e5a0d330dfb7a8c82b36a672820b8dca1be12452",
        build_file_content = """
cc_library(
  name = "cucumber-messages-lib",
  deps = ["@nlohmann_json//:json"],
  hdrs = glob(["include/**/*.hpp"]),
  strip_include_prefix = "include/messages",
  srcs = glob(["src/lib/cucumber-messages/**/*.cpp", "src/lib/cucumber-messages/**/*.hpp"]),
  copts = [
    "--std=c++17",
     "-isystem external/cucumber_messages/src/lib/cucumber-messages",
  ],
  visibility= ["@gherkin_cpp//:__pkg__", "//cpp/test:__subpackages__"],
)
    """
    )

    http_archive(
        name = "nlohmann_json",
        urls = ["https://github.com/nlohmann/json/archive/refs/tags/v3.11.2.zip"],
        strip_prefix = "json-3.11.2",
        sha256 = "95651d7d1fcf2e5c3163c3d37df6d6b3e9e5027299e6bd050d157322ceda9ac9",
        build_file_content = """
cc_library(
  name = "json",
  hdrs = ["single_include/nlohmann/json.hpp"],
  srcs = [],
  includes = ["single_include"],
  copts = ["--std=c++17"],
  visibility= ["//visibility:public"],
)
    """
    )
