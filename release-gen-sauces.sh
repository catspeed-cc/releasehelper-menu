#!/usr/bin/env bash

# LOCAL ONLY - DO NOT PUSH TO REPOSITORY!

# STILL needed: this is a fallback
# Function to find the Git root directory, ascending up to 6 levels
# Required for source line to be accurate and work from all locations
find_git_root() {
    local current_dir="$(pwd)"
    local max_levels=6
    local level=0
    local dir="$current_dir"

    while [[ $level -le $max_levels ]]; do
        if [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        # Go up one level
        dir="$(dirname "$dir")"
        # If we've reached the root (e.g., /), stop early
        if [[ "$dir" == "/" ]] || [[ "$dir" == "//" ]]; then
            break
        fi
        ((level++))
    done

    echo "Error: .git directory not found within $max_levels parent directories." >&2
    return 1
}

find_project_root() {

  export PROJECT_ROOT=""
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Check if we are inside the 'docker' directory (current path contains /docker)
  if [[ "$PWD" == *"/docker" || "$PWD" == *"/docker/"* ]] && \
     [[ -d "./sauce_scripts" && \
        -d "./compose_files" && \
        -d "./sauce_scripts_baked_into_docker_image" && \
        -f "./compose_files/docker-compose.yaml" ]]; then
      # Confirmed: we are in the correct docker/ directory
      echo "✅ Running inside valid docker/ directory."
      export PROJECT_ROOT="$(dirname "$PWD")"
    
  # Last resort: check if we can find commonlib.sh relative to current location
  elif [[ -f "./docker/lib/commonlib.sh" ]]; then
    echo "✅ Found docker/lib/commonlib.sh — assuming current directory is project root."
    export PROJECT_ROOT="$PWD"
  fi

  # Attempt to detect Git root
  export GIT_ROOT=$(find_git_root)

  # Nested logic: decide PROJECT_ROOT and validate everything in one flow
  if [[ -n "$GIT_ROOT" && -d "$GIT_ROOT" && -f "$GIT_ROOT/docker/lib/commonlib.sh" ]]; then
    # Git root is valid AND points to a real SD-Forge project
    export PROJECT_ROOT="$GIT_ROOT"
  else
    # No valid Git root — rely on existing PROJECT_ROOT
    # If PROJECT_ROOT unset or empty AND directory does not exist
    if [[ ! -n "$PROJECT_ROOT" && ! -d "$PROJECT_ROOT" ]]; then
        export GIT_ROOT="error"
        export PROJECT_ROOT="error"
    else
      # OVERRIDE GIT_ROOT
      GIT_ROOT=$PROJECT_ROOT
    fi   
  fi
  
  echo "📁 Git root set to: $GIT_ROOT"
  echo "📁 Project root set to: $PROJECT_ROOT" 

}

# find the GIT_ROOT or PROJECT_ROOT (set both variables, source common config first time)
find_project_root

# safely test for commonlib/commoncfg and attempt sourcing it :)
if [[ -f "$GIT_ROOT/docker/lib/commonlib.sh" && -f "$GIT_ROOT/docker/lib/commoncfg.sh" ]]; then
  # source the library
  if ! source "$GIT_ROOT/docker/lib/commonlib.sh"; then
    echo "❌ Failed to source commonlib.sh." >&2
    echo "   Found Git-controlled SD-Forge repo or valid PROJECT_ROOT but failed to source critical libs." >&2
    echo "   Check sauces archive is installed in project root." >&2
    echo "   Consult README.md custom/cutdown install or file catspeed-cc issue ticket." >&2
    exit 1
  fi
  # source the config
  if ! source "$GIT_ROOT/docker/lib/commoncfg.sh"; then
    echo "❌ Failed to source commoncfg.sh." >&2
    echo "   Found Git-controlled SD-Forge repo or valid PROJECT_ROOT but failed to source critical libs." >&2
    echo "   Check sauces archive is installed in project root." >&2
    echo "   Consult README.md custom/cutdown install or file catspeed-cc issue ticket." >&2
    exit 1
  fi
fi

echo "#"
echo "##"
echo "## sd-webui-reforge-docker - github-create-sauces-release.sh <v*.*.*> script initiated"
echo "##"
echo "## create a sauces.tar.gz (Ex: './github-create-sauces-release.sh v1.1.1')"
echo "##"
echo "#"

# Source the shared functions
source ${GIT_ROOT}/docker/lib/commonlib.sh

# Infinite loop to get version or use timestamp
while true; do
  echo
  read -r -p "Enter version (e.g. v1.2.3) or press Enter for timestamp: " VERSION_INPUT

  if [[ -z "$VERSION_INPUT" ]]; then
    # Use timestamp if input is empty
    export FILE_PREFIX=$(date "+%Y-%m-%d_%H-%M-%S_%Z")
    echo
    echo "📅 Using timestamp: $FILE_PREFIX"
    break
  elif [[ "$VERSION_INPUT" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    # Valid version format: v1.2.3 or v1.2.3-beta.1
    export FILE_PREFIX="$VERSION_INPUT"
    echo
    echo "🔖 Using version: $FILE_PREFIX"
    break
  else
    # Invalid input
    echo
    echo "❌ Invalid format. Please use 'vX.Y.Z' (e.g. v1.0.0)."
    echo "   You can also press Enter to use a timestamp."
    # Loop continues
  fi
done

echo "Prefix is: $FILE_PREFIX"
# We just showed user the prefix, throw a confirmation loop
confirm_continue

# change to script directory
cd $WORK_DIR

# clean the work directory
rm -r $WORK_DIR/*

# copy the menu script
cp ../${CURRENT_FORK}-menu.sh ./

# copy the docker/ dir
cp -r ../docker/ ./

# create the mounted volume directories
# subdirs will be populated by the first run
mkdir -p outputs
mkdir -p models

rm -rf ./docker/sauces_dl

rm -rf ./docker/compose_files/*~
rm -rf ./docker/sauce_scripts/*~
rm -rf ./docker/sauce_scripts_baked_into_docker_image/*~
rm -rf ./docker/lib/*~

echo
echo "Sauce directory structure finalized (BELOW)..."
echo "Please confirm it looks OK and continue..."
echo
echo "ONLY CONTINUE IF YOU WANT SAUCE ARCHIVE CREATED!"
echo

echo
echo "Listing of $WORK_DIR"
echo
tree $WORK_DIR

echo
echo "Sauce directory structure finalized (ABOVE)..."
echo "Please confirm it looks OK and continue..."
echo
echo "ONLY CONTINUE IF YOU WANT SAUCE ARCHIVE CREATED!"
echo

# We just asked user to confirm sauce directory is OK, throw a confirmation loop
confirm_continue

# create the archive
tar cfz ./${FILE_PREFIX}-sauce.tar.gz ./*

# Create our MD5SUM
md5sum ./${FILE_PREFIX}-sauce.tar.gz > ./${FILE_PREFIX}-sauce.tar.gz.md5

rm -rf ./docker

# Clean up the work dir
find "${WORK_DIR}" -mindepth 1 \
    ! -name "${FILE_PREFIX}-sauce.tar.gz" \
    ! -name "${FILE_PREFIX}-sauce.tar.gz.md5" \
    ! -name ".git" \
    -delete

echo
echo "Listing of $WORK_DIR"
echo
# Show the user :)
tree $WORK_DIR

echo "Done."
echo
echo "Do you want to move the sauce archive [${FILE_PREFIX}-sauce.tar.gz] to sauces/ ?"
echo "WARNING: this WILL overwrite a sauce archive with the same name"
echo

# We just asked user to confirm move sauce archive to sauces/, throw a confirmation loop
confirm_continue

# clear old sauces if exist
rm -rf $SAUCE_DL_DIR/${FILE_PREFIX}-sauce.tar.gz*

# MOVE IT ALL TO SAUCES/
mv $WORK_DIR/${FILE_PREFIX}-sauce.tar.gz* $SAUCE_DL_DIR

echo
echo "Listing of $SAUCE_DL_DIR"
echo
ls -al $SAUCE_DL_DIR/*.tar.gz*

echo
echo "MD5: " . $(cat $SAUCE_DL_DIR/${FILE_PREFIX}-sauce.tar.gz.md5)

echo

echo "Sauce archive creation completed!"
echo "Confirm your sauce file exists"
echo 
