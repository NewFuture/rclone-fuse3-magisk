# Rclone FUSE3 Magisk Module

This project builds Android Magisk modules that integrate Rclone with FUSE 3.17.x support, enabling seamless mounting of remote storage on Android devices. The build system cross-compiles for multiple Android architectures and creates installable Magisk modules.

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Working Effectively

### Prerequisites and Setup
- Install build dependencies:
  ```bash
  pip install meson ninja
  ```
- Android NDK is required (automatically provided in GitHub Actions environment via `ANDROID_NDK_HOME`)
- Initialize git submodules:
  ```bash
  git submodule update --init --recursive
  ```
  - **Timing**: ~1 second for submodule initialization

### Build Process
- **CRITICAL**: Full build process requires internet access for downloading rclone binaries
- Patch libfuse submodule first:
  ```bash
  ./patch.sh
  ```
  - **Timing**: <1 second, applies Android-specific patches
  - **Note**: Re-running shows "Reversed patch detected" warnings but is harmless
- Build for specific Android architecture:
  ```bash
  ./build.sh arm64-v8a [TAG_NAME]
  ./build.sh x86_64 [TAG_NAME]
  ```
  - **NEVER CANCEL**: Build takes 25-45 minutes per architecture. ALWAYS set timeout to 60+ minutes
  - **Components built**: libfuse3 (~2-21 seconds), rclone download (~5 seconds if network available), module packaging
- Test individual components:
  ```bash
  # Test libfuse3 build only (works offline)
  ./scripts/build-libfuse3.sh arm64-v8a
  ```
  - **Timing**: ~2-21 seconds (faster on rebuild), NEVER CANCEL

### Validation and Testing
- **CRITICAL LIMITATION**: Rclone download requires internet access to `beta.rclone.org`
- In restricted environments, builds will fail at rclone download step
- **Manual validation scenarios**:
  - Verify submodule initialization: `git submodule status` should show no `-` prefix
  - Test patch application: `./patch.sh` should complete without errors
  - Validate libfuse3 cross-compilation for Android architectures
  - Check module structure after build completion

## Architecture and Supported Platforms
- **Supported Android ABIs**: arm64-v8a, armeabi-v7a, x86, x86_64
- **CI builds**: arm64-v8a and x86_64 (primary architectures)
- **Manual builds**: All architectures supported via `./build.sh <ABI>`
- **Minimum Android API**: 21 (Android 5.0)
- **FUSE version**: 3.17.x (libfuse submodule)
- **Rclone version**: Defined in `magisk-rclone/module.prop` (currently v1.70.3)

## Key Project Structure
```
.
├── README.md                 # Project documentation
├── build.sh                  # Main build script for Android modules
├── patch.sh                  # Applies Android patches to libfuse
├── scripts/
│   ├── build-libfuse3.sh    # Cross-compiles libfuse for Android
│   └── download-rclone.sh   # Downloads rclone Android binaries
├── magisk-rclone/           # Magisk module template
│   ├── module.prop          # Module metadata and version
│   ├── service.sh           # Boot service script
│   ├── action.sh            # Web GUI management
│   ├── customize.sh         # Installation customization
│   └── system/vendor/bin/   # Binary installation path
├── libfuse/                 # Git submodule (fuse-3.17.x branch)
├── patch-libfuse3/          # Android-specific patches for libfuse
└── .github/workflows/       # CI/CD automation
```

## Common Build Issues and Solutions
- **"abort: command not found"**: Missing function in download script - network connectivity required
- **"can't find file to patch"**: Run `git submodule update --init --recursive` first
- **"Reversed patch detected"**: Harmless warning when re-running `./patch.sh` on already patched code
- **Cross-compilation errors**: Ensure `ANDROID_NDK_HOME` environment variable is set
- **Network timeouts**: Builds require access to `beta.rclone.org` and `raw.githubusercontent.com`
- **"Could not resolve host: beta.rclone.org"**: Expected in restricted network environments - build will fail at rclone download step

## GitHub Actions Integration
- **Automated builds**: Triggered on push to main and tags
- **Build matrix**: Builds arm64-v8a and x86_64 architectures
- **Android NDK version**: r27c (automatically configured in CI)
- **Timing expectations**:
  - Full CI build: 10-15 minutes per architecture
  - Artifact upload: <1 minute
  - Release upload: <1 minute
- **Automated updates**: Daily check for new rclone versions (check-rclone-update.yml)
- **Network dependencies in CI**: Access to beta.rclone.org and raw.githubusercontent.com required

## Development Workflow
- **Before making changes**: Always run `git submodule update --init --recursive` and `./patch.sh`
- **Testing changes**: Test libfuse3 build first: `./scripts/build-libfuse3.sh arm64-v8a`
- **Cross-architecture validation**: Test on both arm64-v8a and x86_64 when possible
- **Module validation**: Check `magisk-rclone/module.prop` version consistency

## Magisk Module Components
- **Scripts provided**:
  - `rclone-config`: Opens rclone configuration interface
  - `rclone-web`: Starts rclone web GUI on port 5572
  - `rclone-sync`: Executes sync jobs from config file
  - `rclone-kill-all`: Unmounts and kills all rclone processes
- **Configuration paths**:
  - `/data/adb/modules/rclone/conf/rclone.conf`: Main rclone config
  - `/data/adb/modules/rclone/conf/env`: Environment variables
  - `/data/adb/modules/rclone/conf/sync`: Sync job definitions

## Network Dependencies
- **CRITICAL**: Build process requires internet access for:
  - Downloading rclone binaries from `beta.rclone.org`
  - Fetching Magisk module installer script from GitHub
- **Offline development**: Only libfuse3 compilation works offline
- **CI environment**: Network access is available in GitHub Actions

## Version Management
- **Rclone version**: Update `version=` in `magisk-rclone/module.prop`
- **Module version**: Update `versionCode=` in `magisk-rclone/module.prop`
- **Automated updates**: Daily workflow checks for new rclone releases and creates PRs

## Build Timing Reference
| Component | Duration | Timeout Recommendation |
|-----------|----------|------------------------|
| Submodule init | ~1s | 30s |
| Patch application | <1s | 30s |
| libfuse3 build (first) | ~21s | 60s |
| libfuse3 build (rebuild) | ~2s | 60s |
| Rclone download | ~5s | 120s |
| Module packaging | ~5s | 60s |
| **Full build** | **25-45min** | **60+ minutes** |

**NEVER CANCEL any build operations - they may take up to 45 minutes per architecture.**