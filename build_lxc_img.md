## Dependencies

#### LXC and LXC-net
Install lxc (ver > 2.0) on your computer. With Debian use the Jessie-backports or Stretch repo.

You should establish a bridge between the container and your network interface to have an Internet connection on it.

The lxc-net package is part of the lxc package in Debian (Jessie-backports and stretch).
Put the following lines in /etc/default/lxc-net :

```sh
USE_LXC_BRIDGE="true"
LXC_BRIDGE="lxcbr0"
LXC_ADDR="10.0.3.1"
LXC_NETMASK="255.255.255.0"
LXC_NETWORK="10.0.3.0/24"
LXC_DHCP_RANGE="10.0.3.2,10.0.3.254"
LXC_DHCP_MAX="253"
LXC_DHCP_CONFILE=""
LXC_DOMAIN=""
```

Then (as root or sudo)

```sh
systemctl enable lxc-net # enable the service to run at boot
systemctl start lxc-net # launch the service
```

Now every container should have a bridge and therefore is connected to Internet (if your computer is also ;). You can check with the ```ifconfig``` or ```ip a``` command on your computer and the container.

#### Ansible

Install the ansible (ver > 2.0) package from your distribution repo. For Debian use Jessie-backports or Stretch.

## Create the container

(as root or sudo)
```sh
lxc-create -n <name> -t debian -- -r jessie
lxc-start -n <name>
lxc-attach -n <name>
```

Now a shell is opened in the lxc image as root.

## Execution of some command in th container

(as root in the lxc image)

```sh
adduser lxc
apt update && apt upgrade && apt install apt-transport-https python sudo nano less openssh-server
adduser lxc sudo
exit
```
Python and sudo are needed by Ansible

Now check the ip addr of the container and remember it (I will refer to it in this document as <container_ip_addr>) :

(as root or sudo)
```sh
lxc-ls -f
```

## Enable ssh connection to the container

Create an ssh key (with no passphrase, it's easier) for your container (if not already done) :

```sh
ssh-keygen -t rsa -b 4096 -C "Any comment" -f ~/.ssh/<key_file_name>
```

Copy the public key to the ```authorized_key``` file in the container :

```sh
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/<key_file_name>.pub lxc@<container_ip_addr>
```

Put the following lines in ~/.ssh/config (if not already done) :

```sh
Host 10.0.3.*
  IdentityFile ~/.ssh/lxc_image
```

## Execute Ansible to configure the container

First, put the <container_ip_addr> of the container in the ```hosts``` file of the ansible playbook

Then :

```sh
ansible-playbook -i hosts ethereum.yml
```

Your container is ready !
