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

#server_name=$(hostname)



function prepair_server() {
  printf "Change DNS to Shecan...\n"
  cat > /etc/resolv.conf << EOF
    nameserver 178.22.122.100
    nameserver 185.51.200.2
EOF
  sleep 2
    printf "Shecan is activated!\n\n"
    printf "Update the packages list...\n"
    apt clean && apt update -qq
  sleep 1
    echo ""
    echo "Input the server FQDN:"
    read server_name
  sleep 1
          (echo "${server_name}" > /etc/hostname)
    hostname -F /etc/hostname
    echo "hostname is:"
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
    printf "Input ocserv IP address:"
    read ocservIP
    printf "Input port number:"
    read ocPort
    printf "Input username:"
    read ocUsername
    printf "Input password:"
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
  if grep -q nfs "/etc/fstab";
  then
    echo '192.168.100.230:/nfs /nfs/ nfs defaults 0 0' >> /etc/fstab
  fi
  mount -a
}

function install_bbb() {

  if [[! -f /etc/systemd/system/openconnect.service ]]
  then
      printf "OpenConnect service not running on the server.\n"
      printf "Do you need to connect to DarsPlus private cloud?"
      select yn in "Yes" "No"; do
          case $yn in
              Yes ) private_cloud; break;;
              No ) exit;;
          esac
      done
      new_install
  else
      new_install
  fi

  
}

function new_install() {
  # Get some data fro instalation
  printf "Input your FQDN without \"http://\", \"https://\" or \"www\" like bbb.darsplus.com:"
  read FQDN
  printf "Input E-mail address for generate ssl:"
  read eMail
  printf "Input turn server FQDN like turn.darsplus.com:"
  read turnServer
  printf "Input turn server secret key:"
  read turnSecret

  wget -qO- https://ubuntu.bigbluebutton.org/bbb-install.sh | bash -s -- -v xenial-22 -s $FQDN -e $eMail -c $turnServer:$turnSecret -w
}


##
# Color  Variables
##
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
echo -ne "
What do you want to do?
$(ColorGreen '1)') Prepare server for new instalation
$(ColorGreen '2)') Connect to DarsPlus private cloud
$(ColorGreen '3)') Check private cloud connection 
$(ColorGreen '4)') Install or Update BigBlueButton
$(ColorGreen '0)') Exit
$(ColorBlue 'Choose an option:') "
        read a
        case $a in
	        1) prepair_server ; menu ;;
	        2) private_cloud ; menu ;;
	        3) mount_nfs ; menu ;;
	        4) install_bbb ; menu ;;
		0) exit 0 ;;
		*) echo -e $red"Wrong option."$clear; WrongCommand;;
        esac
}

# Call the menu function
menu