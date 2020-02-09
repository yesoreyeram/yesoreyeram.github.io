#!/bin/sh

echo "Publishing";
git config --global user.email "actions@github.com"
git config --global user.name "Github Actions"
git add .
git commit -m "Deploy by Github Actions"
git push
git status

exit 0;
