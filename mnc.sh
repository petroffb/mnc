#!/bin/bash

file_auto_update20=/etc/apt/apt.conf.d/20auto-upgrades
file_auto_update50=/etc/apt/apt.conf.d/50unattended-upgrades
file_repo=/etc/apt/sources.list
file_grub=/etc/default/grub
cond="bad"

if [ -f /home/user/script_flag ]
# Second starting
then
counter=0
while read line; do
((counter++))
case $counter in
  1 ) srv_clnt=$line;;
  2 ) share_server_ip=$line;;
  * ) :;;
esac
done < /home/user/script_flag
if [ $srv_clnt = client ]
  then
mount $share_server_ip:/home/user/share share
echo "$share_server_ip:/home/user/share /home/user/share nfs timeo=50,hard,intr" | tee -a /etc/fstab
  else
:
fi
rm /home/user/script_flag
ldconfig
else
# First starting
while [[ $cond != "ok" ]]; do
echo "Be attentive before input!"
srv_clnt=2
time_syncro_srv_port=0
time_syncro_srv_ip=""
while [ $srv_clnt == 2 ]; do
  echo "Choose the installation way:"
  printf "0 - [S]erver\n1 - [C]lient\n"
  read response
  case $response in
  0|[sS]* ) echo "The Server option has been chosen."
      srv_clnt="server";;
  1|[cC]* ) echo "The Client option has been chosen."
      srv_clnt="client";;
  * ) echo "One more time....";;
  esac
done
echo "The PU's type:"
while [[ $response_pu != [0-1] ]]; do
printf "0 - 83-rd order\n1 - NT\n2 - 2I\n"
read response_pu
done
case $response_pu in
  0 ) echo "The PU's type is 83-rd order";;
  1 ) echo "The PU's type is NT";;
  2 ) echo "The PU's type is 2I";;
  * ) echo "ERROR! The PU's type is unknown!"
      exit;;
esac
case $srv_clnt in
  "server" ) while [[ $time_syncro_srv_port -le 1024 || $time_syncro_srv_port -gt 65535 ]]; do
      echo "Port [1025 - 65535] for time_syncro clients' connecting (default 27333) : "
      read time_syncro_srv_port
      if [ -z $time_syncro_srv_port ]
      then time_syncro_srv_port=27333
      else :
      fi
      done
      echo "Port for time_syncro clients' connecting has been chosen: $time_syncro_srv_port"
      echo "IP-address for share-server (local ip-address):"
      read share_server_ip
      echo "Share-server's ip-address has been setted: $share_server_ip"
      ;;
  "client" ) while [[ -z $time_syncro_srv_ip ]]; do
      echo "Time_syncro server's ip-address : "
      read time_syncro_srv_ip
      done
      while [[ $time_syncro_srv_port -le 1024 || $time_syncro_srv_port -gt 65535 ]]; do
      echo "Port [1025 - 65535] for time_syncro clients' connecting (default 27333) : "
      read time_syncro_srv_port
      if [ -z $time_syncro_srv_port ]
      then time_syncro_srv_port=27333
      else 
      :
      fi
      done
      echo "Port for time_syncro clients' connecting has been chosen: $time_syncro_srv_port"
      echo "Range of cores has been chosen (minutes):"
      read time_syncro_period
      echo "The time_syncro server's range has been setted (minuts): $time_syncro_period"
      echo "Share-server's ip-address:"
      read share_server_ip
      echo "Share-server's ip-address has been setted : $share_server_ip"
      ;;
  * ) echo "The installation way is unknown! Bye :("
      exit;;
esac
echo "Type via space a range for segregation of cores:"
read first_cpu_core last_cpu_core
echo "Range of cores has been chosen: $first_cpu_core - $last_cpu_core"
echo "Use autostart of ipmimon (yes or no)? Use one only if you have enough resorces."
read auto_ipmimon
echo "These options will be used:"
echo "The installation way is - $srv_clnt"
if [ $srv_clnt == "server" ]
then
  echo "Port for time_syncro clients' connecting - $time_syncro_srv_port"
  echo "Share server's ip-address - $share_server_ip"
else
  echo "Time_syncro server's ip-address - $time_syncro_srv_ip:$time_syncro_srv_port"
  echo "Period of requesting time_syncro server (minutes): $time_syncro_period"
  echo "Share-server's ip-address - $share_server_ip"
fi
echo "Used cores $first_cpu_core - $last_cpu_core"
case $auto_ipmimon in
  [yY]es ) echo "ipmimon.service is in autostart mode";;
  * ) echo "ipmimon.service is not in autostart mode";;
esac
echo -n "Are all correct? (if yes - type 'ok'): "
read cond
done

# Main process
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
case $response_pu in
  0 ) tar -xf /home/user/auto/programs/83/programs.tar.gz -C /home/user/programs/
      cp /home/user/auto/programs/83/lib/*.so /usr/lib/
      mkdir /mnt/ram_disk/
      printf "tmpfs     /mnt/ram_disk     tmpfs     rw,size=10G,x-gvfs-show     0 0\n" >> /etc/fstab
      mount -a      
      ;;
  1 ) tar -xf /home/user/auto/programs/NT/programs.tar.gz -C /home/user/programs/
      cp /home/user/auto/programs/NT/lib/*.so /usr/lib/
      ;;
  2 ) tar -xf /home/user/auto/programs/2Iq/programs.tar.gz -C /home/user/programs/
      cp /home/user/auto/programs/2I/lib/*.so /usr/lib/
      ;;
  * ) echo "КОСЯК! Вариант реализации пультовой части: Неизвестно"
      ;;
esac

# installing DPDK
cpu_cores="$(seq -s ',' $first_cpu_core 1 $last_cpu_core)"
mkdir /home/user/DPDK/
chown user:user /home/user/DPDK/
cp /home/user/auto/DPDK/dpdk-16.11.3.tar.xz /home/user/DPDK/
cd /home/user/DPDK/
tar xf ./dpdk-16.11.3.tar.xz
cd ./dpdk-stable-16.11.3/
make install DESTDIR=dpdk_install T=x86_64-native-linuxapp-gcc CONFIG_RTE_BUILD_SHARED_LIB=y EXTRA_CFLAGS="-fPIC"
sed -i "s/GRUB_CMDLINE_LINUX=\"/&default_hugepagesz=1G\ hugepagesz=1G\ hugepages=0\ isolcpus=$cpu_cores/g" $file_grub
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
echo "/home/user/DPDK/dpdk-stable-16.11.3/x86_64-native-linuxapp-gcc/lib/" | tee -a /etc/ld.so.conf.d/librte.conf
cp /home/user/auto/other/dpdkbind.service /etc/systemd/system/
cp /home/user/auto/other/ipmimon.service /etc/systemd/system/
systemctl enable dpdkbind.service
if [[ $auto_ipmimon = [yY]es ]]
then 
systemctl enable ipmimon.service
else
systemctl disable ipmimon.service
fi
ldconfig
cp /home/user/auto/libhtgiolib/libhtgiolib.so.1.3.0 /home/user/DPDK/
ln -s /home/user/DPDK/libhtgiolib.so.1.3.0 /usr/lib/libhtgiolib.so
ln -s /lib/x86_64-linux-gnu/libprocps.so.4 /lib/x86_64-linux-gnu/libprocps.so.3
cp /home/user/auto/boost/* /usr/lib/x86_64-linux-gnu/
#sed -i -e '/^exit 0/i/home/user/programs/run.sh' /etc/rc.local

# Configuration share-service
if [ $srv_clnt = server ]
then
apt-get -f install /home/user/auto/sharing/server/*.deb
mkdir -p /home/user/share/
echo "/home/user/share $share_server_ip/255.255.255.0(rw,no_root_squash,async,subtree_check)" | sudo tee -a /etc/exports
/etc/init.d/nfs-kernel-server restart
else
apt-get -f install /home/user/auto/sharing/client/*.deb
mkdir -p /home/user/share/
fi

# Configuration time_syncro
mkdir /home/user/programs/time_syncro/
cp /home/user/auto/timesync/*.* /home/user/programs/time_syncro/
cp /home/user/auto/timesync/time_syncro /home/user/programs/time_syncro/
ln -s /home/user/programs/time_syncro/libproxy.so.1.0.0 /usr/lib/x86_64-linux-gnu/libproxy.so.1
ln -s /home/user/programs/time_syncro/libQt5Network.so.5.5.1 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5
chmod +x /home/user/programs/time_syncro/time_syncro
ldconfig
if [ $srv_clnt = server ]
then
cp /home/user/auto/timesync/server/time_sync_server.service /etc/systemd/system/
cp /home/user/auto/timesync/server/time.sh /home/user/programs/time_syncro/
sed -i "/time_syncro/c /home/user/programs/time_syncro/time_syncro -s $time_syncro_srv_port" /home/user/programs/time_syncro/time.sh
systemctl enable time_sync_server.service
else
cp /home/user/auto/timesync/client/time_sync_client.service /etc/systemd/system/
cp /home/user/auto/timesync/client/time.sh /home/user/programs/time_syncro/
time_syncro_tmp=$time_syncro_srv_ip":"$time_syncro_srv_port" "$time_syncro_period
sed -i "/time_syncro/c /home/user/programs/time_syncro/time_syncro -c $time_syncro_tmp" /home/user/programs/time_syncro/time.sh
systemctl enable time_sync_client.service
fi
chmod +x /home/user/programs/time_syncro/time.sh

#Making checkpoint
echo $srv_clnt > /home/user/script_flag
echo $share_server_ip >> /home/user/script_flag

reboot
fi