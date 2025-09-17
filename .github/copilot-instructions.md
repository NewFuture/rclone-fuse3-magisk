# Rclone FUSE3 Magisk Module

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

This is a Magisk module that integrates Rclone with FUSE 3.17.x support into Android, enabling seamless remote storage mounting and automated management. The project builds native Android binaries for multiple architectures and creates installable Magisk module ZIP files.

## Working Effectively

### Bootstrap and Build Process
Always execute these steps in order to set up the development environment:

1. **Initialize submodules and apply patches**:
   ```bash
   git submodule update --init --recursive
   ./patch.sh
   ```
   - Submodule init takes 10-30 seconds normally, 2-3 minutes on slow connections. NEVER CANCEL.
   - Patch application takes under 1 second
   - If patches fail, ensure submodules are initialized first

2. **Install build dependencies**:
   ```bash
   pip install meson ninja
   ```
   - Takes 30-60 seconds normally
   - Go is usually pre-installed, verify with: `which go`
   - Android NDK should be available at `$ANDROID_NDK_HOME` (usually `/usr/local/lib/android/sdk/ndk/27.3.13750724`)

3. **Build libfuse3 for specific architecture**:
   ```bash
   ./scripts/build-libfuse3.sh arm64-v8a
   ```
   - Takes 2-15 seconds normally. NEVER CANCEL.
   - Set timeout to 120+ seconds for build commands
   - Supports: arm64-v8a, armeabi-v7a, x86, x86_64
   - Creates `libfuse/build/util/fusermount3` and other utilities

4. **Download rclone binary (requires internet)**:
   ```bash
   ./scripts/download-rclone.sh arm64-v8a v1.70.3 destination/path
   ```
   - Takes 30-120 seconds depending on connection. NEVER CANCEL.
   - May fail in restricted network environments - document as "fails due to firewall limitations"

5. **Full build process for single architecture**:
   ```bash
   ./build.sh arm64-v8a test-tag
   ```
   - Takes 2-5 minutes total. NEVER CANCEL. Set timeout to 600+ seconds.
   - Creates `magisk-rclone_arm64-v8a.zip` and `update-arm64-v8a.json`

### Testing and Validation
- **No unit tests exist** - validation is done through build verification
- **Always validate build artifacts** by checking that ZIP files are created: `ls -la *.zip *.json`
- **Check libfuse3 build artifacts**: `ls -la libfuse/build/util/fusermount3`
- **Cannot run the Android module** in a Linux environment - this is a Magisk module designed for Android
- **Build validation**: Ensure both ZIP and JSON files are generated correctly after running `./build.sh`
- **Manual verification**: Extract and inspect ZIP contents to verify all required files are present
- **Script validation**: Examine wrapper scripts in `magisk-rclone/system/vendor/bin/` for proper syntax

### GitHub CI Workflow
The `.github/workflows/build-android.yml` workflow:
- Runs on Ubuntu Latest with Android NDK r27c
- Builds for arm64-v8a and x86_64 architectures
- Takes 10-15 minutes total. NEVER CANCEL CI builds.
- Uploads artifacts and creates releases for tagged commits
- Set timeout to 30+ minutes for CI workflow completion

## Architecture and Key Components

### Build Scripts
- `build.sh` - Main build script, takes ABI and tag parameters
- `scripts/build-libfuse3.sh` - Builds libfuse3 for Android using meson/ninja
- `scripts/download-rclone.sh` - Downloads rclone binary from beta.rclone.org
- `patch.sh` - Applies necessary patches to libfuse submodule

### Magisk Module Structure (`magisk-rclone/`)
- `module.prop` - Module metadata (version v1.70.3, versionCode 22)
- `service.sh` - Boot service script for automatic mounting
- `action.sh` - Web GUI management script
- `sync.service.sh` - Background sync service 
- `customize.sh` - Installation customization
- `env` - Default environment variables and configuration
- `system/vendor/bin/` - Rclone wrapper scripts

### Available Commands
The module provides these wrapper scripts:
- `rclone-config` - Opens rclone configuration interface
- `rclone-web` - Starts rclone Web GUI with predefined options
- `rclone-mount <name>` - Mounts remote storage to `/sdcard/<name>`
- `rclone-sync` - Runs rclone sync with provided arguments
- `rclone-kill-all` - Unmounts all rclone mounts and kills processes

### Configuration Files
Module configuration is stored in `/data/adb/modules/rclone/conf/`:
- `rclone.conf` - Main rclone configuration
- `env` - Custom environment variables and flags
- `htpasswd` - Web GUI authentication
- `sync` - Automatic sync job definitions
- `copy` - Copy job definitions

## Build Requirements and Dependencies

### System Dependencies
- **Android NDK r27c** - Required for cross-compilation
- **Python 3 with pip** - For meson and ninja installation  
- **Git with submodules** - For libfuse source code
- **Curl** - For downloading rclone binaries
- **Go** - Usually pre-installed in CI environments

### Build Timing Expectations
- **NEVER CANCEL**: Full build process takes 2-5 minutes per architecture
- **NEVER CANCEL**: CI build takes 10-15 minutes for all architectures  
- **NEVER CANCEL**: libfuse3 compilation takes 10-15 seconds
- **NEVER CANCEL**: Submodule initialization can take 2-3 minutes
- **NEVER CANCEL**: Rclone download takes 30-120 seconds

### Network Requirements
- **Internet access required** for downloading rclone binaries from beta.rclone.org
- **Submodule access** to github.com/libfuse/libfuse.git
- May fail in restricted environments - document network limitations

## Development Workflow

### Making Changes
1. **Always start with submodule initialization**: `git submodule update --init --recursive`
2. **Apply patches**: `./patch.sh`
3. **Install dependencies**: `pip install meson ninja`
4. **Test build for one architecture first**: `./build.sh arm64-v8a test`
5. **Validate ZIP file creation and contents**
6. **Test additional architectures if needed**

### Validation Steps
- **Build validation**: Verify ZIP and JSON files are created
- **Content validation**: Extract ZIP and check file structure
- **Cannot run functional tests** - this is an Android-only module
- **CI validation**: Ensure GitHub workflow completes successfully

### Common Issues and Workarounds
- **Patch application fails**: Ensure submodules are initialized first
- **Network download fails**: Document as limitation in restricted environments  
- **Build fails**: Check Android NDK path and version (r27c required)
- **Missing dependencies**: Run pip install for meson/ninja

## Repository Structure Reference

### Root Directory
```
.github/workflows/          # CI/CD workflows  
.gitmodules                 # Submodule configuration
build.sh                    # Main build script
libfuse/                    # FUSE library submodule (after init)
magisk-rclone/              # Module source files
patch-libfuse3/             # Patches for libfuse
patch.sh                    # Patch application script
scripts/                    # Build helper scripts
```

### Key Files to Monitor
- `magisk-rclone/module.prop` - Version information
- `magisk-rclone/env` - Default configuration
- `.github/workflows/build-android.yml` - CI configuration
- `scripts/build-libfuse3.sh` - Core build logic
- `scripts/download-rclone.sh` - Binary download logic

## Important Notes

- **Android-specific**: This module only works on Android with Magisk
- **Cross-compilation only**: Cannot run the final product on Linux
- **Network dependent**: Requires internet for rclone binary downloads
- **Architecture support**: arm64-v8a, armeabi-v7a, x86, x86_64
- **No automated tests**: Validation is manual through build verification
- **Bilingual documentation**: README contains both English and Chinese text