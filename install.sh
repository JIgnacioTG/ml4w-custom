#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_action() { echo -e "${CYAN}[ACTION]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"
HOME_CONFIG="${HOME}/.config"
BACKUP_BASE="${HOME}/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${BACKUP_BASE}/${TIMESTAMP}"

backup_needed=false

is_correct_symlink() {
    local source_path="$1"
    local target_path="$2"

    if [[ -L "$target_path" ]]; then
        local current_target
        current_target="$(readlink -f "$target_path")"
        local expected_target
        expected_target="$(readlink -f "$source_path")"
        [[ "$current_target" == "$expected_target" ]]
    else
        return 1
    fi
}

backup_file() {
    local target_path="$1"
    local relative_path="$2"
    local backup_path="${BACKUP_DIR}/${relative_path}"

    mkdir -p "$(dirname "$backup_path")"

    if [[ -L "$target_path" ]]; then
        local link_target
        link_target="$(readlink "$target_path")"
        echo "$link_target" > "${backup_path}.symlink"
        print_info "Backed up symlink: ${target_path} -> ${link_target}"
    elif [[ -f "$target_path" ]]; then
        cp -p "$target_path" "$backup_path"
        print_info "Backed up file: ${target_path}"
    fi
    backup_needed=true
}

process_dotfile() {
    local relative_path="$1"
    local source_path="${DOTFILES_DIR}/${relative_path}"
    local target_path="${HOME_CONFIG}/${relative_path}"

    print_info "Processing: ${relative_path}"

    if [[ ! -e "$source_path" ]]; then
        print_error "Source file not found: ${source_path}"
        return 1
    fi

    if is_correct_symlink "$source_path" "$target_path"; then
        print_success "Already correctly linked: ${relative_path}"
        return 0
    fi

    local parent_dir
    parent_dir="$(dirname "$target_path")"
    if [[ ! -d "$parent_dir" ]]; then
        print_action "Creating directory: ${parent_dir}"
        mkdir -p "$parent_dir"
    fi

    if [[ -e "$target_path" || -L "$target_path" ]]; then
        backup_file "$target_path" "$relative_path"
        if [[ -L "$target_path" ]]; then
            print_action "Removing existing symlink: ${target_path}"
        else
            print_action "Removing existing file: ${target_path}"
        fi
        rm "$target_path"
    fi

    ln -s "$source_path" "$target_path"
    print_success "Created symlink: ${target_path} -> ${source_path}"
}

main() {
    echo -e "${BOLD}${CYAN}"
    echo "============================================"
    echo "  ML4W Custom Dotfiles Installer"
    echo "============================================"
    echo -e "${NC}"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        print_error "Dotfiles directory not found: ${DOTFILES_DIR}"
        exit 1
    fi

    print_info "Script directory: ${SCRIPT_DIR}"
    print_info "Dotfiles source: ${DOTFILES_DIR}"
    print_info "Target config: ${HOME_CONFIG}"
    print_info "Backup location: ${BACKUP_DIR}"
    echo ""

    local errors=0
    local processed=0

    while IFS= read -r -d '' file; do
        relative_path="${file#${DOTFILES_DIR}/}"
        if process_dotfile "$relative_path"; then
            ((processed++)) || true
        else
            ((errors++)) || true
        fi
        echo ""
    done < <(find "$DOTFILES_DIR" -type f -print0)

    echo -e "${BOLD}${CYAN}"
    echo "============================================"
    echo "  Installation Summary"
    echo "============================================"
    echo -e "${NC}"
    print_info "Processed: ${processed} files"

    if [[ $errors -gt 0 ]]; then
        print_error "Errors: ${errors}"
        exit 1
    else
        print_success "All dotfiles installed successfully!"
    fi

    if [[ "$backup_needed" == false && -d "$BACKUP_DIR" ]]; then
        rmdir "$BACKUP_DIR" 2>/dev/null || true
        print_info "No backups needed"
    elif [[ -d "$BACKUP_DIR" ]]; then
        print_info "Backups saved to: ${BACKUP_DIR}"
    fi
}

main "$@"
