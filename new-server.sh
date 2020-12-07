#!/bin/bash

##
# BASH script for install a new BBB server with:
#   - prepair the server (update, set hostname, set timezone,...)
#   - Connect to DarsPlus private cloud
#     - Install OpenConnect and create the service
#     - Check the connection to private cloud
#     - Mount the NFS partition
#   - Install BBB
#   - Apply setting to BBB
#   - Install exporter for Grafana 
##

function prepair_server() {

  printf "Change DNS to Shecan...\n"
cat > /etc/resolv.conf << EOF
nameserver 178.22.122.100
nameserver 185.51.200.2
EOF
  sleep 2
    printf "Shecan is activated!\n\n"
    printf "Update the packages list...\n"
    apt clean && apt update -q
  sleep 1
    echo ""
    echo "Input the server FQDN: "
    read server_name
  sleep 1
          (echo "${server_name}" > /etc/hostname)
    hostname -F /etc/hostname
    echo "hostname is: "
    hostname
    printf "Upgrade OS..."
    apt update && apt upgrade -y && apt autoremove -y
    dpkg-reconfigure tzdata

}

function private_cloud() {

  if [[! -f /etc/systemd/system/openconnect.service ]]
  then
    # Check openconnect is installed or not
    pkg=openconnect
    if ! dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$";
    then
      apt update && apt install $pkg -y
    fi
    printf "Input ocserv IP address: "
    read ocservIP
    printf "Input port number: "
    read ocPort
    printf "Input username: "
    read ocUsername
    printf "Input password: "
    read ocPassword
    sleep 1

cat > /etc/systemd/system/openconnect.service << EOF
    [Unit]
    Description=Connect to DarsPlus private cloud
    After=network.target

    [Service]
    Type=simple
    Environment=password=$ocPassword
    ExecStart=/bin/sh -c 'echo $password | sudo openconnect --passwd-on-stdin --user=$ocUsername --no-cert-check https://$ocservIP:$ocPort'
    Restart=always

    [Install]
    WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl start openconnect.service
    systemctl enable openconnect.service
  else
    printf "Service alredy configured. Check it man before any other change!!!"
  fi

}

function mount_nfs() {

  if [[ ! -d /nfs/ ]]
  then
    printf "Create NFS mount point...!"
      mkdir /nfs
  fi
  if ! grep -q nfs "/etc/fstab";
  then
    echo '192.168.100.230:/nfs /nfs/ nfs defaults 0 0' >> /etc/fstab
  fi
  mount -a
  printf "The NFS partition mounted to the server...!"

}

function install_bbb() {

  if [[ ! -f /etc/systemd/system/openconnect.service ]]
  then
      printf "OpenConnect service not running on the server.\n"
      printf "Do you need to connect to DarsPlus private cloud?\n"
      select yn in "Yes" "No"; do
          case $yn in
              Yes ) private_cloud; break;;
              No ) break;;
          esac
      done
      new_install
  else
      new_install
  fi

}

function apply-config() {
  chmod +x apply-config.sh
  cp apply-config.sh /etc/bigbluebutton/bbb-conf/apply-config.sh
  bbb-conf --restart
}

function new_install() {
  if [[ -f /etc/bigbluebutton/bbb-conf/apply-config.sh ]]
  then
      rm -rf /etc/bigbluebutton/bbb-conf/apply-config.sh
  fi
  
  # Get some data fro instalation
  printf "Input your FQDN without \"http://\", \"https://\" or \"www\" like bbb.darsplus.com: "
  read FQDN
  printf "Input E-mail address for generate ssl: "
  read eMail
  printf "Input turn server FQDN like turn.darsplus.com: "
  read turnServer
  printf "Input turn server secret key: "
  read turnSecret

  wget -qO- https://ubuntu.bigbluebutton.org/bbb-install.sh | bash -s -- -v xenial-22 -s $FQDN -e $eMail -c $turnServer:$turnSecret -w
}

function press_any_key() {
  printf "\nPress any key to back to menu..."
  while [ true ] ; do
  read -t 3 -n 1
  if [ $? = 0 ] ; then
    clear ; menu ;
  else
  echo "waiting for the keypress"
  fi
  done
}

##
# Color  Variables
##
red='\e[31m'
green='\e[32m'
blue='\e[34m'
clear='\e[0m'

##
# Color Functions
##

ColorGreen(){
	echo -ne $green$1$clear
}
ColorBlue(){
	echo -ne $blue$1$clear
}

menu(){
  clear
echo -ne "
What do you want to do?
$(ColorGreen '1)') Prepare server for new instalation
$(ColorGreen '2)') Connect to DarsPlus private cloud
$(ColorGreen '3)') Create and mount NFS to the server 
$(ColorGreen '4)') Install or Update BigBlueButton
$(ColorGreen '5)') Apply needed configuration to BBB
$(ColorGreen '0)') Exit
$(ColorBlue 'Choose an option:') "
        read a
        case $a in
	        1) prepair_server ; press_any_key ;;
	        2) private_cloud ; press_any_key ;;
	        3) mount_nfs ; press_any_key ;;
	        4) install_bbb ; press_any_key ;;
          5) apply-config ; press_any_key ;;
		0) clear; exit 0 ;;
		*) echo -e $red"Wrong option."$clear; sleep 1; clear; menu;;
        esac
}

# Call the menu function
check_root() {
  if [ $EUID != 0 ]; 
  then 
    printf "You must run this script as root.\n";
  else
    clear
    menu
  fi
}

check_root