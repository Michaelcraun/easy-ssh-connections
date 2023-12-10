#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set_autoconnect_port() {
    server=$1
    port=$2
    ssh_config="/etc/ssh/ssh_config"

    echo "Host $server" >> $ssh_config
    echo "Port $port" >> $ssh_config
}

create_passwordless_login() {
    server_name=$1
    tmp_port=$2

    ssh-keygen -t rsa -b 2048 -P '' -f ".$server_name.pub"
    echo "Username for server with name $server_name?"
    read username
    server_address="$username@$server_name"

    if [ -z ${tmp_port+x} ]; then declare port=22; else declare port=$tmp_port; fi
    ssh-copy-id -p $port $server_address
    ssh $server_address -p $port

    echo "ssh $server_address -p $port" > "$SCRIPT_DIR/$server_name.sh"
    chmod +x "$SCRIPT_DIR/$server_name.sh"

    if [ $port != 22 && $(test -f "$SCRIPT_DIR/$server_name.sh") ]; then
        set_autoconnect_port $server_name $port;
    fi
}

print_sudo_warning() {
    echo "****************************** WARNING *******************************"
    echo "This script must be ran with sudo permissions! If it was not, please cancel (ctrl + C) and rerun with sudo permissions!"
    sleep 10
}

while getopts s:p: flag
do
    case "$flag" in
        s) server=$OPTARG;;
        p) port=$OPTARG; print_sudo_warning;;
        *) echo "Invalid command given [$OPTARG] - ending"; exit 0;;
    esac
done

create_passwordless_login $server $port
exit 1