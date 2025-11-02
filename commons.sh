#!/bin/bash

# Copyright (C) 2021-2024 Thien Tran, Tommaso Chiti
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

detect_os() {
    if [ -f /etc/arch-release ]; then
        OS="arch"
    elif [ -f /etc/NIXOS ]; then
        OS="nixos"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    elif grep -qi "fedora" /etc/os-release 2>/dev/null; then
        OS="fedora"
    else
        OS="unknown"
    fi
    export OS
}

check_dialog(){
    if command -v dialog &> /dev/null; then
        USE_DIALOG=true
    else
        USE_DIALOG=false
    fi
    export USE_DIALOG
}

check_internet() {
    TEMP_FILE=$(mktemp)  # Create a temporary file to store output
    
    continue_script 2 "Testing Internet!" "Testing internet connection..."
    
    ping -c 3 -q google.com > "$TEMP_FILE" 2>&1
    if [ $? -eq 0 ]; then
        printf "\n\n" >> "$TEMP_FILE"
        terminal_title "Internet connection is active." >> "$TEMP_FILE"
        export HAS_INTERNET=true
    else
        printf "\n\n" >> "$TEMP_FILE"
        terminal_title "No internet connection detected." >> "$TEMP_FILE"
        export HAS_INTERNET=false
        exit 1
    fi

    continue_script 2 "You have internet!" "$(cat "$TEMP_FILE")"
    rm -f "$TEMP_FILE"  # Clean up temporary file
}

# update_mirrors() {
#     TEMP_FILE=$(mktemp)
    
#     continue_script 2 "Updating Mirrors" "Running \`reflector\` to fetch the latest fast mirrors..."

#     if reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist >"$TEMP_FILE" 2>&1; then
#         printf "\n\n" >> "$TEMP_FILE"
#         terminal_title "Mirrorlist successfully updated using reflector." >> "$TEMP_FILE"
#         export MIRRORS_UPDATED=true
#     else
#         printf "\n\n" >> "$TEMP_FILE"
#         terminal_title "Failed to update mirrorlist. Check your internet or reflector installation." >> "$TEMP_FILE"
#         export MIRRORS_UPDATED=false
#         exit 1
#     fi

#     continue_script 2 "Mirrorlist Updated!" "$(cat "$TEMP_FILE")"
#     rm -f "$TEMP_FILE"
# }

# refresh_pacman_db() {
#     TEMP_FILE=$(mktemp)

#     continue_script 2 "Refreshing Pacman DB" "Running \`pacman -Syy\` to refresh package database..."

#     if pacman -Syy --noconfirm >"$TEMP_FILE" 2>&1; then
#         printf "\n\n" >> "$TEMP_FILE"
#         terminal_title "Pacman database successfully refreshed." >> "$TEMP_FILE"
#         export PACMAN_REFRESHED=true
#     else
#         printf "\n\n" >> "$TEMP_FILE"
#         terminal_title "Pacman DB refresh failed. Check your internet or mirrors." >> "$TEMP_FILE"
#         export PACMAN_REFRESHED=false
#         exit 1
#     fi

#     continue_script 2 "Pacman DB Refreshed!" "$(cat "$TEMP_FILE")"
#     rm -f "$TEMP_FILE"
# }

# install_fs_tools() {
#     TEMP_FILE=$(mktemp)

#     continue_script 2 "Installing Filesystem Tools" "Installing essential filesystem packages like btrfs-progs, ntfs-3g, and more..."

#     pacman -Sy --noconfirm > /dev/null

#     if pacman -S --noconfirm btrfs-progs ntfs-3g xfsprogs dosfstools exfatprogs e2fsprogs >>"$TEMP_FILE" 2>&1; then
#         printf "\n\n" >> "$TEMP_FILE"
#         terminal_title "Filesystem tools installed successfully." >> "$TEMP_FILE"
#         export FS_TOOLS_INSTALLED=true
#     else
#         printf "\n\n" >> "$TEMP_FILE"
#         terminal_title "Failed to install some filesystem tools." >> "$TEMP_FILE"
#         export FS_TOOLS_INSTALLED=false
#         exit 1
#     fi

#     continue_script 2 "Filesystem Tools Ready!" "$(cat "$TEMP_FILE")"
#     rm -f "$TEMP_FILE"
# }




screen_height=$(tput lines)
screen_width=$(tput cols)
half_height=$((screen_height * 50 / 100))
half_width=$((screen_width * 50 / 100)) 
full_height=$((screen_height * 80 / 100))
full_width=$((screen_width * 80 / 100)) 

output() {
    printf '\e[1;31m%s\e[m\n' "$*"
}

terminal_title() {
    local msg_title="${1:-Default}"
    local wrapped_title=$(echo "$msg_title" | awk '{ gsub(/.{100}/,"&\n") }1')
    local length=$(echo "$wrapped_title" | awk 'BEGIN { max = 0 } { if (length($0) > max) max = length($0) } END { print max }')
    local border=$(printf '%*s' $((length + 8)) '' | tr ' ' '=')

    echo -e "$border"
    echo -e ">>> $wrapped_title <<<"
    echo -e "$border"
}

pause_script() {
    local msg_title="${1:-Default}"
    local msg_text="${2:-Default}"
    local title=$(echo -e "$msg_title")
    local message=$(echo -e "$msg_text")

    dialog \
        --ok-label "Ok" \
        --backtitle "$title" \
        --title "$title" \
        --msgbox "$message" \
        $half_height $half_width 2>&1 >/dev/tty
    exit_code=$?
    case $exit_code in
        0)  return;;
        1)  exit;;
    esac
}

continue_script() {
    local time_sleep="$1"
    local msg_title="${2:-Default}"
    local msg_text="${3:-Default}"
    local title=$(echo -e "$msg_title")
    local message=$(echo -e "$msg_text")

    dialog \
        --ok-label "Ok" \
        --backtitle "$title" \
        --title "$title" \
        --infobox "$message" \
        $half_height $half_width 2>&1 >/dev/tty
    exit_code=$?
    sleep "$time_sleep"
    case $exit_code in
        0)  return;;
        1)  exit;;
    esac
}

output_error() {
        local cmd="$1"
        local exit_code="$2"
               
        local wrapped_cmd=$(echo "$cmd" | awk '{ gsub(/.{100}/,"&\n") }1')

        if [ "$exit_code" -eq 0 ]; then
            echo -e "\
================================================\n\
>>> SUCCESS: COMMANDS EXECUTED SUCCESSFULLY! <<<\n\
================================================\n\n" >> "$combined_log"
        else
            echo -e "\
============================================================\n\
>>> CRITICAL ERROR: COMMAND EXECUTION FAILED! <<<\n\
------------------------------------------------------------\n\
Exit Code: $exit_code\n\
Failed Command: $wrapped_cmd\n\
===========================================================\n\n" >> "$combined_log"
        fi
    }

scroll_window_output() {
    local choice="$1"
    local prompt="$2"
    local file="$3"
    local temp_file

    temp_file=$(mktemp) || { echo "Failed to create temp file"; return 1; }

    echo -e "$prompt\n\n$(cat "$file")" > "$temp_file"

    dialog \
        --backtitle "Viewing $file" \
        --title "$file on logs viewer" \
        --ok-label "Ok, Continue" \
        --extra-button \
        --extra-label "Cancel" \
        --textbox "$temp_file" \
        $full_height $full_width
    local exit_status=$?
    eval "$choice=\"$exit_status\""
    rm -f "$temp_file"
}

live_command_output() {
    local type="$1"
    local user="$2"
    local context="$3"
    shift 3
    local commands=("$@")
    local script_name=$(basename "$(realpath "$0")")
    local combined_log="/tmp/${script_name}_$(date +%Y_%m_%d_%H_%M_%S).log"
    local exit_code=0
    
    if ! id "$USER_WITH_ROOT" &>/dev/null; then
        useradd -m -G wheel -s /bin/bash "$USER_WITH_ROOT"
        echo "$USER_WITH_ROOT ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/"$USER_WITH_ROOT"
    fi

    cleanup() {
        rm -f "$combined_log"
    }
    trap cleanup EXIT

    execute_command() {
        local type="$1"
        local cmd="$2"
        {
            terminal_title "Running: $cmd" >> "$combined_log"
            
            if [[ "$type" == makepkg ]]; then
                sudo -u "$USER_WITH_ROOT" bash -c "$cmd" >> "$combined_log" 2>&1

            elif [[ "$type" == sysuser ]]; then
                if [[ -n "$user" ]]; then
                    sudo -u "$user" bash -c "$cmd" >> "$combined_log" 2>&1
                else
                    pause_script "Error: user is not set" "Please set user before running SSH commands."
                    return 1
                fi

            else
                eval "$cmd" >> "$combined_log" 2>&1
            fi
    
            exit_code=$?
            output_error "$cmd" "$exit_code"
        }
        return $exit_code
    }


    {
        for cmd in "${commands[@]}"; do
            execute_command "$type" "$cmd" || { 
                scroll_window_output return_value "$(terminal_title "$script_name Error, the logs are:")" "$combined_log"
                if [ $return_value -eq 3 ]; then
                    continue_script 2 "You decided to exit" "Script exited execution. Bye."
                    exit 1
                fi
                exit_code=$?
                killall dialog 2>/dev/null
                break
            }
        done

        if [ $exit_code -eq 0 ]; then
            terminal_title "Done, continuing to next step!" >> "$combined_log"
            terminal_title "read the logs for this operation on $combined_log" >> "$combined_log"
            sleep 2
            killall dialog 2>/dev/null
            return 0  # Success
        else
            return 1  # Failure
        fi
    } &

    tail -f "$combined_log" | dialog \
        --backtitle "$script_name on live viewer" \
        --title "$title" \
        --programbox "" \
        "$full_height" "$full_width" 2>&1 >/dev/tty &

    dialog_pid=$!
    wait "$dialog_pid"

    if id "$USER_WITH_ROOT" &>/dev/null; then
        rm -f /etc/sudoers.d/"$USER_WITH_ROOT"  # Remove sudo access
        userdel -r "$USER_WITH_ROOT"  # Remove user and home directory
    fi
}

input_text() {
    local choice="$1"
    local msg_title="${2:-Default}"
    local msg_text="${3:-Default}"
    local msg_prompt="${4:-Default}"
    local title=$(echo -e "$msg_title")
    local message=$(echo -e "$msg_text")
    local prompt=$(echo -e "$msg_prompt")
    local dialog_output
    local console_output
    local exit_code=0
    local fulltext="$message
    
$prompt"

    dialog_output=$(dialog \
        --backtitle "$title" \
        --title "$title" \
        --ok-label "Continue" \
        --inputbox "$fulltext" \
        $half_height $half_width 2>&1 >/dev/tty)
    exit_code=$?
    eval "$choice=\"$dialog_output\""
    return $exit_code
}

input_pass() {
    local choice="$1"
    local msg_title="${2:-Default}"
    local msg_text="${3:-Default}"
    local msg_prompt="${4:-Default}"
    local title=$(echo -e "$msg_title")
    local message=$(echo -e "$msg_text")
    local prompt=$(echo -e "$msg_prompt")
    local dialog_output
    local console_output
    local exit_code=0
    local fulltext="$message
    
$prompt"

    dialog_output=$(dialog \
        --backtitle "$title" \
        --title "$title" \
        --ok-label "Continue" \
        --insecure \
        --passwordbox "$fulltext" \
        $half_height $half_width 2>&1 >/dev/tty)
    exit_code=$?
    eval "$choice=\"$dialog_output\""
    return $exit_code
}

ensure_same_pass() {
    local user="$1"
    local pass="$2"
    local pass1 pass2
    local msg_title="Password validation for: $user"
    
    while true; do
        local msg_text="Please enter your password."
        local msg_prompt="Enter your password"
        input_pass pass1 "$msg_title" "$msg_text" "$msg_prompt"
        
        local msg_text="Please confirm your password."
        local msg_prompt="Confirm your password"
        input_pass pass2 "$msg_title" "$msg_text" "$msg_prompt"
        
        if [ "$pass1" != "$pass2" ]; then
            continue_script 2 "Passwords don't match" "Passwords do not match. Please try again."
        else
            break
        fi
    done
    eval "$pass=\"$pass1\""
    return 0
}

menu_prompt() {
    local choice="$1"
    local msg_title="${2:-Default}"
    local msg_text="${3:-Default}"
    shift 3
    local options=("$@")
    local title=$(echo -e "$msg_title")
    local description=$(echo -e "$msg_text")
    local menu_items=()
    
    for i in "${!options[@]}"; do
        if [[ "${options[i]}" == "Continue" ]]; then
            menu_items+=("c" "${options[i]}")
        elif [[ "${options[i]}" == "Exit" ]]; then
            menu_items+=("e" "${options[i]}")
        elif [[ "${options[i]}" == "Back" ]]; then
            menu_items+=("b" "${options[i]}")
        else
            menu_items+=($((i)) "${options[i]}")
        fi
    done

    dialog_output=$(dialog \
        --backtitle "$title" \
        --title "$title" \
        --ok-label "Select" \
        --menu "$description" \
        $full_height $full_width 15 "${menu_items[@]}" 2>&1 >/dev/tty)
    exit_code=$?
    eval "$choice=\"$dialog_output\""

    return $exit_code

}

multiselect_prompt() {
    local msg_title="${1:-Default}"
    local msg_text="${2:-Default}"
    shift 2
    local options=("$@")

    local title=$(echo -e "$msg_title")
    local description=$(echo -e "$msg_text \n\nUse SPACE to select/deselect options and OK when finished.")

    dialog_output=$(dialog \
        --backtitle "$title" \
        --title "$title" \
        --checklist "$description" \
        $full_height $full_width 15 "${options[@]}" 2>&1 >/dev/tty)

    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "$dialog_output"
    else
        echo ""
    fi

    return $exit_code
}
