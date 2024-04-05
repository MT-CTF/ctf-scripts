#!/bin/sh

# Code from https://unix.stackexchange.com/a/89760

# Validate arguments
if [ $# -lt 1 ]; then
	echo "A list of one or more paths is required."
	exit 1
fi

# Checks if a path exists and can be moved.
checkPath () {
	if [ ! -e "$1" ]; then
		echo "'$1' does not exist."
		return 1;
	fi
	if [ ! -w "$1" ]; then
		echo "Cannot move '$1', permission denied."
		return 1;
	fi
	return 0;
}

# Finds a new path with numerical suffix.
getName () {
	suf=0;
	while [ -e "$1.$suf" ]
		do let suf+=1
	done
	Dest=$1.$suf
}

# Loop through arguments -- use quotes to allow spaces in paths.
while (($#)); do
	Src=$1
	Dest=$1
	shift
	checkPath "$Src"
	if [ $? -eq 0 ]; then
		getName "$Src"
		mv "$Src" "$Dest"
	fi
done