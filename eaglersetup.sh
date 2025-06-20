echo "#####################################################################################"
echo "                            \"\"#                                  m                 "
echo "       mmm    mmm    mmmm    #     mmm    m mm   mmm    mmm   mm#mm  m   m  mmmm  "
echo "     #\"  #  \"   #  #\" \"#    #    #\"  #   #\"  \" #   \"  #\"  #    #    #   #  #\" \"# "
echo "    #\"\"\"\"  m\"\"\"#  #   #    #    #\"\"\"\"   #      \"\"\"m  #\"\"\"\"    #    #   #  #   # "
echo "   \"#mm\"  \"mm\"#  \"#m\"#    \"mm  \"#mm\"   #     \"mmm\"  \"#mm\"    \"mm  \"mm\"#  ##m#\" "
echo "                 m  #                                                   #     "
echo "                 \"\"  "
echo "2025 Melanie Pacheco, 80hd_0                                     Debian - Version 1.1"
echo "#####################################################################################"
echo "Welcome to eaglersetup! This script sets up a fully functional eaglercraft server. If you have any issues, contact me on discord, username 80hd_0."
read -p "Before we begin, type anything at all if you understand the prerequisites (requirements) for running this server. Press enter if you don't understand/know. # " understandme
if [ -z "$understandme" ]; then
	echo "Here are the prerequisites for running this program and any eaglercraft server. Anything not listed here is done for you."
	echo "REQUIRED:"
	echo "- port 25565 open/port forwarded. this is where tcp/websockets will be hosted from, in otherwords Java and Eaglercraft."
	echo "- a subdomain/domain pointed to the ip address of your vps/router"
	echo "note - you can use "cloudflared" tunnels to portforward for Eaglercraft. Mind you, this will require you to own a domain, and a cloudflare account. this method only works for Eaglercraft and does not work for java."
	echo "REQUIRED FOR Eaglercraft:"
	echo "- port 443 port forwarded/open"
	echo "- a web domain or subdomain (e.g. example.com or example.example.com)"
	# an email isnt actually required so.. echo "- an email (required for certificate, you won't be sent emails if you select no)"
	echo "- port 80 port forwarded/open"
	echo "- a web domain or subdomain (e.g. 80hdnet.work or eagler.80hdnet.work)"
	echo "- an email (required for certificate, you won't be sent emails if you select no)"
	echo "RECCOMENDED:"
	echo "- some knowledge of how to own/setup a minecraft server"
	echo "- java (the script tries to download it but it may fail. You should probably get your preferred version first.)"
	exit 1
fi
read -p "First, please enter the domain you will using for the server for Eaglercraft support. # " domain
read -p "Next, eaglersetup is creating a server folder for your server to go in. If you're already in it, type a period. Otherwise, type a name for the folder: # " folder
if [ -z "$folder" ]; then
	folder=.
fi
echo "Eaglersetup is now downloading the server. This might take a bit."
git clone https://github.com/Eaglercraft-Templates/Eaglercraft-Server-Paper "$folder"
if [ -z "$(which java)" ]; then
	echo "You don't have java! This script will try to download it on your system. If the script fails, it's likely this step that's breaking, and you should install it manually!"
	sudo apt-get install -y default-jre > /dev/null
	echo "Install complete!"
fi
chmod +x ./$folder/run.sh
echo "Done downloading the server!"
if [ -n "$domain" ]; then
	echo "Since you told us your domain, eaglersetup is now setting up websocket/eaglercraft support with Apache2. Please note that this is not configured to work with NGINX. if you don't know what that is, you can ignore this message."
	echo "this part might take a while, especially if you don't have apache2 installed (on ubuntu it's preinstalled)"
	sudo apt install apache2 -y > /dev/null 2>/dev/null
	sudo apt install certbot -y > /dev/null 2>/dev/null
	sudo systemctl stop apache2 > /dev/null 2>/dev/null
	sudo certbot certonly --standalone -d "$domain"
	sudo systemctl start apache2 > /dev/null 2>/dev/null
	read -p "Provide your intended eaglerxserver port. It will default to 25565, which is also the default for eaglerxserver. Leave it blank if you don't know what to do. # " port
	if [ -z "$port" ] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
		port=25565
	fi
	sudo tee /etc/apache2/sites-available/$domain.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName $domain
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$domain/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem

    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass / ws://localhost:$port/
    ProxyPassReverse / ws://localhost:$port/

    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} =websocket [NC]
    RewriteRule /(.*) ws://localhost:$port/\$1 [P,L]

    ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
    CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined
</VirtualHost>
EOF
	read -p "Is there already a website running on Apache2? If you don't know what this means, press enter. [yN] # " yn2
	if [ "$yn" = "n" ] || [ "$yn" = "N" ] || [ -z "$yn" ]; then
		echo "Eaglersetup is disabling the default Apache2 config. It's easy to fix if you decide to make a website later."
		sudo a2dissite *default*
	fi
	sudo a2enmod proxy proxy_http proxy_wstunnel rewrite ssl > /dev/null
	sudo a2ensite "$domain.conf" > /dev/null
	sudo systemctl restart apache2
	sed -i 's/25565/$port/' $folder/server.properties
fi
read -p "Now do you want to run the server? [Y/n] # " yn
if [ "$yn2" = "n" ] || [ "$yn2" = "N" ] || [ -z "$yn2" ]; then
	echo "Okay! starting the server..."
	cd $folder
	./run.sh
else
	echo "Eaglersetup has completed! Remember to run it by typing ./run.sh"
	cd $folder
fi
## This code written by  Melanie Pacheco, discord 80hd_0. other common aliases:
## 80hd_0, 80HD0, 80HD-0, 80HD
