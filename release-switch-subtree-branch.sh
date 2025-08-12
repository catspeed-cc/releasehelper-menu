#!/bin/bash

# switch-subtree-docker.sh
# Interactively switch the docker subtree to a branch
# Assumes remote name: subtree-docker-full-dir
# Designed for use in releasehelper-menu

set -euo pipefail

# Configuration — customize per subtree
PREFIX="docker"                            # Where to pull into
REMOTE="subtree-docker-full-dir"          # Git remote name
REPO_PURPOSE="Docker configuration"       # For display only

echo "🔄 Git Subtree Switcher"
echo "-------------------------------"
echo "Repository: $REPO_PURPOSE"
echo "Local path: ./$PREFIX"
echo "Remote:     $REMOTE"
echo

# Verify remote exists
if ! git remote get-url "$REMOTE" &>/dev/null; then
  echo "❌ Remote '$REMOTE' not found."
  echo "Please add it with:"
  echo "  git remote add $REMOTE /path/to/your/docker-repo"
  echo "  # or"
  echo "  git remote add $REMOTE https://github.com/you/docker-repo.git"
  exit 1
fi

# Fetch latest branches
echo -n "📡 Fetching latest from '$REMOTE'... "
if git fetch "$REMOTE"; then
  echo "done."
else
  echo "failed!"
  exit 1
fi

# Menu options
options=(
  "main - Stable release version"
  "development - Active development"
  "📦 Enter a custom branch name"
  "🚪 Cancel and exit"
)

# Display menu
echo
echo "Select a branch to pull into ./$PREFIX/:"
for i in "${!options[@]}"; do
  printf " %3s) %s\n" "$((i+1))" "${options[i]}"
done
echo

# Read choice
read -p "Choose an option [1-$((${#options[@]}))]: " choice

# Handle selection
case "$choice" in
  1)
    BRANCH="main"
    ;;
  2)
    BRANCH="development"
    ;;
  3)
    read -rp "🎯 Enter branch name: " BRANCH
    if [[ -z "$BRANCH" ]]; then
      echo "❌ No branch name entered. Aborting."
      exit 1
    fi
    ;;
  4|"")
    echo "👋 Cancelled."
    exit 0
    ;;
  *)
    echo "❌ Invalid option."
    exit 1
    ;;
esac

# Confirm
echo
echo "👉 You selected: '$BRANCH'"
read -p "✅ Pull into '$PREFIX/' now? (y/N): " -n 1 -r
echo

[[ ! $REPLY =~ ^[Yy]$ ]] && echo "👋 Aborted." && exit 0

# Safety: check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
  echo "⚠️  Warning: You have uncommitted changes in your working tree."
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && echo "👋 Aborted." && exit 0
fi

# Perform subtree pull
echo "🔽 Pulling '$REMOTE/$BRANCH' into '$PREFIX/'..."
if git subtree pull --prefix="$PREFIX" "$REMOTE" "$BRANCH" --squash; then
  echo "✅ Success! '$PREFIX/' is now synced with '$REMOTE/$BRANCH'"
else
  echo "❌ Failed to pull subtree. Check:"
  echo "   - Is the branch '$BRANCH' pushed to '$REMOTE'?"
  echo "   - Did you forget to fetch?"
  exit 1
fi