#!/usr/bin/env bash

# Capture parameter early
if [ -n "$1" ]; then
    DOCKER_TAG="$1"
else
    DOCKER_TAG=$(date "+%Y-%m-%d_%H-%M-%S_%Z")
fi

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
    echo "   Found Git-controlled sd-reForge repo or valid PROJECT_ROOT but failed to source critical libs." >&2
    echo "   Check sauces archive is installed in project root." >&2
    echo "   Consult README.md custom/cutdown install or file catspeed-cc issue ticket." >&2
    exit 1
  fi
  # source the config
  if ! source "$GIT_ROOT/docker/lib/commoncfg.sh"; then
    echo "❌ Failed to source commoncfg.sh." >&2
    echo "   Found Git-controlled sd-reForge repo or valid PROJECT_ROOT but failed to source critical libs." >&2
    echo "   Check sauces archive is installed in project root." >&2
    echo "   Consult README.md custom/cutdown install or file catspeed-cc issue ticket." >&2
    exit 1
  fi
fi

echo "#"
echo "##"
echo "## sd-webui-reforge-docker - release-build-docker.sh <tag> script initiated"
echo "##"
echo "## docker build / push to dockerhub (Ex. release-build-docker.sh bleeding)"
echo "##"
echo "#"

# Source the shared functions
source ${GIT_ROOT}/docker/lib/commonlib.sh

# logic to check which fork
if [[ "$DOCKER_SERVICE_NAME" == *"sd-forge"* ]]; then
  export FORK_ADD=sd-forge
  export REP_ADD=catspeedcc/sd-webui-forge-docker     
elif [[ "$DOCKER_SERVICE_NAME" == *"sd-reforge"* ]]; then
  export FORK_ADD=sd-reforge
  export REP_ADD=catspeedcc/sd-webui-reforge-docker
else
  echo
  echo "[Error] Unknown fork, refusing to build!"
  echo
  exit 1
fi
                   
cd ${GIT_ROOT}
                   
echo          
echo "[DEBUG] PWD: ${PWD}"                       
echo "[DEBUG] REP_ADD:[${REP_ADD}]"             
echo "[DEBUG] FORK_ADD:[${FORK_ADD}]"
echo             

confirm_continue                                  
                                               
docker build -f "./Dockerfile.${FORK_ADD}" -t "${REP_ADD}:${DOCKER_TAG}" .

while true; do
  echo -n "Push Docker image to Docker Hub? (N/y): "
  read -r response

  case "${response}" in
    [Yy])
      echo "Pushing image..."
      docker push "${REP_ADD}:${DOCKER_TAG}"
      break
      ;;
    [Nn])
      echo "Skipping push."
      break
      ;;
    *)
      echo "Please enter 'y' or 'n'."
      echo
      ;;
  esac
done

echo
echo "release operations completed"
echo
