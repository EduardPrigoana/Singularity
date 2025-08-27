{
  description = "Flutter";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };

      androidComposition = pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = ["35.0.0" "34.0.0" "33.0.1"];
        platformVersions = ["35" "34" "33" "31"];
        abiVersions = [];
        includeNDK = true;
        ndkVersions = [ "27.2.12479018" "26.3.11579264" "25.1.8937393"];
        cmakeVersions = ["3.22.1"];
        includeSystemImages = false;
        includeEmulator = false;
        useGoogleAPIs = false;
        extraLicenses = [
          "android-googletv-license"
          "android-sdk-arm-dbt-license"
          "android-sdk-license"
          "android-sdk-preview-license"
          "google-gdk-license"
          "intel-android-extra-license"
          "intel-android-sysimage-license"
          "mips-android-sysimage-license"
        ];
      };

      androidSdk = androidComposition.androidsdk;


    in {
  devShell = with pkgs;
    mkShell rec {
      ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
      ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
      JAVA_HOME = jdk17.home;
      FLUTTER_ROOT = "${flutter}";
      DART_ROOT = "${flutter}/bin/cache/dart-sdk";
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
      QT_QPA_PLATFORM = "wayland;xcb";

      buildInputs = [
        flutter
        androidSdk
        gradle
        jdk17
        gtk3
        pkg-config
        xdg-user-dirs
        mpv-unwrapped.dev
        mpv-unwrapped

        # rustc
        # cargo
        # rustfmt
        # rust-analyzer
        # clippy
        rustup
        openssl
        # cbindgen                   # generates C headers from Rust
        # llvmPackages.libclang      # libclang used by dart:ffigen
      ];

      LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [vulkan-loader libGL]}";

      # Globally installed dart packages live in $PUB_CACHE/bin or ~/.pub-cache/bin
      shellHook = ''
        # make cargo-installed binaries available in the shell
        export PATH="$HOME/.cargo/bin:$PATH"

        if [ -z "$PUB_CACHE" ]; then
          export PATH="$PATH:$HOME/.pub-cache/bin"
        else
          export PATH="$PATH:$PUB_CACHE/bin"
        fi

        # Helpful LD_LIBRARY_PATH for desktop builds so Dart can find the Rust .so files
        # (adjust the paths to match your build output layout if different)
        export LD_LIBRARY_PATH="$(pwd)/build/linux/x64/debug/bundle/lib:$(pwd)/build/linux/x64/release/bundle/lib:$LD_LIBRARY_PATH"
      '';
    };
    });
}
