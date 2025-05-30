#!/bin/bash
set -e

# Argument parsing
SHORT=r,d:,p:,s:,h
LONG=remove,dest-dir:,prefix-dir:,sysconf-dir:,no-ectool,no-pre-uninstall,no-post-install,no-battery-sensors,no-sudo,no-pip-install,help
VALID_ARGS=$(getopt -a --options $SHORT --longoptions $LONG -- "$@")
if [[ $? -ne 0 ]]; then
    exit 1;
fi

TEMP_FOLDER='./.temp'
trap 'rm -rf $TEMP_FOLDER' EXIT

PREFIX_DIR="/usr"
DEST_DIR=""
SYSCONF_DIR="/etc"
SHOULD_INSTALL_ECTOOL=true
SHOULD_PRE_UNINSTALL=true
SHOULD_POST_INSTALL=true
SHOULD_REMOVE=false
NO_BATTERY_SENSOR=false
NO_SUDO=false
NO_PIP_INSTALL=false

eval set -- "$VALID_ARGS"
while true; do
  case "$1" in
    '--remove' | '-r')
        SHOULD_REMOVE=true
        ;;
    '--prefix-dir' | '-p')
        PREFIX_DIR=$2
        shift
        ;;
    '--dest-dir' | '-d')
        DEST_DIR=$2
        shift
        ;;
    '--sysconf-dir' | '-s')
        SYSCONF_DIR=$2
        shift
        ;;
    '--no-ectool')
        SHOULD_INSTALL_ECTOOL=false
        ;;
    '--no-pre-uninstall')
        SHOULD_PRE_UNINSTALL=false
        ;;
    '--no-post-install')
        SHOULD_POST_INSTALL=false
        ;;
    '--no-battery-sensors')
        NO_BATTERY_SENSOR=true
        ;;
    '--no-sudo')
        NO_SUDO=true
        ;;
    '--no-pip-install')
        NO_PIP_INSTALL=true
        ;;
    '--help' | '-h')
        echo "Usage: $0 [--remove,-r] [--dest-dir,-d <installation destination directory (defaults to $DEST_DIR)>] [--prefix-dir,-p <installation prefix directory (defaults to $PREFIX_DIR)>] [--sysconf-dir,-s system configuration destination directory (defaults to $SYSCONF_DIR)] [--no-ectool] [--no-post-install] [--no-pre-uninstall] [--no-sudo] [--no-pip-install]" 1>&2
        exit 0
        ;;
    --)
        break
        ;;
  esac
  shift
done

if ! python -h 1>/dev/null 2>&1; then
    echo "Missing package 'python'!"
    exit 1
fi

if [ "$NO_PIP_INSTALL" = false ]; then
    if ! python -m pip -h 1>/dev/null 2>&1; then
        echo "Missing python package 'pip'!"
        exit 1
    fi
fi

if [ "$SHOULD_REMOVE" = false ]; then
    if ! python -m build -h 1>/dev/null 2>&1; then
        echo "Missing python package 'build'!"
        exit 1
    fi
fi

PYTHON_SCRIPT_INSTALLATION_PATH="$DEST_DIR$PREFIX_DIR/bin/fw-fanctrl"

# Root check
if [ "$EUID" -ne 0 ] && [ "$NO_SUDO" = false ]
  then echo "This program requires root permissions or use the '--no-sudo' option"
  exit 1
fi

SERVICES_DIR="./services"
SERVICE_EXTENSION=".service"

SERVICES="$(cd "$SERVICES_DIR" && find . -maxdepth 1 -maxdepth 1 -type f -name "*$SERVICE_EXTENSION" -exec basename {} "$SERVICE_EXTENSION" \;)"
SERVICES_SUBCONFIGS="$(cd "$SERVICES_DIR" && find . -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)"

function sanitizePath() {
    local SANITIZED_PATH="$1"
    local SANITIZED_PATH=${SANITIZED_PATH//..\//}
    local SANITIZED_PATH=${SANITIZED_PATH#./}
    local SANITIZED_PATH=${SANITIZED_PATH#/}
    echo "$SANITIZED_PATH"
}

function build() {
    echo "building package"
    rm -rf "dist/" 2> "/dev/null" || true
    python -m build -s
    find . -type d -name "*.egg-info" -exec rm -rf {} + 2> "/dev/null" || true
}

# remove remaining legacy files
function uninstall_legacy() {
    echo "removing legacy files"
    rm "/usr/local/bin/fw-fanctrl" 2> "/dev/null" || true
    rm "/usr/local/bin/ectool" 2> "/dev/null" || true
    rm "/usr/local/bin/fanctrl.py" 2> "/dev/null" || true
    rm "/etc/systemd/system/fw-fanctrl.service" 2> "/dev/null" || true
    rm "$DEST_DIR$PREFIX_DIR/bin/fw-fanctrl" 2> "/dev/null" || true
}

function uninstall() {
    if [ "$SHOULD_PRE_UNINSTALL" = true ]; then
        ./pre-uninstall.sh "$([ "$NO_SUDO" = true ] && echo "--no-sudo")"
    fi
    # remove program services based on the services present in the './services' folder
    echo "removing services"
    for SERVICE in $SERVICES ; do
        SERVICE=$(sanitizePath "$SERVICE")
        # be EXTRA CAREFUL about the validity of the paths (dont wanna delete something important, right?... O_O)
        rm -rf "$DEST_DIR$PREFIX_DIR/lib/systemd/system/$SERVICE$SERVICE_EXTENSION"
    done

    # remove program services sub-configurations based on the sub-configurations present in the './services' folder
    echo "removing services sub-configurations"
    for SERVICE in $SERVICES_SUBCONFIGS ; do
        SERVICE=$(sanitizePath "$SERVICE")
        echo "removing sub-configurations for [$SERVICE]"
        SUBCONFIGS="$(cd "$SERVICES_DIR/$SERVICE" && find . -mindepth 1 -type f)"
        for SUBCONFIG in $SUBCONFIGS ; do
            SUBCONFIG=$(sanitizePath "$SUBCONFIG")
            echo "removing '$DEST_DIR$PREFIX_DIR/lib/systemd/$SERVICE/$SUBCONFIG'"
            rm -rf "$DEST_DIR$PREFIX_DIR/lib/systemd/$SERVICE/$SUBCONFIG" 2> "/dev/null" || true
        done
    done

    if [ "$NO_PIP_INSTALL" = false ]; then
        echo "uninstalling python package"
        python -m pip uninstall -y fw-fanctrl 2> "/dev/null" || true
    fi

    ectool autofanctrl 2> "/dev/null" || true # restore default fan manager
    if [ "$SHOULD_INSTALL_ECTOOL" = true ]; then
        rm "$DEST_DIR$PREFIX_DIR/bin/ectool" 2> "/dev/null" || true
    fi
    rm -rf "$DEST_DIR$SYSCONF_DIR/fw-fanctrl" 2> "/dev/null" || true
    rm -rf "/run/fw-fanctrl" 2> "/dev/null" || true

    uninstall_legacy
}

function install() {
    uninstall_legacy

    rm -rf "$TEMP_FOLDER"
    mkdir -p "$DEST_DIR$PREFIX_DIR/bin"
    if [ "$SHOULD_INSTALL_ECTOOL" = true ]; then
        mkdir "$TEMP_FOLDER"
        installEctool "$TEMP_FOLDER" || (echo "an error occurred when installing ectool." && echo "please check your internet connection or consider installing it manually and using --no-ectool on the installation script." && exit 1)
        rm -rf "$TEMP_FOLDER"
    fi
    mkdir -p "$DEST_DIR$SYSCONF_DIR/fw-fanctrl"

    build

    if [ "$NO_PIP_INSTALL" = false ]; then
        echo "installing python package"
        python -m pip install --prefix="$DEST_DIR$PREFIX_DIR" dist/*.tar.gz
        which python
        actual_installation_path="$(which 'fw-fanctrl' 2>/dev/null)"
        if [[ $? -eq 0 ]]; then
            PYTHON_SCRIPT_INSTALLATION_PATH="$actual_installation_path"
        fi
        rm -rf "dist/" 2> "/dev/null" || true
    fi

    echo "script installation path is '$PYTHON_SCRIPT_INSTALLATION_PATH'"

    cp -pn "./src/fw_fanctrl/_resources/config.json" "$DEST_DIR$SYSCONF_DIR/fw-fanctrl" 2> "/dev/null" || true
    cp -f "./src/fw_fanctrl/_resources/config.schema.json" "$DEST_DIR$SYSCONF_DIR/fw-fanctrl" 2> "/dev/null" || true

    # add --no-battery-sensors flag to the fanctrl service if specified
    if [ "$NO_BATTERY_SENSOR" = true ]; then
        NO_BATTERY_SENSOR_OPTION="--no-battery-sensors"
    fi

    # create program services based on the services present in the './services' folder
    echo "creating '$DEST_DIR$PREFIX_DIR/lib/systemd/system'"
    mkdir -p "$DEST_DIR$PREFIX_DIR/lib/systemd/system"
    echo "creating services"
    for SERVICE in $SERVICES ; do
        SERVICE=$(sanitizePath "$SERVICE")
        if [ "$SHOULD_PRE_UNINSTALL" = true ] && [ "$(systemctl is-active "$SERVICE")" == "active" ]; then
            echo "stopping [$SERVICE]"
            systemctl stop "$SERVICE"
        fi
        echo "creating '$DEST_DIR$PREFIX_DIR/lib/systemd/system/$SERVICE$SERVICE_EXTENSION'"
        cat "$SERVICES_DIR/$SERVICE$SERVICE_EXTENSION" | sed -e "s/%PYTHON_SCRIPT_INSTALLATION_PATH%/${PYTHON_SCRIPT_INSTALLATION_PATH//\//\\/}/" | sed -e "s/%SYSCONF_DIRECTORY%/${SYSCONF_DIR//\//\\/}/" | sed -e "s/%NO_BATTERY_SENSOR_OPTION%/${NO_BATTERY_SENSOR_OPTION}/" | tee "$DEST_DIR$PREFIX_DIR/lib/systemd/system/$SERVICE$SERVICE_EXTENSION" > "/dev/null"
    done

    # add program services sub-configurations based on the sub-configurations present in the './services' folder
    echo "adding services sub-configurations"
    for SERVICE in $SERVICES_SUBCONFIGS ; do
        SERVICE=$(sanitizePath "$SERVICE")
        echo "adding sub-configurations for [$SERVICE]"
        SUBCONFIG_FOLDERS="$(cd "$SERVICES_DIR/$SERVICE" && find . -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)"
        # ensure folders exists
        mkdir -p "$DEST_DIR$PREFIX_DIR/lib/systemd/$SERVICE"
        for SUBCONFIG_FOLDER in $SUBCONFIG_FOLDERS ; do
            SUBCONFIG_FOLDER=$(sanitizePath "$SUBCONFIG_FOLDER")
            echo "creating '$DEST_DIR$PREFIX_DIR/lib/systemd/$SERVICE/$SUBCONFIG_FOLDER'"
            mkdir -p "$DEST_DIR$PREFIX_DIR/lib/systemd/$SERVICE/$SUBCONFIG_FOLDER"
        done
        SUBCONFIGS="$(cd "$SERVICES_DIR/$SERVICE" && find . -mindepth 1 -type f)"
        # add sub-configurations
        for SUBCONFIG in $SUBCONFIGS ; do
            SUBCONFIG=$(sanitizePath "$SUBCONFIG")
            echo "adding '$DEST_DIR$PREFIX_DIR/lib/systemd/$SERVICE/$SUBCONFIG'"
            cat "$SERVICES_DIR/$SERVICE/$SUBCONFIG" | sed -e "s/%PYTHON_SCRIPT_INSTALLATION_PATH%/${PYTHON_SCRIPT_INSTALLATION_PATH//\//\\/}/" | tee "$DEST_DIR$PREFIX_DIR/lib/systemd/$SERVICE/$SUBCONFIG" > "/dev/null"
            chmod +x "$DEST_DIR$PREFIX_DIR/lib/systemd/$SERVICE/$SUBCONFIG"
        done
    done
    if [ "$SHOULD_POST_INSTALL" = true ]; then
        ./post-install.sh --dest-dir "$DEST_DIR" --sysconf-dir "$SYSCONF_DIR" "$([ "$NO_SUDO" = true ] && echo "--no-sudo")"
    fi
}

function installEctool() {
    workingDirectory=$1
    echo "installing ectool"

    ectoolDestPath="$DEST_DIR$PREFIX_DIR/bin/ectool"

    ectoolJobId="$(cat './fetch/ectool/linux/gitlab_job_id')"
    ectoolSha256Hash="$(cat './fetch/ectool/linux/hash.sha256')"

    artifactsZipFile="$workingDirectory/artifact.zip"

    echo "downloading artifact from gitlab"
    curl -s -S -o "$artifactsZipFile" -L "https://gitlab.howett.net/DHowett/ectool/-/jobs/${ectoolJobId}/artifacts/download?file_type=archive" || (echo "failed to download the artifact." && return 1)
    if [[ $? -ne 0 ]]; then return 1; fi

    echo "checking artifact sha256 sum"
    actualEctoolSha256Hash=$(sha256sum "$artifactsZipFile" | cut -d ' ' -f 1)
    if [[ "$actualEctoolSha256Hash" != "$ectoolSha256Hash" ]]; then
        echo "Incorrect sha256 sum for ectool gitlab artifact '$ectoolJobId' : '$ectoolSha256Hash' != '$actualEctoolSha256Hash'"
        return 1
    fi

    echo "extracting artifact"
    {
        unzip -q -j "$artifactsZipFile" '_build/src/ectool' -d "$workingDirectory" &&
        cp "$workingDirectory/ectool" "$ectoolDestPath" &&
        chmod +x "$ectoolDestPath"
    } || (echo "failed to extract the artifact to its designated location." && return 1)
    if [[ $? -ne 0 ]]; then return 1; fi

    echo "ectool installed"
}

if [ "$SHOULD_REMOVE" = true ]; then
    uninstall
else
    install
fi
exit 0
