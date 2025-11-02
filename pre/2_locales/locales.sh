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

locales_setup() {
    clear
    locale=en_US
    kblayout=us
    cat <<EOF > /mnt/etc/locale.gen
$locale.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
es_CO.UTF-8 UTF-8
EOF

    echo "LANG=$locale.UTF-8" > /mnt/etc/locale.conf
    echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

    continue_script 4 'Locales' "Your /mnt/etc/locale.gen looks like this:    
$(<'/mnt/etc/locale.gen')

Your /mnt/etc/locale.conf looks like this:    
$(<'/mnt/etc/locale.conf')

Your /mnt/etc/vconsole.conf looks like this:    
$(<'/mnt/etc/vconsole.conf')"

}

