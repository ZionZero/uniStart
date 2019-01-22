#!/bin/bash
#
# This script does the initial configuration and securing found in guides:
#   https://www.linode.com/docs/getting-started/
#   https://www.linode.com/docs/security/securing-your-server/
# It SHOULD work for Ubuntu, Debian, Arch, and CentOS

# Look for Distribution Type
distrotype=$(cat /etc/os-release | grep "ID_LIKE" | sed 's/ID_LIKE=//g' | sed 's/["]//g' | awk '{print $1}')

# User greeting
echo "Hello There!"
echo "===================================="
echo

# Upgrade Packages
echo "Updating $distrotype"
echo "===================================="
echo
if [ "$distrotype" = "archlinux" ]; then
pacman -Syu -y
fi
if [ "$distrotype" = "ubuntu" ]; then
apt update && apt upgrade -y
fi
if [ "$distrotype" = "debian" ]; then
apt update && apt upgrade -y
fi
if [ "$distrotype" = "centos" ]; then
yum update -y
fi

# Hostname config
echo "Set Hostname"
echo "===================================="
echo
read -p "What is my Hostname? " HOSTNAME
hostnamectl set-hostname $HOSTNAME
nano /etc/hosts
IP=$(curl -s -4 icanhazip.com)
echo "$IP   $HOSTNAME" >> /etc/hosts

# Create new USER
echo "Choose a Username"
echo "===================================="
echo
read -p 'User Name?' USER
if [ "$distrotype" = "archlinux" ]; then
	useradd -m -g users -G wheel -s /bin/bash $USER
	echo "User added to wheel group"
	echo "===================================="
	echo
fi
if [ "$distrotype" = "Debian" ]; then
	adduser $USER
	adduser $USER sudo
	echo "User added to sudo group"
	echo "===================================="
	echo
fi
if [ "$distrotype" = "CentOS" ]; then
	adduser $USER
	passwd $USER
	usermod -aG wheel $USER
	echo "User added to wheel group"
	echo "===================================="
	echo
fi

# Clock config
echo "TIMEZONE SETUP"
echo "===================================="
if [ "$distrotype" = "archlinux" ]; then
	tzselect
fi
if [ "$distrotype" = "Debian" ]; then
	dpkg-reconfigure tzdata
fi
if [[ "$distrotype" = "CentOS" ]]; then
	tzselect
fi

# Setup pubkey directory, request pub key from user, set permissions.
echo "SSH PUBLIC KEY SETUP"
echo "===================================="
echo
read -p 'Which users pubkey are you pasting?' USER
if [[ ! $PUB ]]; then read -p "Paste $USERS SSH pubkey: " PUB; fi
mkdir -p /home/${USER}/.ssh
touch /home/${USER}/.ssh/authorized_keys
echo $PUB > /home/${USER}/.ssh/authorized_keys
chmod 700 -R /home/${USER}/.ssh
chmod 600 /home/${USER}/.ssh/authorized_keys


# Proper chown
if [ "$distrotype" = "archlinux" ]; then
chown $USER:wheel /home/$USER/.ssh/authorized_keys
chown $USER:wheel /home/$USER/.ssh/
fi

if [ "$distrotype" = "Debian" ]; then
	chown $USER:$USER /home/$USER}/.ssh/authorized_keys
	chown $USER:$USER /home/$USER}/.ssh/
fi

# Configure SSHD File and permissions
sed -i -e "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/#PermitRootLogin no/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i -e "s/#PasswordAuthentication no/PasswordAuthentication no/" /etc/ssh/sshd_config

echo "Restarting SSH Daemon"
echo "===================================="
systemctl restart sshd

echo "Your Linux Server Is Ready!"
echo "===================================="
