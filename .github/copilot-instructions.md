# Copilot Instructions for rclone-fuse3-magisk

## Repository Overview

This repository builds a Magisk module that integrates Rclone with FUSE 3.17.x support into Android. The module enables automatic mounting of remote storage as local directories during system boot and runtime.

## Technology Stack

- **Primary Languages**: Shell/Bash scripting
- **Build System**: Meson + Ninja (for libfuse3)
- **Target Platform**: Android (Magisk module)
- **Dependencies**:
  - Rclone (downloaded from official releases)
  - FUSE 3.17.x (libfuse, built from source with patches)
  - Android NDK (r27c or compatible)
  - Python (for meson)

## Repository Structure

```
.
├── .github/
│   └── workflows/          # CI/CD workflows
├── build.sh                # Main build script for creating Magisk module
├── patch.sh                # Applies patches to libfuse
├── scripts/
│   ├── build-libfuse3.sh   # Cross-compiles libfuse3 for Android
│   └── download-rclone.sh  # Downloads appropriate rclone binary
├── patch-libfuse3/         # Patches for libfuse3 compatibility
├── magisk-rclone/          # Magisk module template
│   ├── module.prop         # Module metadata (version, description)
│   ├── service.sh          # Boot-time mounting service
│   ├── sync.service.sh     # Background sync service
│   ├── env                 # Environment variable configuration
│   └── system/vendor/bin/  # User-facing rclone wrapper scripts
└── libfuse/                # Git submodule for FUSE library
```

## Build Process

### Supported Architectures
- `arm64-v8a` (aarch64)
- `x86_64`

### Build Steps

1. **Patch libfuse**: Run `./patch.sh` to apply Android compatibility patches
2. **Build for architecture**: Run `./build.sh <ABI> [TAG_NAME]`
   - Downloads rclone binary for the specified architecture
   - Cross-compiles libfuse3 using Android NDK
   - Creates Magisk module ZIP package
   - Generates `update-<ABI>.json` for OTA updates

### Build Environment Requirements
- Android NDK r27c (set via `ANDROID_NDK_HOME`)
- Python with meson and ninja installed
- Go (for potential rclone building, though binaries are downloaded)
- Standard Unix tools: wget, curl, zip, patch

## Key Files and Their Purpose

### Version Management
- `magisk-rclone/module.prop`: Contains `version` (e.g., v1.72.0) and `versionCode` (numeric)
- Version updates should increment both values

### Scripts in Module (`magisk-rclone/system/vendor/bin/`)
- `rclone-config`: Opens rclone configuration interface
- `rclone-web`: Starts rclone web GUI
- `rclone-mount`: Mounts a remote storage location
- `rclone-sync`: Executes sync jobs from configuration
- `rclone-kill-all`: Unmounts all and kills rclone processes

### Configuration Files (Runtime, in `/data/adb/modules/rclone/conf/`)
- `rclone.conf`: Main rclone configuration
- `env`: Custom environment variables and flags
- `htpasswd`: Web GUI credentials
- `sync`: Sync job definitions

## CI/CD Workflows

### build-android.yml
- Triggers on: Push to main, tags, and PRs
- Builds both architectures (arm64-v8a, x86_64)
- Uploads artifacts
- On tags: Creates GitHub release with ZIP files and update.json

### check-rclone-update.yml
- Runs daily at 10:00 UTC
- Checks for new rclone releases via GitHub API
- Automatically creates PR with version updates if newer version found
- Updates both `version` and increments `versionCode` in module.prop

## Coding Conventions

### Shell Scripts
- Use `set -e` for error handling
- Use proper quoting for variables (e.g., `"$VARIABLE"`)
- Chinese comments are acceptable (project has bilingual documentation)
- Logging in module scripts: Use `log -t Magisk "[rclone] message"`

### Build Scripts
- Validate architecture parameters before proceeding
- Use descriptive error messages in both English and Chinese when appropriate
- Clean up temporary files after build

### Version Updates
- When updating rclone version:
  - Update `version=` field in `magisk-rclone/module.prop`
  - Increment `versionCode=` field (must be monotonically increasing integer)
  - Test that download URL works for all architectures

## Testing Guidelines

### Manual Testing Requirements
- After version updates, verify:
  - Build completes successfully for all architectures
  - Generated ZIP files are valid Magisk modules
  - `update-<ABI>.json` files are well-formed JSON
  - Rclone binary downloads succeed from beta.rclone.org

### Module Testing (Manual, requires Android device)
- Install module via Magisk Manager
- Verify boot-time mounting works
- Test wrapper scripts (rclone-config, rclone-web, etc.)
- Check log output via `logcat -s Magisk:*`

## Important Notes

1. **Submodule Management**: The `libfuse` directory is a git submodule. Always initialize with `git submodule update --init`

2. **Architecture Mapping**: 
   - Magisk uses: `arm64-v8a`, `x86_64`
   - Rclone URLs use: `armv8a`, `x64`
   - NDK uses: `aarch64-linux-android`, `x86_64-linux-android`
   - Ensure mappings are consistent in scripts

3. **NDK Cross-Compilation**: The build uses meson cross-files for Android. API level 28 (Android 9) is the default target.

4. **FUSE Patches**: Do not modify libfuse directly. All changes should be patch files in `patch-libfuse3/`

5. **Automated PRs**: The update checker workflow creates PRs automatically. Review these carefully before merging.

6. **Binary Downloads**: Rclone binaries come from `beta.rclone.org` testbuilds, not official releases. This provides Android-21 compatible binaries.

## Common Tasks

### Adding a New Architecture
1. Add mapping to `platforms` array in `scripts/build-libfuse3.sh`
2. Add case in `scripts/download-rclone.sh`
3. Update workflow to build new architecture
4. Test end-to-end build

### Updating Documentation
- `README.md` is bilingual (English/Chinese)
- Maintain consistency between language sections
- Update both languages when making changes

### Fixing Build Issues
- Check NDK environment variables are set correctly
- Verify meson/ninja versions are compatible
- Review patch application in `patch.sh`
- Ensure all submodules are initialized

## External Resources

- [Rclone Documentation](https://rclone.org/)
- [FUSE for Android](https://github.com/libfuse/libfuse)
- [Magisk Module Documentation](https://topjohnwu.github.io/Magisk/)
- [Android NDK Documentation](https://developer.android.com/ndk)

## Security Considerations

- Do not commit secrets or credentials
- Be cautious with automated PR merges from update checker
- Validate download URLs before using (prevent supply chain attacks)
- Test new rclone versions for security vulnerabilities before release
