# Setup
- Check [flake.nix](flake.nix) for dependencies
- With **Nix**: run `nix develop`
  - Some additional setup may be required after this, especially for Rust integration
- Without `nix`: you’ll need to set up everything manually

## Rust Integration
- See https://github.com/fzyzcjy/flutter_rust_bridge
- Need `flutter_rust_bridge_codegen v2.7.0` (See `cargo.toml` in `./rust`)
  - Latest version doesn't work because `audiotags` (in `pubspec.yaml`) uses `frb 2.7.0`

## Other
- For vscode integraion - change `.vscode/settings.json` locally
- Building APKs is currently broken after upgrading to latest flutter, dart version
- I usually do development by running it in linux, not android emulator
