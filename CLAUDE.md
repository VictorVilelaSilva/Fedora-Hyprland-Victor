# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **KooL's Fedora-Hyprland Install Script** - an automated installation script for setting up Hyprland on Fedora Linux with pre-configured dotfiles, themes, and components. The repository contains installation scripts but NOT the actual Hyprland configuration files (those are downloaded from the separate [Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) repository during installation).

## Key Commands

### Main Installation
```bash
# Standard installation (interactive)
./install.sh

# Installation with preset configuration
./install.sh --preset preset.sh

# Auto-install (download and run)
sh <(curl -L https://raw.githubusercontent.com/JaKooLit/Fedora-Hyprland/main/auto-install.sh)
```

### Re-running Individual Scripts
Scripts must be run from the repository root, NOT from within `install-scripts/`:
```bash
# Correct way to re-run a component
./install-scripts/gtk_themes.sh
./install-scripts/sddm.sh

# WRONG - do not cd into install-scripts first
```

### System Monitor Services
Optional user-level systemd services for monitoring:
```bash
# Install services (run from repo root)
./install-scripts/battery-monitor.sh
./install-scripts/disk-monitor.sh
./install-scripts/temp-monitor.sh

# Manage services
systemctl --user status|start|stop battery-monitor
systemctl --user status|start|stop disk-monitor
systemctl --user status|start|stop temp-monitor
```

## Architecture

### Entry Points
- **`install.sh`**: Main orchestrator with whiptail-based interactive UI for component selection
- **`preset.sh`**: Default preset configuration file (can be customized for automated installations)
- **`auto-install.sh`**: Remote installer that downloads and runs the script

### Core Structure

**`install-scripts/`** - Modular installation scripts for each component:
- `Global_functions.sh`: Shared functions for package installation, logging, and progress display
- `00-hypr-pkgs.sh`: Core Hyprland packages list (edit to customize packages)
- `copr.sh`: COPR repository configuration
- `hyprland.sh`: Hyprland installation
- Component-specific scripts: `nvidia.sh`, `bluetooth.sh`, `sddm.sh`, `gtk_themes.sh`, `thunar.sh`, `zsh.sh`, etc.
- `dotfiles-main.sh`: Downloads actual config files from Hyprland-Dots repo
- `02-Final-Check.sh`: Post-installation validation

**`assets/`** - Static configuration files:
- `fastfetch/`: System info display configs
- `add_zsh_theme/`: Additional zsh themes
- `Thunar/`, `gtk-3.0/`, `xfce4/`: Component configs
- `.zprofile`, `.zshrc`: Shell configurations

### Execution Flow
1. `install.sh` checks prerequisites (not root, whiptail installed, GPU detection)
2. Presents whiptail checklist for component selection (or loads from preset)
3. Executes core scripts: COPR repos → packages → fonts → Hyprland
4. Executes selected component scripts in order
5. Runs final validation and offers reboot

### Key Patterns

**Logging**: All operations log to `Install-Logs/` directory with timestamped files

**Package Management**:
- Uses `Global_functions.sh` for consistent package operations
- `install_package()`: Installs with progress spinner, checks if already installed
- `uninstall_package()`: Safe removal with verification
- All DNF output redirected to logs

**Script Sourcing**: Individual scripts source `Global_functions.sh` for shared utilities:
```bash
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
```

**Safety Checks**:
- Scripts must NOT be run as root
- Detects active login managers before SDDM installation
- Checks for NVIDIA GPU to show appropriate options
- Verifies download directory has write permissions

## Customization

### Package Lists
Edit `install-scripts/00-hypr-pkgs.sh` to modify core packages. The `Extra=()` array at the top allows adding custom packages without editing the main list.

### COPR Repositories
Edit `install-scripts/copr.sh` to add/remove COPR repos.

### Preset Configuration
Create custom preset files based on `preset.sh` format:
```bash
nvidia="ON"
gtk_themes="ON"
dots="ON"
# ... etc
```

### Custom Wallpapers
Wallpapers come from the separate Hyprland-Dots repository. To install custom wallpapers:
- See `CUSTOM_WALLPAPERS_GUIDE.md` for detailed instructions
- Use the provided `install-scripts/custom-wallpapers.sh` template
- Options: local files, Git repo, or direct URLs

### Custom GTK Themes & Icons
GTK themes and icons are downloaded from the [GTK-themes-icons](https://github.com/JaKooLit/GTK-themes-icons) repository. To add custom themes/icons:
- See `CUSTOM_GTK_THEMES_GUIDE.md` for comprehensive instructions
- Use the provided `install-scripts/custom-gtk-themes.sh` template
- Place local themes in `assets/custom-gtk-themes/`
- Place local icons in `assets/custom-gtk-icons/`
- Default theme configuration: `assets/gtk-3.0/settings.ini`
- Installed themes go to `~/.themes/`, icons to `~/.icons/`

## Important Constraints

1. **Do not modify core dotfiles here** - they live in the separate Hyprland-Dots repository
2. **Scripts depend on execution from repo root** - they use relative paths to find Global_functions.sh
3. **Whiptail UI requires terminal** - automated installations should use preset files
4. **Nouveau conflicts** - NVIDIA setup assumes nouveau is not installed
5. **SDDM conflicts** - cannot install if other login managers (GDM, LightDM) are active

## Development Workflow

### Contributing
- Fork the `development` branch (not `main`)
- Follow commit message conventions in `COMMIT_MESSAGE_GUIDELINES.md`
- Test on clean Fedora installation (Sway Spin or Minimal recommended)
- Update documentation if adding new components

### Commit Message Format
Use conventional commit types: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, etc.

Example: `feat: add quickshell installation support`

### Testing Individual Scripts
When testing component scripts:
```bash
# Create test log directory if needed
mkdir -p Install-Logs

# Run from repo root
./install-scripts/<script-name>.sh
```

## External Dependencies

- **Hyprland-Dots**: Main config files repo (auto-cloned during installation)
- **GTK-themes-icons**: Optional themes repo
- **Wallpaper-Bank**: Optional wallpapers
- **SDDM theme**: Modified fork of sddm-astronaut-theme
- **COPR repos**: Required for Hyprland and related packages on Fedora

## Known Issues & Workarounds

### NVIDIA
- May need `env = WLR_DRM_DEVICES,/dev/dri/cardX` in ENVariables.conf
- Older cards (GTX 800 and below) need driver version adjustment in nvidia.sh
- Some users report SDDM login hang - check DRI device paths

### Rofi
- X11 rofi conflicts with Wayland - uninstall and use rofi-wayland instead

### Fedora 39 and Older
- Waybar < 0.10.3 causes workspace display issues

### Auto-start Hyprland
- Disabled by default in `.zprofile` to avoid conflicts with other DEs
- Uncomment lines in `~/.zprofile` to re-enable

## File Paths of Interest

- Installation logs: `Install-Logs/`
- Main script: `install.sh`
- Global utilities: `install-scripts/Global_functions.sh`
- Package definitions: `install-scripts/00-hypr-pkgs.sh`
- Dotfiles installer: `install-scripts/dotfiles-main.sh`
