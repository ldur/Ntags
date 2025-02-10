#!/bin/bash

# Check if a commit message was provided
if [ -z "$1" ]; then
  echo "Error: No commit message provided."
  echo "Usage: ./commit.sh \"Your commit message\""
  exit 1
fi

# Store the commit message
COMMIT_MESSAGE=$1

# Navigate to the project directory (optional, adjust the path if needed)
# cd /path/to/your/Ntags/project

# Add all changes to git
git add .

# Commit the changes with the provided message
git commit -m "$COMMIT_MESSAGE"

# Push changes to the remote repository
git push origin main

# Check if push was successful
if [ $? -eq 0 ]; then
  echo "Successfully pushed to GitHub with message: '$COMMIT_MESSAGE'"
else
  echo "Error: Failed to push to GitHub."
fi

