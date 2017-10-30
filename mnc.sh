#!/bin/bash
# 1 parameter - local server ip
# 2 parameter - server\client share
# 3 parameter - server\client time_syncro
# 4 parameter - first CPU core
# 5 parameter - last CPU core

file_auto_update20=/etc/apt/apt.conf.d/20auto-upgrades
file_auto_update50=/etc/apt/apt.conf.d/50unattended-upgrades
file_repo=/etc/apt/sources.list
file_grub=/etc/default/grub

#SETCOLOR_SUCCESS="echo -en \\033[1;32m"
#SETCOLOR_FAILURE="echo -en \\033[1;31m"
#SETCOLOR_NORMAL="echo -en \\033[0;39m"

if [ $# != 5 ]
then
echo "Параметры скрипта по порядку: [ip-сервера] [server\\client share] [server\\client time_syncro] [first CPU core] [last CPU core]"
exit
else
:
fi

if [ -f /home/user/script_flag ]
# Second starting
then
if [ $2 = client ]
  then
mount $1:/home/user/share share
echo "$1:/home/user/share /home/user/share nfs timeo=50,hard,intr" | tee -a /etc/fstab
  else
:
fi
rm /home/user/script_flag
ldconfig
# First starting
else
if [ -e $file_auto_update20 ]
then if [ -f $file_auto_update20 ]
  then
  echo 'APT::Periodic::Update-Package-Lists "0";' > $file_auto_update20
  echo 'APT::Periodic::Update-Package-Lists "0";' >> $file_auto_update20
  else 
  echo $file_auto_update20 is not a file
  fi
else
: > $file_auto_update20
echo 'APT::Periodic::Update-Package-Lists "0";' > $file_auto_update20
echo 'APT::Periodic::Update-Package-Lists "0";' >> $file_auto_update20
fi

if [ -e $file_auto_update50 ]
then if [ -f $file_auto_update50 ]
  then
  sed -i 's/^"${distro_id}:${distro_codename}-security";/\/\/"${distro_id}:${distro_codename}-security";/g' $file_auto_update50
  else
  echo $file_auto_update50 is not a file
  fi
else
echo $file_auto_update50 does not exist
fi

cp -r ./auto/ /home/user/

sed -i 's/^[0-9A-Za-z]/\#&/g' $file_repo

apt-get update

dpkg -i /home/user/auto/deb_ubuntu16/*.deb

# installing programs
mkdir /home/user/programs/
cp /home/user/auto/programs/programs.tar.gz /home/user/programs/
cd /home/user/programs/
tar xf ./programs.tar.gz

# installing DPDK
cpu_cores="$(seq -s ',' $4 1 $5)"
mkdir /home/user/DPDK/
chown user:user /home/user/DPDK/
cp /home/user/auto/DPDK/dpdk-16.11.2.tar.xz /home/user/DPDK/
cd /home/user/DPDK/
tar xf ./dpdk-16.11.2.tar.xz
cd ./dpdk-stable-16.11.2/
make install DESTDIR=dpdk_install T=x86_64-native-linuxapp-gcc CONFIG_RTE_BUILD_SHARED_LIB=y EXTRA_CFLAGS="-fPIC"
sed -i "s/GRUB_CMDLINE_LINUX=\"/&default_hugepagesz=1G\ hugepagesz=1G\ hugepages=2\ isolcpus=$cpu_cores/g" $file_grub
update-grub
cp /home/user/auto/other/HGPG_for_DPDK.service /etc/systemd/system/
cp /home/user/auto/other/distrib_HGPG_DPDK.sh /home/user/DPDK/
chmod +x /home/user/DPDK/distrib_HGPG_DPDK.sh
sed -i -e 's/\r$//' /home/user/DPDK/distrib_HGPG_DPDK.sh
systemctl enable HGPG_for_DPDK
mkdir -p /mnt/huge
touch /etc/ld.so.conf.d/library.conf
echo "/home/user/programs/library/" | tee -a /etc/ld.so.conf.d/library.conf
touch /etc/ld.so.conf.d/librte.conf
echo "/home/user/DPDK/dpdk-stable-16.11.2/x86_64-native-linuxapp-gcc/lib/" | tee -a /etc/ld.so.conf.d/librte.conf
ldconfig
cp /home/user/auto/libhtgiolib/libhtgiolib.so.1.2.10 /home/user/DPDK/
ln -s /home/user/DPDK/libhtgiolib.so.1.2.10 /usr/lib/libhtgiolib.so
ln -s /lib/x86_64-linux-gnu/libprocps.so.4 /lib/x86_64-linux-gnu/libprocps.so.3
cp /home/user/auto/boost/* /usr/lib/x86_64-linux-gnu/
#sed -i -e '/^exit 0/i/home/user/programs/run.sh' /etc/rc.local

# Configuration share-service
if [ $2 = server ]
then
apt-get -f install /home/user/auto/sharing/server/*.deb
mkdir -p /home/user/share/
echo "/home/user/share $1/255.255.255.0(rw,no_root_squash,async,subtree_check)" | sudo tee -a /etc/exports
/etc/init.d/nfs-kernel-server restart
else
apt-get -f install /home/user/auto/sharing/client/*.deb
deb mkdir -p /home/user/share/
fi

# Configuration time_syncro
ln -s /home/user/auto/timesync/libproxy.so.1.0.0 /usr/lib/x86_64-linux-gnu/libproxy.so.1
ln -s /home/user/auto/timesync/libQt5Network.so.5.5.1 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5
chmod +x /home/user/auto/timesync/time_syncro
ldconfig
if [ $3 = server ]
then
cp /home/user/auto/timesync/server/time_sync_server.service /etc/systemd/system/
cp /home/user/auto/timesync/server/time.sh /home/user/programs/
systemctl enable time_sync_server.service
else
cp /home/user/auto/timesync/client/time_sync_client.service /etc/systemd/system/
cp /home/user/auto/timesync/client/time.sh /home/user/programs/
systemctl enable time_sync_client.service
fi

echo : > /home/user/script_flag
reboot
fi