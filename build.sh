#!/bin/sh

echo "Building sriramajeyam.com";

yarn build;

cp CNAME ./docs/CNAME;

exit 0;
