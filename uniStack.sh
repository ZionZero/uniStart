#!/bin/bash
#
# This script does the initial configuration and securing found in guides:
#   https://www.linode.com/docs/getting-started/
#   https://www.linode.com/docs/security/securing-your-server/
# It SHOULD work for Ubuntu, Debian, Arch, and CentOS

# Look for Distribution Type
if [ -e /etc/debian_version ]; then
distrotype="debian"
elif [ -e /etc/arch-release ]; then
distrotype="archlinux"
else
distrotype=$(cat /etc/os-release | grep "ID_LIKE" | sed 's/ID_LIKE=//g' | sed 's/["]//g' | awk '{print $1}')
fi

# User greeting
echo
echo "Hello There $distrotype User! "
echo "===================================="
echo

# Upgrade Packages
echo "Updating Your $distrotype based system"
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
if [ "$distrotype" = "rhel" ]; then
yum update -y
fi

# Clock config
echo
echo "Set Local Timezone"
echo "===================================="
if [ "$distrotype" = "archlinux" ]; then
	tzselect
fi
if [ "$distrotype" = "debian" ]; then
	dpkg-reconfigure tzdata
fi
if [[ "$distrotype" = "centos" ]]; then
	tzselect
fi
if [[ "$distrotype" = "rhel" ]]; then
	tzselect
fi

# Hostname config
echo
echo "Set Hostname"
echo "===================================="
echo
read -p "Choose A Hostname. " HOSTNAME
hostnamectl set-hostname $HOSTNAME
IP=$(ip -4 addr show dev eth0 | grep inet | tr -s " " | cut -d" " -f3 | head -n 1 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
echo "$IP   $HOSTNAME" >> /etc/hosts


echo "Restarting SSH Daemon"
echo "===================================="
systemctl restart sshd

# Create new USER
echo
echo "Setup a non-root user"
echo "===================================="
echo
read -p 'New User Name? ' NEWUSER

if [ "$distrotype" = "archlinux" ]; then
	useradd -m -g users -G wheel -s /bin/bash $NEWUSER
	echo
	echo "User added to wheel group"
	echo "===================================="
	echo
fi
if [ -e /etc/debian_version ]; then
	adduser $NEWUSER
	adduser $NEWUSER sudo
	echo
	echo "User added to sudo group"
	echo "===================================="
	echo
fi
if [ "$distrotype" = "centos" ]; then
	adduser $NEWUSER
	passwd $NEWUSER
	usermod -aG wheel $NEWUSER
	echo "User added to wheel group"
	echo "===================================="
	echo
fi
if [ "$distrotype" = "rhel" ]; then
	adduser $NEWUSER
	passwd $NEWUSER
	usermod -aG wheel $NEWUSER
	echo
	echo "User added to wheel group"
	echo "===================================="
	echo
fi

# Setup pubkey directory,
if [[ ! $PUB ]]; then read -p "Paste $NEWUSER SSH pubkey here: " PUB; fi

mkdir -p /home/$NEWUSER/.ssh
touch /home/$NEWUSER/.ssh/authorized_keys
echo $PUB > /home/$NEWUSER/.ssh/authorized_keys
chmod 700 -R /home/$NEWUSER/.ssh
chmod 600 /home/$NEWUSER/.ssh/authorized_keys

# Request pub key from user, set permissions.
echo
echo "SSH Public Key Configuration"
echo "===================================="
echo
#read -p "Paste $NEWUSER pubkey here: " PUB

# Proper chown
if [ "$distrotype" = "archlinux" ]; then
chown $NEWUSER:wheel /home/$NEWUSER/.ssh/
chown $NEWUSER:wheel /home/$NEWUSER/.ssh/authorized_keys
fi

if [ -e /etc/debian_version ]; then
	chown $NEWUSER:$NEWUSER /home/$NEWUSER/.ssh/authorized_keys
	chown $NEWUSER:$NEWUSER /home/$NEWUSER/.ssh/
fi

if [ "$distrotype" = "rhel" ]; then
	chown $NEWUSER:wheel /home/$NEWUSER/.ssh/authorized_keys
	chown $NEWUSER:wheel /home/$NEWUSER/.ssh/
fi

if [ "$distrotype" = "centos" ]; then
	chown $NEWUSER:wheel /home/$NEWUSER/.ssh/authorized_keys
	chown $NEWUSER:wheel /home/$NEWUSER/.ssh/
fi

# Configure SSHD File and permissions
sed -i -e "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/#PermitRootLogin no/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i -e "s/#PasswordAuthentication no/PasswordAuthentication no/" /etc/ssh/sshd_config

# Finish
echo
echo "All done $NEWUSER. Your IP is $IP. System Ready"
echo "===================================="
