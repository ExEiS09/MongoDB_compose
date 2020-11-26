#!/bin/bash

binarypath="/usr/local/bin"

## We're getting the information from ENVs from DF. It's done for minimize the number of layers

unzip $consulbin && mv $workbin $binarypath

if [[ $(echo $?) -ne 0 ]]
    then
        echo 'Something went wrong with PATH or binary itself. Verify that the URL for binary is correct and PATH variable not corrupted'
        exit 1
fi

if [[ -z "$CONSUL_USER" ]]
    then
        echo 'Please specify valid user for consul substitution with CONSUL_USER var'
        exit 2
fi


consul -autocomplete-install
complete -C ${binarypath} ${workbin}

check_user() {
    cat /etc/passwd | grep ${CONSUL_USER}
    echo $?
}

if ! check_user
    then
        