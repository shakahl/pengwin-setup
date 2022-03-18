#!/bin/bash

# shellcheck source=./uninstall-common.sh
source "$(dirname "$0")/uninstall-common.sh" "$@"

shortcut_path=$(wslpath "$(wslvar -l Programs)")/"${SHORTCUTS_FOLDER}"

function main() {

  echo "Uninstalling Pengwin start-menu shortcuts"
  rem_dir "$shortcut_path"

}

if show_warning "Pengwin start-menu shortcuts" "$@"; then
  main "$@"
fi
