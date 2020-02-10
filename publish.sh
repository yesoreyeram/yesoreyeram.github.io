#!/bin/sh

echo "Update build";
echo $(date) > LAST_UPDATED

echo "Publishing";
git config --global user.email "actions@github.com"
git config --global user.name "Github Actions"
git add .
git commit -m "Github Pages deploy by Github Actions"
git push
git status

exit 0;
