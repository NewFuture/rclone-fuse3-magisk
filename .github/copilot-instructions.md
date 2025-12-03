# GitHub Copilot Instructions for rclone-fuse3-magisk

## Repository Overview

This repository contains a Magisk module that integrates rclone with FUSE3 support for Android. It enables mounting remote storage as local directories with automated boot-time mounting and management scripts.

**Key Components:**
- Magisk module structure in `magisk-rclone/`
- Build scripts for cross-compiling libfuse3 and packaging rclone
- Shell scripts for service management and automation
- CI/CD workflows for automated building and release management

## Code Style and Conventions

### Shell Scripts
- Use `#!/bin/bash` for build scripts and `#!/system/bin/sh` for on-device scripts
- Use `set -e` at the beginning of scripts to fail on errors
- Follow existing logging patterns: `L() { log -t Magisk "[rclone] $1"; }`
- Preserve Chinese comments where they exist (bilingual documentation)
- Use consistent indentation (2 spaces for shell scripts)

### File Organization
- Build scripts: `scripts/` directory
- Module files: `magisk-rclone/` directory
- Patches: `patch-libfuse3/` directory
- CI/CD: `.github/workflows/` directory

### Environment Variables
- Configuration files use `set -a && . "$MODPATH/env" && set +a` pattern for loading environment variables
- Key variables are defined in `magisk-rclone/env`

## Build System

### Build Process
1. **libfuse3 compilation**: Uses meson and ninja with Android NDK cross-compilation
2. **rclone download**: Downloads pre-built rclone binaries for target architecture
3. **Module packaging**: Creates Magisk-compatible ZIP files with proper structure

### Supported Architectures
- `arm64-v8a` (primary)
- `x86_64` (secondary)
- Infrastructure exists for `armeabi-v7a` and `x86` but not actively built

### Build Commands
```bash
./build.sh arm64-v8a [TAG_NAME]
./build.sh x86_64 [TAG_NAME]
```

### Dependencies
- Android NDK (r27c or compatible)
- Python packages: meson, ninja
- Go toolchain (for any Go-based modifications)
- Standard Linux build tools: wget, zip, sed, grep

## Testing and Validation

### Build Validation
- Always test builds for both `arm64-v8a` and `x86_64` architectures
- Verify ZIP file structure matches Magisk module requirements
- Check that `update-*.json` files are generated correctly

### Script Testing
- Test shell scripts for syntax errors: `bash -n script.sh`
- Verify environment variable expansion works correctly
- Ensure paths are absolute where required (especially on-device scripts)

### Module Testing
- Module structure must include:
  - `module.prop` with correct metadata
  - `service.sh` for boot-time operations
  - `customize.sh` for installation customization
  - `action.sh` for module actions
  - Binary files in `system/vendor/bin/`

## Key Files and Directories

### Critical Files
- `magisk-rclone/module.prop`: Module metadata, version information
- `magisk-rclone/service.sh`: Boot service that auto-mounts remotes
- `magisk-rclone/env`: Default environment variables and configuration
- `build.sh`: Main build orchestration script
- `.github/workflows/build-android.yml`: CI/CD pipeline

### Do Not Modify Without Care
- `libfuse/` (git submodule) - only patch via `patch-libfuse3/`
- `magisk-rclone/system/` structure - must match Magisk expectations
- Version number format in `module.prop` - follows rclone upstream versions

## Common Workflows

### Adding New Features
1. If adding on-device scripts, place them in appropriate locations within `magisk-rclone/`
2. Use existing logging patterns for consistency
3. Test on both arm64-v8a and x86_64 if possible
4. Update README.md with bilingual documentation

### Updating Dependencies
1. **rclone version**: Update `version=` in `magisk-rclone/module.prop`
2. **libfuse3**: Update submodule reference and patches if needed
3. **Build tools**: Update versions in workflow files

### Fixing Build Issues
1. Check NDK version compatibility in `.github/workflows/build-android.yml`
2. Verify cross-compilation settings in `scripts/build-libfuse3.sh`
3. Test meson configuration with `--verbose` flag if needed

## Security and Best Practices

### Security Considerations
- Never commit sensitive credentials or tokens
- Validate user inputs in scripts that process configuration files
- Be cautious with file permissions - use `chmod` explicitly
- Test path traversal vulnerabilities when handling user-provided paths

### Best Practices
- Minimal changes philosophy - only modify what's necessary
- Preserve backward compatibility when possible
- Test scripts with `set -x` for debugging
- Use quoted variables to prevent word splitting: `"$variable"`
- Prefer absolute paths in on-device scripts: `/vendor/bin/rclone` not `rclone`

## Documentation

### README Updates
- Maintain bilingual format (English/Chinese)
- Use existing formatting patterns (emoji, code blocks, sections)
- Update both language versions when making changes
- Include usage examples for new features

### Comments
- Preserve Chinese comments in shell scripts where they exist
- Add comments for complex logic or non-obvious behavior
- Use inline comments sparingly - prefer self-documenting code

## GitHub Actions

### Workflows
- **build-android.yml**: Builds module for release (triggered on tags and PRs)
- **check-rclone-update.yml**: Automated checking for rclone updates

### Release Process
1. Update version in `module.prop`
2. Create and push a git tag matching the version
3. CI automatically builds and uploads to GitHub releases
4. Update JSON files are generated for Magisk module updates

## Module Runtime Behavior

### Service Lifecycle
1. `service.sh` runs at boot
2. Waits for system boot completion
3. Auto-mounts all configured rclone remotes
4. Starts sync service in background
5. Updates module description with status emoji

### File Locations on Device
- Module path: `/data/adb/modules/rclone/`
- Configuration: `/data/adb/modules/rclone/conf/`
- Binaries: `/system/vendor/bin/` (via Magisk mount)
- Logs: `/data/log/rclone_sync.log`

## Tips for Contributors

1. **Small, focused changes**: Make minimal modifications to achieve the goal
2. **Test locally first**: Use the build scripts before pushing
3. **Follow existing patterns**: Match the style of surrounding code
4. **Bilingual docs**: Update both English and Chinese when changing README
5. **Verify CI**: Ensure GitHub Actions workflows pass
6. **Check compatibility**: Test on both primary architectures when possible
