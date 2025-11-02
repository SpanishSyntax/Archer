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

source ./commons.sh

mount_btrfs() {
    local -n given_array="$1"
    local commands_to_run=()
    
    commands_to_run+=("mount \"${ROOT_PART}\" /mnt")
    commands_to_run+=("btrfs su cr /mnt/@")
    commands_to_run+=("btrfs su cr /mnt/@home")
    commands_to_run+=("btrfs su cr /mnt/@snapshots")

    for key in "${!given_array[@]}"; do
        IFS=" | " read -r disk flags path desc <<< "${given_array[$key]}"
        disk=$(echo "$disk" | xargs)
        flags=$(echo "$flags" | xargs)
        path=$(echo "$path" | xargs)
        desc=$(echo "$desc" | xargs)
        commands_to_run+=("[[ -d /mnt/$key ]] || btrfs subvolume create /mnt/$key")
    done
    
    commands_to_run+=("chattr +C /mnt/@home")
    commands_to_run+=("chattr +C /mnt/@snapshots")

    for key in "${!given_array[@]}"; do
        IFS=" | " read -r disk flags path desc <<< "${given_array[$key]}"
        disk=$(echo "$disk" | xargs)
        flags=$(echo "$flags" | xargs)
        path=$(echo "$path" | xargs)
        desc=$(echo "$desc" | xargs)
        commands_to_run+=("chattr +C /mnt/$key")
    done

    # commands_to_run+=("sync")
    # commands_to_run+=("udevadm settle")
    commands_to_run+=("umount /mnt")
    commands_to_run+=("mount -o ssd,noatime,compress=zstd,subvol=@ \"${ROOT_PART}\" /mnt")

    commands_to_run+=("mkdir -p /mnt/.btrfsroot")
    commands_to_run+=("mkdir -p /mnt/home")
    commands_to_run+=("mkdir -p /mnt/.snapshots")

    commands_to_run+=("mount -o ssd,noatime,compress=zstd,nodev,nosuid,noexec,subvolid=5 \"${ROOT_PART}\" /mnt/.btrfsroot")
    commands_to_run+=("mount -o ssd,noatime,compress=zstd,nodev,nosuid,subvol=@home \"${ROOT_PART}\" /mnt/home")
    commands_to_run+=("mount -o ssd,noatime,compress=zstd,nodev,nosuid,noexec,subvol=@snapshots \"${ROOT_PART}\" /mnt/.snapshots")

    for key in "${!given_array[@]}"; do
        IFS=" | " read -r disk flags path desc <<< "${given_array[$key]}"
        disk=$(echo "$disk" | xargs)
        flags=$(echo "$flags" | xargs)
        path=$(echo "$path" | xargs)
        desc=$(echo "$desc" | xargs)
        commands_to_run+=("mkdir -p /mnt$path")
    done

    local options=()
    for key in "${!given_array[@]}"; do
        IFS=" | " read -r disk flags path desc <<< "${given_array[$key]}"
        disk=$(echo "$disk" | xargs)
        flags=$(echo "$flags" | xargs)
        path=$(echo "$path" | xargs)
        desc=$(echo "$desc" | xargs)
        commands_to_run+=("mount -o $flags,subvol=$key $disk /mnt$path")
        local options+=("$key has $path")
    done

    commands_to_run+=("mkdir -p /mnt/boot")
    commands_to_run+=("mount -o nodev,nosuid \"${EFI_PART}\" /mnt/boot")
    commands_to_run+=("swapon \"${SWAP_PART}\"")
    commands_to_run+=("btrfs property set /mnt/@snapshots ro true")

    live_command_output "" "" "Configuring BTRFS volumes on $ROOT_PART" "${commands_to_run[@]}"
    
    continue_script 2 "Finished BTRFS setup" "Finished mouting BTRFS and all of its required structure.

@          has /
@home      has /home
@snapshots has /.snapshots
subvolid 5 has /.btrfsroot

Additionally:

$(printf "%s\n" "${options[@]}")"
}

run_btrfs_setup() {
    declare -A subvols
    local subvols=(
        ["@nix"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid | /nix | Nix store, holds immutable package binaries and system derivations."
        ["@persist"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /persist | Persistent data for NixOS impermanence module (optional)."
        ["@var_cache"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/cache | Cached data for apps and package managers, can be recreated if cleared."
        ["@var_spool"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/spool | Holds queues for tasks like mail, printing, or other pending jobs."
        ["@var_tmp"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/tmp | Temporary files for apps and services, persisting after reboots if needed."
        ["@var_log"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/log | System and application log files for tracking events and troubleshooting."
        ["@var_crash"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/crash | Crash reports and core dumps for analyzing system and application failures."
        ["@var_lib_libvirt_images"]="${ROOT_PART} | ssd,noatime,nodatacow,nodev,nosuid,noexec | /var/lib/libvirt/images | Disk images and metadata for virtual machines managed by libvirt."
        ["@var_lib_machines"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/lib/machines | Container images and metadata for systemd-nspawn containers."
        ["@var_lib_containers"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/lib/containers | Container images and volumes for containers and or Podman."
        ["@var_lib_flatpak"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid | /var/lib/flatpak | Installed Flatpak apps and their sandboxed data and dependencies."
        ["@var_lib_docker"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/lib/docker | Container images, volumes, and metadata for Docker environments."
        ["@var_lib_distrobox"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/lib/distrobox | Data and images for running and managing Distrobox containers."
        ["@var_lib_gdm"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/lib/gdm | Configuration and session data for GNOME Display Manager (GDM)."
        ["@var_lib_accounts"]="${ROOT_PART} | ssd,noatime,compress=zstd,nodatacow,nodev,nosuid,noexec | /var/lib/AccountsService | User account settings and data managed by AccountsService."
    )

    local options=()
    for key in "${!subvols[@]}"; do
        IFS=" | " read -r disk flags path desc <<< "${subvols[$key]}"
        options+=("$key" "$desc" "on")
    done
    
    if [[ "$ROOT_FORM" == "btrfs" ]]; then

        subvol_menu_choice=($(multiselect_prompt "Starting subvol picker" "The following volumes are required for the system to work and will be created automatically\n\n.1. @\n2. @home\n\n3. @snapshots\n\nPlease choose what extra subvolumes you require." "${options[@]}"))

        declare -A filtered_subvols
        for choice in "${subvol_menu_choice[@]}"; do
            if [[ -n "${subvols[$choice]}" ]]; then
                filtered_subvols["$choice"]="${subvols[$choice]}"
            fi
        done

        mount_btrfs filtered_subvols
    fi
}