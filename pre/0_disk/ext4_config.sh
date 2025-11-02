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

mount_ext4() {
    

    continue_script "Mounting $ROOT_PART on /mnt" "Mounting $ROOT_PART on /mnt."

    mount -o ssd,noatime,compress=zstd "${ROOT_PART}" /mnt
    mount -o nodev,nosuid,noexec "${ESP_PART}" /mnt/efi

    continue_script 2 "EXT4 Mounting" "Finished mouting EXT4"
}

run_ext4_setup() {
    
    if [[ "$ROOT_FSTYPE" == "ext4" ]]; then
        mount_ext4
    fi
}