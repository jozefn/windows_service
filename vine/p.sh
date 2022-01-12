#!/bin/bash
cd vine_project
./process.sh
cd ../
/bin/sh ~/rmv.sh
./prep_vine.pl -b
ls ~/smove.sh > /dev/null 2>&1
status=$?
if [[ $status != 0 ]]; then
    echo "no more files"
    exit 1
fi
/bin/sh ~/smove.sh
