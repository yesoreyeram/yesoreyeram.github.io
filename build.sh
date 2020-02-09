#!/bin/sh

echo "Install Dependencies";
yarn install --frozen-lockfile;

echo "Cleanup";
rm -rf .staging/;
rm -rf assets/;
rm -rf blog/;
rm *.html;

echo "Building sriramajeyam.com";
yarn build;

echo "Deploy";
cp -r .staging/* .;

echo "Post build cleanup";
rm -rf .staging/;

exit 0;
