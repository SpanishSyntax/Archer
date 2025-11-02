#!/usr/bin/env bash

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

source ./pre/0_disk/ext4_config.sh
source ./pre/0_disk/btrfs_config.sh

choose_custom_or_default_layout() {
    local title="Entered disk setup!"
    local description="The following section will help you configure anything disk related: Formatting, partitioning and mounting. Keep in mind those operations are DESTRUCTIVE and will result in data loss for the disks or partitions involved.

BACKUP DATA BEFORE PROCEEDING, you have been warned!

Linux allows you to do whatever the fuck you want. If you so wish, parts of the system could be mounted to USB devices for all we care. We assume that your computer is modern enough to have UEFI support and that root is going to be on an SSD. If those conditions are not met, this script is not for you.
We transfer the responsibility of a reasonable setup to you, the final user. Yet, we provide some sane defaults if you prefer a "batteries included" experience.

The default setup aims to give you full rollback support by using Copy on Write (CoW) from the new kid in the block: BTRFS. This makes it possible to go to a previous system state if an update breaks something...Useful on Archlinux.

Default btrfs layout is as follows:
    *. Partition for /boot/efi. (Therefore no BIOS support, only UEFI.)
    *. Partition for /. (Ergo /home is on the same partition as /)
    *. Subvolumes for things that should not be snapshotted and that should stay intact after a rollback like logs or temps or cache.

No swap is required in any mode as this script sets up zram automatically.

With this in mind, let's pick between sane defaults or full custom mode."
    local options=(\
        "Use default partitioning scheme and autoinstall everything on one disk" \
        "Use default partitioning but i'll select EFI and ROOT partitions myself, then autoinstall" \
        "Dont preconfigure, i want to partition and mount myself, then autoinstall." \
        "Exit"
    )
    while true; do
        menu_prompt install_mode_menu "$title" "$description" "${options[@]}"
        case $install_mode_menu in
            0)  full_default_route;break;;
            1)  custom_default_route;break;;
            2)  full_custom_route;break;;
            e)  exit;;
            *)  continue_script 2 "Option not valid" "That is not an option, returning to start menu.";exit;;
        esac
    done
}

full_default_route() {
    local title="Full Auto Install: This Will Erase Your Disk"
    local description="You are about to perform a fully automated installation using the default BTRFS layout.
    WARNING: This process will:
    1. Wipe the entire selected disk — ALL DATA WILL BE LOST.
    2. Create EFI and root partitions.
    3. Format them with modern filesystems (vfat + BTRFS).
    4. Set up a rollback-friendly subvolume layout.
    5. Install the base system afterward.
    
    This layout is optimized for SSDs and assumes UEFI firmware.
    No swap partition is created — zram will be enabled post-install.
    
    If you are unsure, back up your data now or choose 'Exit'.
    
    Select an option to proceed."

    local options=(\
        "Nuke a disk (delete all data)" \
        "Autopartition to required partitions" \
        "Run Autoinstall" \
        "Back"
    )
    while true; do
        menu_prompt install_mode_menu "$title" "$description" "${options[@]}"
        case $install_mode_menu in
            0)  nuke_disk;;
            1)  autopartition_disk;;
            2)  enforce_btrfs;run_btrfs_setup;break;;
            b)  exit;;
            *)  continue_script 2 "Option not valid" "That is not an option, returning to start menu.";exit;;
        esac
    done
}

custom_default_route() {
    local title="Custom Disk Setup: You Are In Control"
    local description="You are entering the guided installation mode with sane defaults.
    
    This mode still follows the default layout:
    - EFI partition (vfat)
    - Root partition (BTRFS with subvolumes)
    
    But unlike the automatic installer, this mode allows you to:
    1. Manually wipe the target disk.
    2. Create the default partitions step-by-step.
    3. Review and select the target partitions.
    4. Choose or override filesystems.
    5. Run the installation when ready.
    
    All data on selected disks or partitions will be erased.
    This mode is ideal if you want control over each step while still using the recommended layout.
    
    Select an option below to proceed."
    local options=(\
        "Nuke a disk (delete all data)" \
        "Autopartition to required partitions" \
        "Edit disk partitions manually" \
        "Set filesystem formats for partitions" \
        "Select EFI partition" \
        "Select root partition" \
        "Run autoinstall with BTRFS subvolumes" \
        "Back"
    )

    while true; do
        menu_prompt install_mode_menu "$title" "$description" "${options[@]}"
        case $install_mode_menu in
            0)  nuke_disk;;
            1)  autopartition_disk;;
            2)  edit_disk;;
            3)  set_filesystem_for_partitions;;
            4)  select_efi_partition;;
            5)  select_root_partition;;
            6)  enforce_btrfs;run_btrfs_setup;break;;
            b)  exit;;
            *)  continue_script 2 "Option not valid" "That is not an option, returning to start menu.";exit;;
        esac
    done
}

full_custom_route() {
    local title="Full Custom Install: Total Control"
    local description="You are entering the full custom install mode.
    
In this mode, you define everything:
  - Partition layout
  - Filesystem formats
  - EFI and root selection
  - Final installation with BTRFS or EXT4

This is the most flexible and dangerous option — no default layout is enforced. Be careful with your choices.

All data on the selected disk or partitions will be lost.
Ideal for advanced users who want full control over partitioning and layout.

Proceed step-by-step and run install when ready."

    local options=(\
        "Nuke a disk (delete all data)" \
        "Autopartition disk (optional helper)" \
        "Edit disk partitions manually" \
        "Set filesystem formats for partitions" \
        "Select EFI partition" \
        "Select root partition" \
        "Run custom install (based on selected FS)" \
        "Back"
    )

    while true; do
        menu_prompt full_custom_menu "$title" "$description" "${options[@]}"
        case $full_custom_menu in
            0)  nuke_disk;;
            1)  autopartition_disk;;
            2)  edit_disk;;
            3)  set_filesystem_for_partitions;;
            4)  select_efi_partition;;
            5)  select_root_partition;;
            6)  
                case "$ROOT_FORM" in
                    btrfs)
                        enforce_btrfs
                        run_btrfs_setup "$ROOT_PART"
                        break
                        ;;
                    ext4)
                        enforce_ext4
                        run_ext4_setup "$ROOT_PART"
                        break
                        ;;
                    *)
                        continue_script 2 "Unsupported Filesystem" "The selected root filesystem ($ROOT_FORM) is not supported by this installer."
                        ;;
                esac
                break
                ;;
            b)  exit;;
            *)  continue_script 2 "Option not valid" "That is not an option, returning to menu.";;
        esac
    done
}


nuke_disk() {
    local disks=($(lsblk -dpnoNAME | grep -P "/dev/nvme|sd|mmcblk|vd"))
    local disks+=("Continue")
    local disks+=("Exit")
    local title="Nuking data and partitions on the disk"
    local description="The following menu shall help you select a disk for full wipe and automatic partitioning. ALL DATA ON IT SHALL BE DELETED."

    if [ ${#disks[@]} -eq 0 ]; then
            continue_script 2 "No disks found" "No valid storage devices found. Exiting."
            exit
    fi

    while true; do
        menu_prompt format_disk_menu_choice "$title" "$description" "${disks[@]}"
        case $format_disk_menu_choice in
            c)  break;;
            e)  exit;;
            *)  DISK="${disks[$((format_disk_menu_choice))]}";break
                ;;
        esac
    done
    commands_to_run=()

    # 1. Wipe all partition info
    commands_to_run+=("wipefs --all --force \"${DISK}\"")

    # 2. Overwrite beginning of disk
    commands_to_run+=("dd if=/dev/zero of=\"${DISK}\" bs=1M count=10 status=progress")

    # 3. Reload partition info
    commands_to_run+=("sync")
    commands_to_run+=("partprobe \"${DISK}\"")
    commands_to_run+=("udevadm settle")
    
    export DISK
    live_command_output "" "" "Nuking $DISK" "${commands_to_run[@]}"
}

autopartition_disk() {
    commands_to_run=()

    EFI_PART="/dev/disk/by-partlabel/ESP"
    ROOT_PART="/dev/disk/by-partlabel/ROOT"
    SWAP_PART="/dev/disk/by-partlabel/SWAP"
    
    commands_to_run+=("parted -s \"${DISK}\" mklabel gpt")
    commands_to_run+=("parted -s \"${DISK}\" mkpart ESP fat32 1MiB 1024MiB")
    commands_to_run+=("parted -s \"${DISK}\" mkpart ROOT btrfs 1024MiB -16GiB")
    commands_to_run+=("parted -s \"${DISK}\" mkpart SWAP linux-swap -16GiB 100%")
    commands_to_run+=("parted -s \"${DISK}\" set 1 esp on")
    
    commands_to_run+=("sync")
    commands_to_run+=("partprobe \"${DISK}\"")
    commands_to_run+=("udevadm settle")

    if ! blkid -s TYPE -o value "${EFI_PART}" | grep -q "vfat"; then
        EFI_FORM='vfat'
        commands_to_run+=("mkfs.vfat -F 32 -n ESP \"${EFI_PART}\"")
    fi

    if ! blkid -s TYPE -o value "${ROOT_PART}" | grep -q "btrfs"; then
        ROOT_FORM='btrfs'
        commands_to_run+=("mkfs.btrfs -L ROOT -f \"${ROOT_PART}\"")
    fi
    
    if ! blkid -s TYPE -o value "${SWAP_PART}" | grep -q "swap"; then
        SWAP_FORM='linux-swap'
        commands_to_run+=("mkswap -L SWAP \"${SWAP_PART}\"")
    fi

    live_command_output "" "" "Partitioning $DISK" "${commands_to_run[@]}"
}

edit_disk() {
    local disks=($(lsblk -dpnoNAME | grep -P "/dev/nvme|sd|mmcblk|vd"))
    local disks+=("Continue")
    local disks+=("Exit")
    local title="Starting disk partitioner"
    local description="The following menu shall help you edit a disks partitions in order to make space for installing arch.

Simply select a disk, edit as neccesary and come back. When done, select option 'c' to continue script execution."

    if [ ${#disks[@]} -eq 0 ]; then
            continue_script 2 "No disks found" "No valid storage devices found. Exiting."
            exit
    fi

    while true; do
        menu_prompt format_disk_menu_choice "$title" "$description" "${disks[@]}"
        DISK="${disks[$((format_disk_menu_choice))]}"
        export DISK
        case $format_disk_menu_choice in
            c)  break;;
            e)  exit;;
            *)  if ! cgdisk "$DISK"; then
                    continue_script 2 "Exited cgdisk for $DISK" "cgdisk exited for disk $DISK. Returning to menu."
                fi
                ;;
        esac
    done
}

set_filesystem_for_partitions() {
    local partitions=($(lsblk -ppnoNAME,SIZE,TYPE | grep -P "/dev/nvme|sd|mmcblk|vd" | grep -w "part" | sed 's/└─//g' | sed 's/├─//g' | awk '{print $1}'))
    local partitions+=("Continue")
    local partitions+=("Exit")
    local title="Starting partition formatter"
    local description="The following menu shall help you assing a filesystem to a selected partition.

Simply select a partition, format it on the menu that opens up and then come back here. When done, select option 1 to continue script execution."

    if [ ${#partitions[@]} -eq 0 ]; then
            continue_script 2 "No partitions found" "No valid partitions found. Exiting."
            exit
    fi

    while true; do
        menu_prompt format_partition_menu "$title" "$description" "${partitions[@]}"
        local partition="${partitions[$((format_partition_menu))]}"
        case $format_partition_menu in
            c)  break;;
            e)  exit;;
            *)  format_a_partition "$partition"
                ;;
        esac
    done
}

format_a_partition() {
    local partition="$1"

    local title="Pick a filesystem for $partition"
    local description="You are now setting a filesystem for partition $partition.

Please select a filesystem for it from the following:"
    local options=(
        "Format as EFI" \
        "Format as BTRFS" \
        "Format as EXT4" \
        "Format as NTFS" \
        "Format as XFS" \
        "Back" \
        "Exit"
    )

    menu_prompt partition_menu "$title" "$description" "${options[@]}"
    case $partition_menu in
        0)  enforce_efi "$partition";;
        1)  enforce_btrfs "$partition";;
        2)  enforce_ext4 "$partition";;
        3)  enforce_ntfs "$partition";;
        4)  enforce_xfs "$partition";;
        b)  return;;
        e)  exit;;
        *)  continue_script 2 "Option not valid" "That is not an option, retry.";;
    esac
}

format_as_efi() {
    local partition="$1"
    mkfs.fat -F 32 "${partition}"
}

format_as_ext4() {
    local partition="$1"
    mkfs.ext4 -f "${partition}"
}

format_as_btrfs() {
    local partition="$1"
    mkfs.btrfs -f "${partition}"
}

format_as_ntfs() {
    local partition="$1"
    mkfs.ntfs -f "${partition}"
}

format_as_xfs() {
    local partition="$1"
    mkfs.xfs -f "${partition}"
}

enforce_efi() {
    format_as_efi "$EFI_PART"
    EFI_FORM=$(lsblk -no FSTYPE "$EFI_PART")
    if [[ "$EFI_FORM" != "vfat" ]]; then
        continue_script 2 "Not EFI" "Error: The selected partition ($EFI_PART) is not formatted as EFI.
Please go back and format the partition as EFI Partition."
        export EFI_PART EFI_FORM
        exit
    else
        continue_script 2 "Formatted as EFI" "The partition ($EFI_PART) is correctly formatted as EFI."
    fi
}

enforce_btrfs() {
    format_as_btrfs "$ROOT_PART"
    ROOT_FORM=$(lsblk -no FSTYPE "$ROOT_PART")
    if [[ "$ROOT_FORM" != "btrfs" ]]; then
        continue_script 2 "Not BTRFS" "Error: The selected partition ($ROOT_PART) is not formatted as BTRFS.
Please go back and format the partition as BTRFS Partition."
        export ROOT_PART ROOT_FORM
        exit
    else
        continue_script 2 "Is BTRFS" "The partition ($ROOT_PART) is correctly formatted as BTRFS."
    fi
}

enforce_ext4() {
    format_as_ext4 "$ROOT_PART"
    ROOT_FORM=$(lsblk -no FSTYPE "$ROOT_PART")
    if [[ "$ROOT_FORM" != "ext4" ]]; then
        continue_script 2 "Not EXT4" "Error: The selected partition ($ROOT_PART) is not formatted as EXT4.
Please go back and format the partition as EXT4 Partition."
        export ROOT_PART ROOT_FORM
        exit
    else
        continue_script 2 "Is EXT4" "The partition ($ROOT_PART) is correctly formatted as EXT4."
    fi
}

enforce_ntfs() {
    format_as_ntfs "$ROOT_PART"
    ROOT_FORM=$(lsblk -no FSTYPE "$ROOT_PART")

    if [[ "$ROOT_FORM" != "ntfs" ]]; then
        continue_script 2 "Not NTFS" "Error: The selected partition ($ROOT_PART) is not formatted as NTFS.
Please go back and format the partition as NTFS Partition."
        export ROOT_PART ROOT_FORM
        exit
    else
        continue_script 2 "Is NTFS" "The partition ($ROOT_PART) is correctly formatted as NTFS."
    fi
}

enforce_xfs() {
    format_as_xfs "$ROOT_PART"
    ROOT_FORM=$(lsblk -no FSTYPE "$ROOT_PART")

    if [[ "$ROOT_FORM" != "xfs" ]]; then
        continue_script 2 "Not XFS" "Error: The selected partition ($ROOT_PART) is not formatted as XFS.
Please go back and format the partition as XFS Partition."
        export ROOT_PART ROOT_FORM
        exit
    else
        continue_script 2 "Is XFS" "The partition ($ROOT_PART) is correctly formatted as XFS."
    fi
}

enforce_swap() {
    format_as_xfs "$ROOT_PART"
    ROOT_FORM=$(lsblk -no FSTYPE "$ROOT_PART")

    if [[ "$ROOT_FORM" != "linux-swap" ]]; then
        continue_script 2 "Not linux-swap" "Error: The selected partition ($ROOT_PART) is not formatted as swap.
Please go back and format the partition as swap Partition."
        export ROOT_PART ROOT_FORM
        exit
    else
        continue_script 2 "Is XFS" "The partition ($ROOT_PART) is correctly formatted as swap."
    fi
}

select_efi_partition() {
    local part="$1"
    local partitions=($(lsblk -ppnoNAME,SIZE,TYPE | grep -P "/dev/nvme|sd|mmcblk|vd" | grep -w "part" | sed 's/└─//g' | sed 's/├─//g' | awk '{print $1}'))
    local title="Select EFI Partition"
    local description="Please select a partition to use as the EFI System Partition (/boot/efi)."

    local menu_items=()
    local formatted_menu=()

    local max_no_len=2
    local max_partition_len=0
    local max_label_len=0
    local max_size_len=0
    local max_fstype_len=0

    for i in "${!partitions[@]}"; do
        local partition="${partitions[$i]}"
        local label=$(lsblk -no LABEL "$partition")
        local size=$(lsblk -no SIZE "$partition")
        local fstype=$(lsblk -no FSTYPE "$partition")

        max_partition_len=$((${#partition} > max_partition_len ? ${#partition} : max_partition_len))
        max_label_len=$((${#label} > max_label_len ? ${#label} : max_label_len))
        max_size_len=$((${#size} > max_size_len ? ${#size} : max_size_len))
        max_fstype_len=$((${#fstype} > max_fstype_len ? ${#fstype} : max_fstype_len))
    done

    for i in "${!partitions[@]}"; do
        local partition="${partitions[$i]}"
        local label=$(lsblk -no LABEL "$partition")
        local size=$(lsblk -no SIZE "$partition")
        local fstype=$(lsblk -no FSTYPE "$partition")

        menu_items+=("$(printf "%-${max_partition_len}s" "$partition") $(printf "%-${max_fstype_len}s" "$fstype") $(printf "%-${max_size_len}s" "$size") $(printf "%-${max_label_len}s" "$label")")
    done

    menu_prompt root_menu "$title" "$description" "${menu_items[@]}"
    EFI_PART="${partitions[$((root_menu))]}"
    EFI_FORM=$(lsblk -no FSTYPE "$EFI_PART")
    export EFI_PART EFI_FORM
}

select_root_partition() {
    local part="$1"
    local partitions=($(lsblk -ppnoNAME,SIZE,TYPE | grep -P "/dev/nvme|sd|mmcblk|vd" | grep -w "part" | sed 's/└─//g' | sed 's/├─//g' | awk '{print $1}'))
    local title="Select ROOT Partition"
    local description="Please select a partition to use as the ROOT System Partition (/)."

    local menu_items=()
    local formatted_menu=()

    local max_no_len=2
    local max_partition_len=0
    local max_label_len=0
    local max_size_len=0
    local max_fstype_len=0

    for i in "${!partitions[@]}"; do
        local partition="${partitions[$i]}"
        local label=$(lsblk -no LABEL "$partition")
        local size=$(lsblk -no SIZE "$partition")
        local fstype=$(lsblk -no FSTYPE "$partition")

        max_partition_len=$((${#partition} > max_partition_len ? ${#partition} : max_partition_len))
        max_label_len=$((${#label} > max_label_len ? ${#label} : max_label_len))
        max_size_len=$((${#size} > max_size_len ? ${#size} : max_size_len))
        max_fstype_len=$((${#fstype} > max_fstype_len ? ${#fstype} : max_fstype_len))
    done

    for i in "${!partitions[@]}"; do
        local partition="${partitions[$i]}"
        local label=$(lsblk -no LABEL "$partition")
        local size=$(lsblk -no SIZE "$partition")
        local fstype=$(lsblk -no FSTYPE "$partition")

        menu_items+=("$(printf "%-${max_partition_len}s" "$partition") $(printf "%-${max_fstype_len}s" "$fstype") $(printf "%-${max_size_len}s" "$size") $(printf "%-${max_label_len}s" "$label")")
    done

    menu_prompt root_menu "$title" "$description" "${menu_items[@]}"
    ROOT_PART="${partitions[$((root_menu))]}"
    ROOT_FORM=$(lsblk -no FSTYPE "$ROOT_PART")
    export ROOT_PART ROOT_FORM
}

start_disk_setup() {
    clear
    choose_custom_or_default_layout
    if [ $? -ne 0 ]; then
        continue_script 2 "Failed" "Failed to choose layout."
        return 1
    fi

    return 0
}
