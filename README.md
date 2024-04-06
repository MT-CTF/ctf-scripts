# ctf-scripts __**USE AT YOUR OWN RISK**__
LandarVargan's scripts/notes for setting up/running a CTF server.

Don't run anything unless you know exactly what you and the script are doing.
The goal is to make this reliable and usable by less tech-savvy users, but the day that becomes a reality is a LONG way off

## Minetest user setup, script download (assumes root user)
* `sudo apt update && sudo apt install git`
* `sudo useradd -s /bin/bash -m -G sudo minetest`
* `su minetest && cd ~`
* `git clone https://github.com/MT-CTF/ctf-scripts.git && cd ctf-scripts/ && chmod +x *.sh`