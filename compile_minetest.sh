#!/bin/bash

if [[ $(/usr/bin/id -u) == 0 ]]; then
    echo "Please don't run with sudo or as root. And use the same user that you setup minetest with"
    exit
fi

cd ~/minetest/

if [ -f "$HOME/minetest/CMakeCache.txt" ]; then
    rm $HOME/minetest/CMakeCache.txt
fi

cmake . -DCMAKE_BUILD_TYPE=Release

cmake . -DRUN_IN_PLACE=TRUE -DBUILD_SERVER=TRUE -DBUILD_CLIENT=FALSE -DENABLE_LUAJIT=TRUE -DREQUIRE_LUAJIT=TRUE

echo
read -p "Press enter to continue"

make -j $(nproc)