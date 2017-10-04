#version=DEVEL
# X Window System configuration information
#xconfig  --startxonboot
# Keyboard layouts
keyboard 'us'
# Root password
#rootpw --plaintext osetroot
rootpw --iscrypted '$6$OSET Foundation$2mPT6B.GIZtow9zZYRewucn1GrFQj6ooqeMIxFxKAl1d8LX1wDizIK4Xl.rkqwslhHb3z5XhyHRGJ/06qwBfz/'
url --url="file:///opt/OSET/LiveISO/rpmRepo"

# System language
lang en_US.UTF-8
user --name=osetuser --password=osetuser
# Firewall configuration
firewall --enabled --service=mdns

repo --name="local" --baseurl=file:///opt/OSET/LiveISO/rpmRepo

# System timezone
timezone US/Eastern
network  --bootproto=dhcp --device=lo --no-activate
#network  --no-activate

# System authorization information
auth --useshadow --enablemd5
# SELinux configuration
selinux --enforcing

# System services
#services --enabled="sshd"
# System bootloader configuration
bootloader --location=none
# Disk partitioning information
part / --fstype="ext4" --size=4000

%packages --excludedocs --nocore
basesystem
bash
biosdevname
cronie
curl
filesystem
glibc
hostname
initscripts
iproute
iprutils
iputils
kbd
less
ncurses
openssh-clients
openssh-server
plymouth
policycoreutils
procps-ng
rootfiles
rpm
rsyslog
selinux-policy-targeted
setup
shadow-utils
systemd
util-linux
vim-minimal
yum
dosfstools
dialog
dracut-config-generic
dracut-live
e2fsprogs
efibootmgr
grub2
isomd5sum
kernel
lvm2
memtest86+
syslinux
dnf
genisoimage
xorriso
cdw
coreutils
coreutils-common
sudo
audit
net-tools
jq
libxml2
%end

%post --nochroot --logfile $ANA_INSTALL_PATH/root/kickstart_post_nochroot.log
echo Copying build scripts to disc
mkdir -p $ANA_INSTALL_PATH/opt/OSET/bin
mkdir -p $ANA_INSTALL_PATH/opt/OSET/ISO
cp -r /opt/OSET/bin $ANA_INSTALL_PATH/opt/OSET
cp -r /opt/OSET/ISO $ANA_INSTALL_PATH/opt/OSET
%end

%post --logfile /root/kickstart_post.log

# set up autologin for osetuser
/usr/bin/mkdir -p /etc/gdm
cat >> /etc/gdm/custom.conf << FOE
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=osetuser
FOE

echo "Adding osetuser"
useradd -c "OSET User" osetuser
passwd -d osetuser > /dev/null
echo "Done adding osetuser"

#turn off annoying/useless audit messages to console
/usr/sbin/auditctl -e 0

#append to sudoers file so osetuser can do the right stuff
cat << EOF | sudo tee -a /etc/sudoers
osetuser	localhost=/sbin/mount /mnt/cdrom, /sbin/umount /mnt/cdrom, /usr/sbin/setenforce, /usr/sbin/livemedia-creator
EOF

cat << EOF | sudo tee -a /home/osetuser/.bash_profile
/opt/OSET/bin/deviceMgr.sh 
exit
EOF

%end

