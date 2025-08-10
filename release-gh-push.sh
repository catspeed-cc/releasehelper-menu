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
echo "## sd-webui-reforge-docker - github-pushsh script initiated"
echo "##"
echo "## commit / push to remote"
echo "##"
echo "#"

# Source the shared functions
source ${GIT_ROOT}/docker/lib/commonlib.sh

while true; do
  # Prompt for -a (commit description / title)
  echo -n "💬 Enter commit description (-a): "
  read -r commit_desc

  # Validate non-empty -a
  if [[ -z "$commit_desc" ]]; then
    echo "⚠️  Commit description (-a) cannot be empty. Please try again."
    echo
    continue
  fi

  # Prompt for -m (commit message / body)
  echo -n "✍️  Enter commit message (-m, or press Enter to use same as -a): "
  read -r commit_msg

  # If -m is empty, use -a value
  if [[ -z "$commit_msg" ]]; then
    commit_msg="$commit_desc"
    echo "🔁 Using description as message: \"$commit_msg\""
  fi

  # Show final commit info
  echo
  echo "✅ Commit Ready:"
  echo "   -a: \"$commit_desc\""
  echo "   -m: \"$commit_msg\""
  echo
            
  confirm_continue            
            
  # Example action (uncomment to actually commit)
  git commit -a -m "$commit_desc" -m "$commit_msg"
  echo "📤 Committed!"

  # Optional: confirm before continuing
  while true; do
    echo -n "🔁 Run another commit? (y/N): "
    read -r again
    case "${again}" in
      [Yy]) break ;;
      ""|[Nn]) 
        echo "👋 Done."
        exit 0
        ;;
      *) echo "Please enter 'y' or 'n'." ;;
    esac
  done
  echo
done   

# push to github loop       
       
while true; do
  echo -n "Push all commits to GitHub? (N/y): "
  read -r response

  case "${response}" in
    [Yy])
      echo "Pushing commits to remote..."         
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
