#!/bin/bash

logFile=/Library/Application\ Support/com.laratech.NC_DNS_Updater/package.log
daemonFile=/Library/LaunchDaemons/com.laratech.nc_dns_updater_daemon.plist
oldDbFile=~/Library/Application\ Support/com.laratech.NC_DNS_Updater/NC_DNS_Updater.storedata
newDbFile=/Library/Application\ Support/com.laratech.NC_DNS_Updater/NC_DNS_Updater.storedata

exec 1<&-
exec 2<&-
exec 1>>"$logFile"
exec 2>&1

if [ -f "$daemonFile" ]; then
	echo "Attempting to unload daemon."
	sudo launchctl unload /Library/LaunchDaemons/com.laratech.nc_dns_updater_daemon.plist
fi


if [ -f "$oldDbFile" ]; then
	echo "Old DB file exists."
	if [ -f "$newDbFile" ]; then
		echo "New DB file exists."
		echo "Deleting new DB file."
		sudo rm "$newDbFile"
		echo "Applying permissions to old DB file."
		sudo chmod 777 "$oldDbFile"
		echo "Copying old DB file."
		sudo cp "$oldDbFile" "$newDbFile"
	fi 
else
	echo "Old DB file does not exist!"
fi

sudo chmod 777 /Library/Application\ Support/com.laratech.NC_DNS_Updater
sudo chmod 777 /Library/Application\ Support/com.laratech.NC_DNS_Updater/nc_dns_updater.log
sudo chmod 777 "$newDbFile"
sudo launchctl load "$daemonFile"
sudo sleep 22
sudo launchctl unload "$daemonFile"
sudo chmod 777 "$newDbFile"
sudo launchctl load "$daemonFile"
