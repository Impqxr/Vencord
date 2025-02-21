#!/usr/bin/env bash

# Script to traverse all directories in the current directory,
# change into them, and run 'git pull' if they are Git repositories.

for dir in */; do
  if [ -d "$dir" ]; then
    echo "Checking directory: $dir"
    cd "$dir" || continue

    # Check if it's a Git repository
    if [ -d ".git" ]; then
      echo "Running 'git pull' in $dir"
      git pull
    else
      echo "$dir is not a Git repository."
    fi

    # Return to the original directory
    cd ..
  fi
done

