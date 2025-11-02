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

hostname_prompt () {
    local host="$1"
    input_text\
        hostname\
        "Hostname username prompt"\
        "This refers to the name on the network and pc name. AKA /etc/hostname"\
        "Enter the hostname: "

    eval "$pass='$hostname'"
}

networking_setup() {
    clear
    hostname_prompt hostname

    echo "$hostname" > /mnt/etc/hostname
    cat <<EOF > /mnt/etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    ${hostname}.localdomain    ${hostname}
EOF

    export hostname
    continue_script 4 'Hostname' "Hostname:    $(</mnt/etc/hostname)
Hosts:

$(</mnt/etc/hosts)"
}

