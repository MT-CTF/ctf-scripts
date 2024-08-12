#!/bin/bash

if [[ $(/usr/bin/id -u) == 0 ]]; then
	echo "Please don't run with sudo or as root"
	exit
fi

cd $(dirname -- "${BASH_SOURCE[0]}") # Change to the directory this script is in

# y/n code from https://stackoverflow.com/a/226724
echo "Are you sure you want to set up a CTF server with the user '$USER'?"
echo "Note: You will need to ssh into this user directly or the system service setup will fail"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) break;;
		No ) exit; break;;
	esac
done

if ! [[ -d ~/capture_the_flag/ ]]; then
	mkdir ~/capture_the_flag/
fi

echo ""
echo "Please enter a technical name for this new ctf server (e.g main)."
echo "It will only be used by the management scripts"

read -p "> " instance_name
while [ -d ~/capture_the_flag/$instance_name ]; do
	echo "A server is already set up with that name. Please enter a different one."
	read -p "> " instance_name
done

echo ""

if ! [[ -d ~/minetest/ ]]; then
	echo "This user doesn't have Minetest set up. You can run setup_minetest.sh to fix that"
	exit
fi

# Install CTF if it isn't yet
if ! [[ -d ~/minetest/games/capturetheflag/ ]]; then
	git -C ~/minetest/games/ clone --recursive https://github.com/MT-CTF/capturetheflag.git

	echo ""
	read -p "Press any key to continue"
	clear -x && sleep 1
fi

# Set up capture_the_flag folder for server
path=$HOME/capture_the_flag/$instance_name

mkdir $path/

setup_redis=false
# y/n code from https://stackoverflow.com/a/226724
echo "Do you want to use redis for your rankings backend?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) setup_redis=true; break;;
		No ) break;;
	esac
done

if [[ $setup_redis == true ]]; then
	sudo apt install luarocks redis
	sudo luarocks --lua-version 5.1 install luaredis

	echo ""
	echo "The ctf_rankings settings can be edited in $path/minetest.conf after you finish setting it up"

	read -p "Press any key to continue"
	clear -x && sleep 1
fi

minetest_conf=true
# y/n code from https://stackoverflow.com/a/226724
echo "Do you want to use a premade minetest.conf as a base for your config?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) break;;
		No )
			touch $path/minetest.conf
			echo "You can find the server's minetest.conf at $path/minetest.conf"
			echo ""
			minetest_conf=false
			break;;
	esac
done


if [[ $minetest_conf == true ]]; then

	clear -x && sleep 1

	port=30000

	if [ -f ~/capture_the_flag/next_port.txt ]; then
		port=$(<~/capture_the_flag/next_port.txt)
	fi

	echo "Setting up minetest.conf for $instance_name..."

	echo "name=ADMIN" > $path/minetest.conf # If there is an existing file it'll be overwritten instead of appended to

	#
	# Address and server list
	#
	printf "\n#\n# Address and server list\n#\n\n" >> $path/minetest.conf

	public_server=true
	# y/n code from https://stackoverflow.com/a/226724
	echo "Do you plan to announce the server to the serverlist? (server_announce | required)"
	select yn in "Yes" "No"; do
		case $yn in
			Yes ) echo "server_announce = true"  >> $path/minetest.conf; break;;
			No ) echo "server_announce = false" >> $path/minetest.conf; public_server=false; break;;
		esac
	done

	if [[ $public_server == true ]]; then
		echo "server_address = " >> $path/minetest.conf

		echo "# port was auto-filled based on $HOME/capture_the_flag/next_port.txt:" >> $path/minetest.conf
		echo "port = $port" >> $path/minetest.conf
		echo "$(($port + 1))" > ~/capture_the_flag/next_port.txt

		echo "server_name = " >> $path/minetest.conf

		echo "#server_url = <url>" >> $path/minetest.conf

		echo "server_description = " >> $path/minetest.conf
	fi

	echo "#motd = " >> $path/minetest.conf

	echo "max_users = 20" >> $path/minetest.conf

	echo "#disallow_empty_password = " >> $path/minetest.conf

	echo "#strict_protocol_version_checking = " >> $path/minetest.conf

	echo "#protocol_version_min = " >> $path/minetest.conf

	#
	# Gameplay
	#
	printf "\n#\n# Gameplay\n#\n\n" >> $path/minetest.conf

	echo "#default_privs = " >> $path/minetest.conf

	echo "#basic_privs = " >> $path/minetest.conf

	echo "" >> $path/minetest.conf

	echo "# Mapedit mode is activated when creative_mode=true. That is the only time you can use a mapgen other than singlenode" >> $path/minetest.conf
	echo "creative_mode = false" >> $path/minetest.conf
	echo "mg_name = singlenode"  >> $path/minetest.conf

	#
	# Trusted Mods
	#
	printf "\n#\n# Trusted Mods\n#\n\n" >> $path/minetest.conf

	if [[ $setup_redis == true ]]; then
		echo "secure.trusted_mods = ctf_rankings" >> $path/minetest.conf
		echo "" >> $path/minetest.conf
		echo "ctf_rankings_backend = redis" >> $path/minetest.conf
		echo "ctf_rankings_redis_server_port = 6379" >> $path/minetest.conf
	else
		echo "#secure.trusted_mods = " >> $path/minetest.conf
	fi

	#
	# Misc Settings
	#
	printf "\n#\n# Misc Settings\n#\n\n" >> $path/minetest.conf

	echo "#strip_color_codes = " >> $path/minetest.conf

	echo "#dedicated_server_step = " >> $path/minetest.conf

	#
	# Profiler
	#
	printf "\n#\n# Profiler\n#\n\n" >> $path/minetest.conf

	echo "#profiler.load = " >> $path/minetest.conf

	echo "Done"
	echo ""
	read -p "The minetest.conf will now be opened in nano so you can put in the necessary info. Press any key to continue"

	nano $path/minetest.conf;

	clear -x && sleep 1

	echo "The server's minetest.conf has been set up! You can find it at $path/minetest.conf"
	echo "Once you start the server for the first time you will need to log in as 'ADMIN' to claim the admin account for this server"
	echo ""
fi

echo "This is what the systemd service file for running your server will contain:"
echo ""

echo "[Unit]"                                                             >> $path/ctf_server_$instance_name.service
echo "Description=Service for the CaptureTheFlag server '$instance_name'" >> $path/ctf_server_$instance_name.service
echo "StartLimitIntervalSec=120"                                          >> $path/ctf_server_$instance_name.service
echo "StartLimitBurst=3"                                                  >> $path/ctf_server_$instance_name.service
echo "After=network.target"                                               >> $path/ctf_server_$instance_name.service
echo ""                                                                   >> $path/ctf_server_$instance_name.service
echo "[Service]"                                                          >> $path/ctf_server_$instance_name.service
echo "Type=simple"                                                        >> $path/ctf_server_$instance_name.service
echo "ExecStart=/bin/bash $path/start_server.sh"                          >> $path/ctf_server_$instance_name.service
echo "Restart=always"                                                     >> $path/ctf_server_$instance_name.service
echo "LimitCORE=infinity"                                                 >> $path/ctf_server_$instance_name.service
echo ""                                                                   >> $path/ctf_server_$instance_name.service
echo "[Install]"                                                          >> $path/ctf_server_$instance_name.service
echo "WantedBy=default.target"                                            >> $path/ctf_server_$instance_name.service

cat $path/ctf_server_$instance_name.service

echo ""

# y/n code from https://stackoverflow.com/a/226724
echo "Do you want to make changes to the service file before using it?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) nano $path/ctf_server_$instance_name.service; break;;
		No ) break;;
	esac
done

read -p "Next step: Setting up the service. Press any key to continue"
echo ""

mkdir -p ~/.config/systemd/user/
cp $path/ctf_server_$instance_name.service ~/.config/systemd/user/

printf "Run the following command to turn on the systemd service:\n" >> $path/service_startup.txt;
echo   "    systemctl --user enable ctf_server_$instance_name" >> $path/service_startup.txt;
printf "\nRun the following command to off the systemd service:\n" >> $path/service_startup.txt;
echo   "    systemctl --user disable ctf_server_$instance_name" >> $path/service_startup.txt;
printf "\n\nRun the following command to update the service file after editing it:\n" >> $path/service_startup.txt;
echo   "    cp $path/ctf_server_$instance_name.service ~/.config/systemd/user/ && systemctl --user daemon-reload"

# y/n code from https://stackoverflow.com/a/226724
echo "Do you want this server to start when the host machine does? (e.g, after a VPS restart)"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) systemctl --user enable ctf_server_$instance_name; break;;
		No ) break;;
	esac
done
echo "If you change your mind later see $path/service_startup.txt"
echo ""

printf "Run the following command to start the ctf server (It should automatically restart if the minetest server crashes or is shutdown):\n" >> $path/service_startstop.txt;
echo   "    systemctl --user start ctf_server_$instance_name" >> $path/service_startstop.txt;
printf "\nRun the following command to force-stop the ctf server and prevent automatic restarts:\n" >> $path/service_startstop.txt;
echo   "    systemctl --user stop ctf_server_$instance_name" >> $path/service_startstop.txt;

echo "See $path/service_startstop.txt for instructions on starting/stopping the service"

read -p "Press any key to continue"

mkdir $path/logs/

echo "#!/bin/bash" | tee $path/update_server.sh > $path/start_server.sh
echo ""            | tee $path/update_server.sh > $path/start_server.sh

# y/n code from https://stackoverflow.com/a/226724
echo "Do you want to report crashes/update info to a Discord webhook?"
select yn in "Yes" "No"; do
	case $yn in
		Yes )
			echo "REPORT_DISCORD=true" | tee -a $path/update_server.sh >> $path/start_server.sh

			read -p "Please enter the webhook url: " url
			echo "WEBHOOK_URL=\"$url\"" | tee -a $path/update_server.sh >> $path/start_server.sh

			if ! [[ "$(sudo dpkg-query -l python3)" ]]; then
				read -p "python3 doesn't seem to be installed. Press any key to attempt installing it with apt"

				sudo apt update
				sudo apt install python3
			fi

			break;;
		No )
			echo "REPORT_DISCORD=false" | tee -a $path/update_server.sh >> $path/start_server.sh
			break;;
	esac
done
echo "" | tee -a $path/update_server.sh >> $path/start_server.sh

echo "LOG_PATH=\"$path/logs\""                                        >> $path/start_server.sh
echo ""                                                               >> $path/start_server.sh
echo "SERVER_NAME=\"$instance_name\"" | tee -a $path/update_server.sh >> $path/start_server.sh
echo "SERVER_PATH=\"$path\""                                          >> $path/start_server.sh
echo ""                                                               >> $path/start_server.sh

cat ./serverscripts/server_script.sh.part >> $path/start_server.sh

cat ./serverscripts/server_update.sh.part >> $path/update_server.sh

chmod +x $path/start_server.sh
chmod +x $path/update_server.sh

# pre-create the world folder
mkdir $path/world/

echo "The server files are at $path/"
echo "Remember to set the map backend to dummy if this isn't a map making server"