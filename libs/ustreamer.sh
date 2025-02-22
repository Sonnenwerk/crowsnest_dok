#!/bin/bash

#### ustreamer library

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit upon Errors
set -Ee

function run_mjpg {
    local cams
    cams="${1}"
    for instance in ${cams} ; do
        run_ustreamer "${instance}" &
    done
}

function run_ustreamer {
    local cam_sec ust_bin dev pt res fps cstm start_param
    cam_sec="${1}"
    ust_bin="${BASE_CN_PATH}/bin/ustreamer/ustreamer"
    dev="$(get_param "cam ${cam_sec}" device)"
    pt=$(get_param "cam ${cam_sec}" port)
    res=$(get_param "cam ${cam_sec}" resolution)
    fps=$(get_param "cam ${cam_sec}" max_fps)
    cstm="$(get_param "cam ${cam_sec}" custom_flags 2> /dev/null)"
    # construct start parameter
    start_param=( --host 127.0.0.1 -p "${pt}" )
    #Raspicam Workaround
    if [ "${dev}" = "$(dev_is_raspicam)" ]; then
        start_param+=( -m MJPEG --device-timeout=5 --buffers=3 )
    else
        start_param+=( -d "${dev}" --device-timeout=2 )
        # Use MJPEG Hardware encoder if possible
        if [ "$(detect_mjpeg "${cam_sec}")" = "1" ]; then
            start_param+=( -m MJPEG --encoder=HW )
        fi
    fi
    start_param+=( -r "${res}" -f "${fps}" )
    # webroot & allow crossdomain requests
    start_param+=( --allow-origin=\* --static "${BASE_CN_PATH}/ustreamer-www" )
    # Custom Flag Handling (append to defaults)
    if [ -n "${cstm}" ]; then
        start_param+=( "${cstm}" )
    fi
    # Log start_param
    log_msg "Starting ustreamer with Device ${dev} ..."
    echo "Parameters: ${start_param[*]}" | \
    log_output "ustreamer [cam ${cam_sec}]"
    # Start ustreamer
    echo "${start_param[*]}" | xargs "${ust_bin}" 2>&1 | \
    log_output "ustreamer [cam ${cam_sec}]"
    # Should not be seen else failed.
    log_msg "ERROR: Start of ustreamer [cam ${cam_sec}] failed!"
}
