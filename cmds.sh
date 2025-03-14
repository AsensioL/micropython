#!/bin/bash

export DOCKER_IMAGE_NAME="micropython-dev"

export        DEVEL_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export DOCKER_DEVEL_PATH="/workdir"


############################## DOCKER COMMANDS ##############################

## Create Docker image
# Command options:
#   --debug -> print stdout from RUN commands (instead of a sliding window)
docker_create_image() {
    # Build docker image
	docker build \
	    --file ${DEVEL_PATH}/Dockerfile \
        --build-arg WORKSPACE=${DOCKER_DEVEL_PATH} \
        -t ${DOCKER_IMAGE_NAME} ${DEVEL_PATH} # --progress=plain
}

# Run bash inside the Docker container (no params) or run a command (with params)
docker_terminal() {
    docker run --rm -it \
        -v ${DEVEL_PATH}:${DOCKER_DEVEL_PATH} \
        -e DEVEL_PATH \
        -e DOCKER_DEVEL_PATH \
        -e BOARD \
        ${DOCKER_IMAGE_NAME} \
        /bin/bash -c "${@:-/bin/bash}"
}

######################### BOARD SELECTION SECTION #########################

SELECTED_BOARD_FILE=.default_board

check_selected_board() {
    if ! [ -f ${DEVEL_PATH}/${SELECTED_BOARD_FILE} ]; then
        echo_red "No board selected. Run the following command"
        echo_red "  select_board <BOARD_NAME>"
        return 1
    fi

    export BOARD=$(cat ${DEVEL_PATH}/${SELECTED_BOARD_FILE})
    return 0
}

select_board() {
    if [ "x$1" = "x" ]; then
        echo_red "Enter board name <BOARD_NAME>"
        return 1
    fi

    echo "$1" > ${DEVEL_PATH}/${SELECTED_BOARD_FILE}
    export BOARD=$1

    echo "Board selected: ${BOARD}"
}


############################## CLEAN SECTION ##############################

## Clean app
clean_app() {

    check_selected_board

    docker_terminal \
        "cd ${DOCKER_DEVEL_PATH}/ports/stm32 && \
         make clean BOARD=${BOARD} V=1"
}


############################## CROSS-COMPILER SECTION ##############################

## Default build command
build_mpy() {
    docker_terminal "make -C mpy-cross"
}

clean_mpy() {
    docker_terminal "make clean -C mpy-cross"
}


############################## SUBMODULES SECTION ##############################

## Build submodules for the selected board
build_submodules() {

    check_selected_board

    docker_terminal \
        "cd ${DOCKER_DEVEL_PATH}/ports/stm32 && \
         make submodules BOARD=${BOARD} V=1"
}


## Build MicroPython binary
build_app() {

    check_selected_board

    docker_terminal \
        "cd ${DOCKER_DEVEL_PATH}/ports/stm32 && \
         make BOARD=${BOARD} V=1"
}


## Flash MicroPython binary
flash_board() {

    check_selected_board

    HEX_FILE="${DEVEL_PATH}/ports/stm32/build-${BOARD}/firmware.hex"
    COMMAND_FILE="${DEVEL_PATH}/.flash_task.jlink"
    cat << EOF > $COMMAND_FILE
si 1
device STM32H743VI
speed auto
if SWD
connect under reset
erase
loadfile $HEX_FILE
r
q
EOF

    # Assume WSL and get host IP
    IP="$(ip route | grep 'default via' | awk '{print $3}')"

    JLinkExe -ip "${IP}" -CommanderScript "$COMMAND_FILE"
}


############################## OTHERS ##############################

# Print in red text
function echo_red () {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e $RED $1 $NC
}


function h() {
    echo "##########################"
    echo "#  MicroPython (custom)  #"
    echo "##########################"
    echo "Docker image name: ${DOCKER_IMAGE_NAME}"
    echo
    echo "Functions:"
    echo "  docker_create_image - Step 0 (once): Build Docker image"
    echo "  build_mpy           - Step 1 (once): Build MicroPython compiler"
    echo "  select_board        - Step 2: Select a board. Example:  select_board NUCLEO_G0B1RE"
    echo "  build_submodules    - Step 3: Build submodules"
    echo "  build_app           - Step 4: Build  App in the   Docker image"
    echo "  flash_board         - Step 5: Flash board outside Docker image. Example: flash_board 192.168"
    echo "  clean_app           - Run make clean within  the  Docker image. Optinal params: [hard]"
    echo
    echo "Helper functions:"
    echo "  h                   - Print this help info"
    echo "  docker_terminal     - Enter /bin/bash terminal within the Docker image (useful for debugging)"
}

h
check_selected_board

