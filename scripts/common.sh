#!/usr/bin/env bash

#
# Functions
#

function fail() {
    echo "ERROR: ${*}" 2>&1
    exit 1
}

function phase() {
    echo "---> Phase: ${*}..."
}
