#!/bin/sh

echo "Building sriramajeyam.com";

yarn build;

rm -rf  assets/;
rm -rf posts/;
rm *.html;

cp -r docs/* .;

rm -rf docs/;

exit 0;
