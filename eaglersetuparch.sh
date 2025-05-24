echo "#####################################################################################"
echo "                            \"\"#                                  m                 "
echo "       mmm    mmm    mmmm    #     mmm    m mm   mmm    mmm   mm#mm  m   m  mmmm  "
echo "     #\"  #  \"   #  #\" \"#    #    #\"  #   #\"  \" #   \"  #\"  #    #    #   #  #\" \"# "
echo "    #\"\"\"\"  m\"\"\"#  #   #    #    #\"\"\"\"   #      \"\"\"m  #\"\"\"\"    #    #   #  #   # "
echo "   \"#mm\"  \"mm\"#  \"#m\"#    \"mm  \"#mm\"   #     \"mmm\"  \"#mm\"    \"mm  \"mm\"#  ##m#\" "
echo "                 m  #                                                   #     "
echo "                 \"\"  "
echo "2025 Melanie Pacheco, 80hd_0                                              Version 1.1"
echo "#####################################################################################"
echo "Welcome to eaglersetup! This script sets up a fully functional eaglercraft server, and optionally sets up WSS for it too. If you have any issues, contact me on discord, username 80hd_0."
read -p "Before we begin, type anything at all if you understand the prerequisites (requirements) for running this server. Press enter if you don't understand/know. # " understandme
if [ -z "$understandme" ]; then
	echo "Here are the prerequisites for running this program and any eaglercraft server. Anything not listed here is done for you."
	echo "REQUIRED:"
	echo "- port 25565 port forwarded/open (unless you are setting up wss!). If you don't know what that is, please use our best friend Mr. Search Engine."
	echo "REQUIRED FOR WSS:"
	echo "- port 443 port forwarded/open"
	echo "- a web domain or subdomain (e.g. 80hdnet.work or eagler.80hdnet.work)"
	echo "- an email (required for certificate, you won't be sent emails if you select no)"
	echo "RECCOMENDED:"
	echo "- some knowledge of how to own/setup a minecraft server"
	echo "- java (the script tries to download it but it may not work on all systems!)"
	exit 1
fi
read -p "First, please provide your domain if you want WSS support or leave it blank if you don't. # " domain
read -p "Next, eaglersetup is creating a server folder for your server to go in. If you're already in it, type a period. Otherwise, type a name for the folder: # " folder
if [ -z "$folder" ]; then
	folder=.
fi
echo "Eaglersetup is now downloading the server. This might take a bit."
sudo pacman -S --noconfirm git > /dev/null 2>/dev/null
sudo pacman -S --noconfirm jre-openjdk > /dev/null 2>/dev/null
git clone https://github.com/Eaglercraft-Templates/Eaglercraft-Server-Paper "$folder"
chmod +x ./$folder/run.sh
echo "Done downloading the server!"
if [ -n "$domain" ]; then
	echo "Since you told us your domain, eaglersetup is now setting up WSS support with Apache2. Please note that this is not configured to work with NGINX. if you don't know what that is, you can ignore this message."
	echo "this part might take a while, especially if you don't have apache installed."
	sudo pacman -S --noconfirm apache > /dev/null 2>/dev/null
	sudo pacman -S --noconfirm certbot > /dev/null 2>/dev/null
	sudo systemctl stop httpd > /dev/null 2>/dev/null
	sudo certbot certonly --standalone -d "$domain"
	sudo systemctl start httpd > /dev/null 2>/dev/null
	read -p "Provide your intended eaglerxserver port. It will default to 25565, which is also the default for eaglerxserver. Leave it blank if you don't know what to do. # " port
	if [ -z "$port" ] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
		port=25565
	fi
	sudo tee /etc/httpd/conf/extra/$domain.conf > /dev/null <<EOF
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
	sudo sed -i '/^#LoadModule proxy_module/s/^#//' /etc/httpd/conf/httpd.conf
	sudo sed -i '/^#LoadModule proxy_http_module/s/^#//' /etc/httpd/conf/httpd.conf
	sudo sed -i '/^#LoadModule proxy_wstunnel_module/s/^#//' /etc/httpd/conf/httpd.conf
	sudo sed -i '/^#LoadModule rewrite_module/s/^#//' /etc/httpd/conf/httpd.conf
	sudo sed -i '/^#LoadModule ssl_module/s/^#//' /etc/httpd/conf/httpd.conf
	if ! grep -q "extra/$domain.conf" /etc/httpd/conf/httpd.conf; then
    		echo "Include conf/extra/$domain.conf" | sudo tee -a /etc/httpd/conf/httpd.conf
	fi
	sudo systemctl restart httpd
	sed -i 's/25565/$port/' $folder/server.properties
fi
read -p "Now do you want to run the server? [Y/n] # " yn
if [ "$yn" = "y" ] || [ "$yn" = "Y" ] || [ -z "$yn" ]; then
	echo "Okay! starting the server..."
	cd $folder
	./run.sh
else
	echo "Eaglersetup has completed! Remember to run it by typing ./run.sh"
	cd $folder
fi
## This code written by  Melanie Pacheco, discord 80hd_0. other common aliases:
## 80hd_0, 80HD0, 80HD-0, 80HD
