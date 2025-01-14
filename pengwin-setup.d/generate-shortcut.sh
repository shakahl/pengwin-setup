#!/bin/bash
# wslu - Windows 10 linux Subsystem Utility
# Component of Windows 10 linux Subsystem Utility
# <https://github.com/wslutilities/wslu>
# Copyright (C) 2019 Patrick Wu
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Version
wslu_version=2.3.3

# Speed up script by not using unicode.
LC_ALL=C
LANG=C

# force bash to not showing code manually.


# checking interopability
grep enabled /proc/sys/fs/binfmt_misc/WSLInterop >/dev/null || (echo "WSL Interopability is disabled. Please enable it before using WSL."; exit 1)

# variables
## color
black=$(echo -e '\e[30m')
red=$(echo -e '\e[31m')
green=$(echo -e '\e[32m')
brown=$(echo -e '\e[33m')
blue=$(echo -e '\e[34m')
purple=$(echo -e '\e[35m')
cyan=$(echo -e '\e[36m')
yellow=$(echo -e '\e[1;33m')
white=$(echo -e '\e[1;37m')
dark_gray=$(echo -e '\e[1;30m')
light_red=$(echo -e '\e[1;31m')
light_green=$(echo -e '\e[1;32m')
light_blue=$(echo -e '\e[1;34m')
light_purple=$(echo -e '\e[1;35m')
light_cyan=$(echo -e '\e[1;36m')
light_gray=$(echo -e '\e[37m')
orange=$(echo -e '\e[38;5;202m')
light_orange=$(echo -e '\e[38;5;214m')
bold=$(echo -e '\033[1m')
reset=$(echo -e '\033(B\033[m')

## indicator
info="${green}[info]${reset}"
input_info="${cyan}[input]${reset}"
error="${red}[error]${reset}"
warn="${orange}[warn]${reset}"
debug="${orange}${bold}[debug]${reset}"

## Windows build number constant
readonly BN_SPR_CREATORS=15063          #1703, Redstone 2, Creators Update
readonly BN_FAL_CREATORS=16299          #1709, Redstone 3, Fall Creators Update
readonly BN_APR_EIGHTEEN=17134          #1803, Redstone 4, April 2018 Update
readonly BN_OCT_EIGHTEEN=17763          #1809, Redstone 5, October 2018 Update
readonly BN_MAY_NINETEEN=18362          #1903, 19H1, May 2019 Update

# functions

function help {
  app_name=$(basename "$1")
  echo -e "$app_name - Part of wslu, a collection of utilities for Windows 10 Windows Subsystem for Linux
Usage: $2
For more help for $app_name, visit the following site: https://github.com/wslutilities/wslu/wiki/$app_name"
}

function double_dash_p {
  echo "${@//\\/\\\\}"
}

function interop_prefix {
  if [ -f /etc/wsl.conf ]; then
    tmp=$(awk -F '=' '/root/ {print $2}' /etc/wsl.conf | awk '{$1=$1;print}')
    if [ "$tmp" == "" ]; then
      echo "/mnt/"
    else
      echo "$tmp"
    fi
  else
    echo "/mnt/"
  fi
}

function chcp_com {
  "$(interop_prefix)"c/Windows/System32/chcp.com "$@" >/dev/null
}

function winps_exec {
  chcp_com "$(cat ~/.config/wslu/oemcp)"
  "$(interop_prefix)"c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -NonInteractive -Command "$@"
  chcp_com 65001
}

# first run, saving some information
if [ ! -d ~/.config/wslu ]; then
  mkdir -p ~/.config/wslu
fi

# generate oem codepage
if [ ! -f ~/.config/wslu/oemcp ]; then
  "$(interop_prefix)"c/Windows/System32/reg.exe query "HKLM\\SYSTEM\\CurrentControlSet\\Control\\Nls\\CodePage" /v OEMCP 2>&1 | sed -n 3p | sed -e 's|\r||g' | grep -o '[[:digit:]]*' > ~/.config/wslu/oemcp
fi

# when --debug, debug.
if [ "$1" == "--debug" ]; then
  echo "${debug}Debug Mode Enabled."
  shift
  set -x
fi

# basic distro detection
distro="$(head -n1 /etc/os-release | sed -e 's/NAME=\"//g')"
case $distro in
  *Pengwin*) distro="pengwin";;
  *WLinux*) distro="wlinux";;
  Ubuntu*) distro="ubuntu";;
  *Debian*) distro="debian";;
  *Kali*) distro="kali";;
  openSUSE*) distro="opensuse";;
  SLES*) distro="sles";;
  Alpine*) distro="alpine";;
  Arch*) distro="archlinux";;
  *Oracle*) distro="oracle";;
  Scientific*) distro="scilinux";;
  *Fedora*) distro="fedora";;
  *Generic*) [ "fedora" == "$(grep -e "LIKE=" /etc/os-release | sed -e 's/ID_LIKE=//g')" ] && distro="oldfedora" || distro="unknown";;
  *) distro="unknown";;
esac
version="37"

cname=""
iconpath=""
is_gui=0
is_interactive=0
customname=""
customenv=""

help_short="wslusc (--env [PATH]|--name [NAME]|--icon [ICO FILE]|--gui|--interactive|--help|--version) [COMMAND]"

while [ "$1" != "" ]; do
  case "$1" in
    -I|--interactive)is_interactive=1;shift;;
    -i|--icon)shift;iconpath=$1;shift;;
    -n|--name)shift;customname=$1;shift;;
    -e|--env)shift;customenv=$1;shift;;
    -g|--gui)is_gui=1;shift;;
    -h|--help) help "$0" "$help_short"; exit;;
    -v|--version) echo "wslu v$wslu_version; wslusc v$version"; exit;;
    *) cname="$*";break;;
  esac
done

# interactive mode
if [[ $is_interactive -eq 1 ]]; then
  echo "${info} Welcome to wslu shortcut creator interactive mode."
  read -r -e -i "$cname" -p "${input_info} Command to execute: " input
  cname="${input:-$cname}"
  read -r -e -i "$customname" -p "${input_info} Shortcut name [optional, ENTER for default]: " input
  customname="${input:-$customname}"
  read -r -e -i "$is_gui" -p "${input_info} Is it a GUI application? [if yes, input 1; if no, input 0]: " input
  is_gui=$(( ${input:-$is_gui} + 0 ))
  read -r -e -i "$customenv" -p "${input_info} Pre-executed command [optional, ENTER for default]: " input
  customenv="${input:-$customenv}"
  read -r -e -i "$iconpath" -p "${input_info} Custom icon Linux path (support ico/png/xpm/svg) [optional, ENTER for default]: " input
  iconpath="${input:-$iconpath}"
fi

if [[ "$cname" != "" ]]; then
  tpath=$(double_dash_p "$(wslvar -s TMP)") # Windows Temp, Win Double Sty.
  dpath=$(wslpath "$(wslvar -l Desktop)") # Windows Desktop, Win Sty.
  script_location="$(wslpath "$(wslvar -s USERPROFILE)")/wslu" # Windows wslu, Linux WSL Sty.
  localfile_path="/usr/share/wslu" # WSL wslu source file location, Linux Sty.
  script_location_win="%USERPROFILE%\\wslu" #  Windows wslu, Win Double Sty.
  distro_location_win="%LOCALAPPDATA%\\Microsoft\\WindowsApps\\pengwin.exe" # Distro Location, Win Double Sty.
  # change param according to the exec.
  distro_param="run"
  if [[ "$distro_location_win" == *wsl.exe ]]; then
    distro_param="-e"
  fi
  # handling no name given case
  new_cname=$(basename "$(echo "$cname" | awk '{print $1}')")
  # handling name given case
  if [[ "$customname" != "" ]]; then
    new_cname=$customname
  fi
  # Check default icon location
  if [[ ! -f $script_location/wsl.ico ]]; then
    echo "${warn} Default wslusc icon \"wsl.ico\" not found in Windows directory. Copying right now..."
    [[ -d $script_location ]] || mkdir "$script_location"
    if [[ -f $localfile_path/wsl.ico ]]; then
      cp "$localfile_path"/wsl.ico "$script_location"
      echo "${info} Default wslusc icon \"wsl.ico\" copied. Located at \"$script_location\"."
    else
      echo "${error} wsl.ico not found. Failed to copy."
      exit 30
    fi
  fi
  # Check presence of runHidden.vbs
  if [[ ! -f $script_location/runHidden.vbs ]]; then
    echo "${warn} runHidden.vbs not found in Windows directory. Copying right now..."
    [[ -d $script_location ]] || mkdir "$script_location"
    if [[ -f $localfile_path/runHidden.vbs ]]; then
      cp "$localfile_path"/runHidden.vbs "$script_location"
      echo "${info} runHidden.vbs copied. Located at \"$script_location\"."
    else
      echo "${error} runHidden.vbs not found. Failed to copy."
      exit 30
    fi
  fi
  # handling icon
  if [[ "$iconpath" != "" ]]; then
    icon_filename="$(basename "$iconpath")"
    ext="${iconpath##*.}"
    if [[ ! -f $iconpath ]]; then
      iconpath="$(double_dash_p "$(wslvar -s USERPROFILE)")\\wslu\\wsl.ico"
      echo "${warn} Icon not found. Reset to default icon..."
    else
      echo "${info} You choose to use custom icon: $iconpath. Processing..."
      cp "$iconpath" "$script_location"

      if [[ "$ext" != "ico" ]]; then
        if [[ "$ext" == "svg" ]]; then
          echo "${info} Converting $ext icon to ico..."
          convert "$script_location/$icon_filename" -trim -background none -resize 256X256 -define 'icon:auto-resize=16,24,32,64,128,256'  "$script_location/${icon_filename%.$ext}.ico"
          rm "$script_location/$icon_filename"
          icon_filename="${icon_filename%.$ext}.ico"
        elif [[ "$ext" == "png" ]] || [[ "$ext" == "xpm" ]]; then
          echo "${info} Converting $ext icon to ico..."
          convert "$script_location/$icon_filename" -resize 256X256 "$script_location/${icon_filename%.$ext}.ico"
          rm "$script_location/$icon_filename"
          icon_filename="${icon_filename%.$ext}.ico"
        else
          echo "${error} wslusc only support creating shortcut using .png/.svg/.ico icon. Aborted."
          exit 22
        fi
      fi
      iconpath="$script_location_win\\$icon_filename"
    fi
  else
    iconpath="$(double_dash_p "$(wslvar -s USERPROFILE)")\\wslu\\wsl.ico"
  fi

  # handling custom vairable command
  if [[ "$customenv" != "" ]]; then
    echo "${info} the following custom variable/command will be applied: $customenv"
  fi
  if [[ "$is_gui" == "1" ]]; then
    winps_exec "Import-Module 'C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\Modules\\Microsoft.PowerShell.Utility\\Microsoft.PowerShell.Utility.psd1';\$s=(New-Object -COM WScript.Shell).CreateShortcut('$tpath\\$new_cname.lnk');\$s.TargetPath='wscript.exe';\$s.Arguments='$script_location_win\\runHidden.vbs \"$distro_location_win\" $distro_param \"cd ~;$customenv bash -l -c $cname\"';\$s.IconLocation='$iconpath';\$s.Save();"
  else
    winps_exec "Import-Module 'C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\Modules\\Microsoft.PowerShell.Utility\\Microsoft.PowerShell.Utility.psd1';\$s=(New-Object -COM WScript.Shell).CreateShortcut('$tpath\\$new_cname.lnk');\$s.TargetPath='\"$distro_location_win\"';\$s.Arguments='$distro_param cd ~;$customenv bash -l -c $cname';\$s.IconLocation='$iconpath';\$s.Save();"
  fi
  tpath="$(wslpath "$(wslvar -s TMP)")/$new_cname.lnk"
  mv "$tpath" "$dpath"
  echo "${info} Create shortcut ${new_cname}.lnk successful"
else
  echo "${error}No input, aborting"
  exit 21
fi
