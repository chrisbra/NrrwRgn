#!/bin/sh

for i in */; do
    cd "$i"
    ./cmd.sh
    rm -f *.mod
    cd - > /dev/null
done
