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

root_password_prompt () {
    local pass="$1"
    ensure_same_pass "root" root_password
    eval "$pass='$root_password'"
}

sysadmin_password_prompt () {
    local pass="$1"
    ensure_same_pass "sysadmin" sysadmin_password
    eval "$pass='$sysadmin_password'"
}

user_setup () {
    clear
    continue_script 2 "Entered root user setup!" "Please provide a password for the root user."
    root_password_prompt root_password

    continue_script 2 "Entered sysadmin user setup!" "Please provide a password for the sysadmin user."
    sysadmin_password_prompt sysadmin_password

    masked_root_password="${root_password:0:1}*******${root_password: -1}"
    masked_sysadmin_password="${sysadmin_password:0:1}*******${sysadmin_password: -1}"
    export root_password
    export masked_sysadmin_password

    continue_script 4 'Admin users password configuration' "Root username:    root
Admin username:    sysadmin
Root     Password:    $masked_root_password
Sysadmin Password:    $masked_sysadmin_password"
}