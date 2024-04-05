#!/bin/bash

if [[ $(/usr/bin/id -u) == 0 ]]; then
	echo "Please don't run with sudo or as root"
	exit
fi

sudo apt update

# Misc deps
sudo apt install git

# Minetest deps
sudo apt install g++ make libc6-dev cmake libpng-dev libjpeg-dev libxi-dev libgl1-mesa-dev libsqlite3-dev libogg-dev libvorbis-dev libopenal-dev libcurl4-gnutls-dev libfreetype6-dev zlib1g-dev libgmp-dev libjsoncpp-dev libzstd-dev gettext libsdl2-dev

if [ -d "$HOME/minetest/" ]; then
	git -C ~/minetest/ pull -r

	if [ -f "$HOME/minetest/misc/irrlichtmt_tag.txt" ]; then
		git -C ~/minetest/lib/irrlichtmt/ pull -r
		git -C ~/minetest/lib/irrlichtmt/ checkout "origin/$(cat ~/minetest/misc/irrlichtmt_tag.txt)"
	fi
else
	git -C ~ clone --depth 1 https://github.com/minetest/minetest.git

	read -p "Press any key to continue"

	if [ -f "$HOME/minetest/misc/irrlichtmt_tag.txt" ]; then
		git -C ~ clone --depth 1 --branch "$(cat ~/minetest/misc/irrlichtmt_tag.txt)" https://github.com/minetest/irrlicht.git ~/minetest/lib/irrlichtmt
	fi
fi

if [ -d "$HOME/luajit/" ]; then
	git -C ~/luajit/ pull -r
else
	git -C ~ clone https://luajit.org/git/luajit.git
fi

make -C ~/luajit/ -j $(nproc) && sudo make -C ~/luajit/ -j $(nproc) install

echo
echo "Run compile_minetest.sh to compile"
