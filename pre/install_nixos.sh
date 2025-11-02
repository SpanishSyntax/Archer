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

source ./pre/0_disk/disk_setup.sh

start_disk_setup || { pause_script "Error on disk setup" "start_disk failed. Exiting.";exit;}

commands_to_run=()

continue_script 2 'Generating cofig' 'Generating nixos autoconfig'
nixos-generate-config --root /mnt

continue_script 2 'Editing the configuration.nix' 'Please add whatever you need to the following configuration.nix'
nano /mnt/etc/nixos/configuration.nix

continue_script 2 'Starting install' 'System will attempt to install you configuration.nix'
nixos-install

pause_script 'Finished' 'Done, you may now wish to reboot (further changes can be done by chrooting into /mnt).'
