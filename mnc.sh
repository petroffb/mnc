#!/bin/bash

# Variables
file_auto_update20=/etc/apt/apt.conf.d/20auto-upgrades
file_auto_update50=/etc/apt/apt.conf.d/50unattended-upgrades
file_repo=/etc/apt/sources.list
file_grub=/etc/default/grub
cond="bad"
file_run_sh=/home/user/programs/run.sh

# Functions
function make_swap {
  fallocate -l 16G /swap
  chmod 600 /swap
  mkswap /swap
  swapon /swap
  cp /etc/fstab /etc/fstab.bak
  echo '/swap none swap sw 0 0' | sudo tee -a /etc/fstab
}

function install_analizpack {
  mkdir /opt/oracle/
  tar -xf /home/user/auto/programs/instantclient_12_2.tar.gz -C /opt/oracle/
  cd /opt/oracle/instantclient_12_2
  ln -s libclntsh.so.12.1 libclntsh.so
  ln -s libocci.so.12.1 libocci.so
  echo /opt/oracle/instantclient_12_2 > /etc/ld.so.conf.d/oracle.conf
  ldconfig
  tar -xf /home/user/auto/programs/Analizpack.tar.gz -C /home/user/programs/
  mkdir /etc/oracle
  mv /home/user/programs/Analizpack/tnsnames.ora /etc/oracle/
  chmod 0644 /etc/oracle/tnsnames.ora
  echo TNS_ADMIN=\"/etc/oracle\" >> /etc/environment
  echo NLS_LANG=\"AMERICAN_RUSSIA.AL32UTF8\" >> /etc/environment
  echo TZ=\"Asia/Almaty\" >> /etc/environment
}

# Body
if [[ -f /home/user/script_flag ]]
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
last_cpu_core=$( cat /sys/devices/system/cpu/online | sed 's/0-//' )
let "res = ($last_cpu_core + 1) / 4"
if [ $last_cpu_core -ge 15 ] 
then 
:
else
echo "Number of cores is too small!"
exit
fi
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
while [[ $response_pu != [0-2] ]]; do
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
printf "Will you use Analizpack? (yes\no): "
read use_analizpack
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
      echo "Enter the period of requesting time_syncro server (minutes):"
      read time_syncro_period
      echo "The time_syncro server's range has been setted (minuts): $time_syncro_period"
      echo "Share-server's ip-address:"
      read share_server_ip
      echo "Share-server's ip-address has been setted : $share_server_ip"
      ;;
  * ) echo "The installation way is unknown! Bye :("
      exit;;
esac

echo "Use autostart of ipmimon (yes or no)? Use one only if you have enough resorces."
read auto_ipmimon
echo "Create SWAP-file? (yes\no):"
read bool_swap_file
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
echo "Used cores: 2 - $last_cpu_core"
case $use_analizpack in
  [yY]es ) echo "Analizpack will be used";;
  * ) echo "Analizpack will not be used";;
esac
case $auto_ipmimon in
  [yY]es ) echo "ipmimon.service is in autostart mode";;
  * ) echo "ipmimon.service is not in autostart mode";;
esac
case $bool_swap_file in
  [yY]es ) echo "create SWAP-file";;
  * ) echo "don't create SWAP-file";;
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

#cp -r ./auto/ /home/user/

sed -i 's/^[0-9A-Za-z]/\#&/g' $file_repo

apt-get update

dpkg -i /home/user/auto/deb_ubuntu16/*.deb
ln /usr/lib/libipmimonitoring.so /usr/lib/libipmimonitoring.so.6

#Making SWAP-file
case $bool_swap_file in
  [yY]es )  make_swap
	    ;;
  * ) ;;
esac


# installing programs
mkdir /home/user/programs/
case $response_pu in
  0 ) tar -xf /home/user/auto/programs/83/programs.tar.gz -C /home/user/programs/
      cp /home/user/auto/programs/83/lib/*.so /usr/lib/
      mkdir /mnt/ram_disk/
      printf "tmpfs     /mnt/ram_disk     tmpfs     rw,size=20G,x-gvfs-show     0 0\n" >> /etc/fstab
      mount -a      
      ;;
  1 ) tar -xf /home/user/auto/programs/NT/programs.tar.gz -C /home/user/programs/
      cp /home/user/auto/programs/NT/lib/*.so /usr/lib/
      ;;
  2 ) tar -xf /home/user/auto/programs/2I/programs.tar.gz -C /home/user/programs/
      cp /home/user/auto/programs/2I/lib/*.so /usr/lib/
      ;;
  * ) echo "КОСЯК! Вариант реализации пультовой части: Неизвестно"
      ;;
esac

echo "* hard nofile 500000" >> /etc/security/limits.conf
echo "* soft nofile 500000" >> /etc/security/limits.conf
echo "root hard nofile 500000" >> /etc/security/limits.conf
echo "root soft nofile 500000" >> /etc/security/limits.conf

setcap cap_sys_ptrace=iep /home/user/programs/wrhg64/wrhg
setcap cap_sys_ptrace=iep /home/user/programs/sorm/sorm

cp /home/user/programs/library/libCPSData_1.so /usr/lib/
cp /home/user/programs/library/libm83m.so /usr/lib/
cp /home/user/programs/library/libUDPCapt.so /usr/lib/
cp /home/user/programs/library/libm2nt.so /usr/lib/

cat /home/user/auto/programs/net_conf_ubuntu.txt >> /etc/sysctl.conf

# Configuration FTP
cp /etc/vsftpd.conf /etc/vsftpd.conf.orig
cat /home/user/auto/programs/ftp_config.txt > /etc/vsftpd.conf
/etc/init.d/vsftpd restart

case $use_analizpack in
  [yY]es )  install_analizpack
	    ;;
  * ) 	;;
esac

# installing DPDK
cpu_cores=$( echo $(seq -s ',' 4 1 $last_cpu_core) | sed -e "s/$res,//" )
mkdir /home/user/DPDK/
chown user:user /home/user/DPDK/
cp /home/user/auto/DPDK/dpdk-16.11.4.tar.xz /home/user/DPDK/
cd /home/user/DPDK/
tar xf ./dpdk-16.11.4.tar.xz
cd ./dpdk-stable-16.11.4/
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
echo "/home/user/DPDK/dpdk-stable-16.11.4/x86_64-native-linuxapp-gcc/lib/" | tee -a /etc/ld.so.conf.d/librte.conf
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
cp /home/user/auto/libhtgiolib/libhtgiolib.so.1.3.2 /home/user/DPDK/
ln -s /home/user/DPDK/libhtgiolib.so.1.3.2 /usr/lib/libhtgiolib.so
ln -s /lib/x86_64-linux-gnu/libprocps.so.4 /lib/x86_64-linux-gnu/libprocps.so.3
cp /home/user/auto/boost/* /usr/lib/x86_64-linux-gnu/
#sed -i -e '/^exit 0/i/home/user/programs/run.sh' /etc/rc.local

#Binding 10G interfaces to DPDK
echo '#!/bin/bash' > $file_run_sh
export RTE_SDK=/home/user/DPDK/dpdk-stable-16.11.4
echo 'export RTE_SDK=/home/user/DPDK/dpdk-stable-16.11.4' >> $file_run_sh
export RTE_TARGET=x86_64-native-linuxapp-gcc
echo 'export RTE_TARGET=x86_64-native-linuxapp-gcc' >> $file_run_sh
cd /home/user/DPDK/dpdk-stable-16.11.4
echo 'cd /home/user/DPDK/dpdk-stable-16.11.4' >> $file_run_sh
modprobe uio 
echo 'modprobe uio' >> $file_run_sh
insmod /home/user/DPDK/dpdk-stable-16.11.4/x86_64-native-linuxapp-gcc/kmod/igb_uio.ko
echo 'insmod /home/user/DPDK/dpdk-stable-16.11.4/x86_64-native-linuxapp-gcc/kmod/igb_uio.ko' >> $file_run_sh
cd /home/user/DPDK/dpdk-stable-16.11.4/tools/
echo 'cd /home/user/DPDK/dpdk-stable-16.11.4/tools/' >> $file_run_sh
for tmp_str in $(./dpdk-devbind.py -s | awk '/X710|X540/ {print $1}')
do
  ./dpdk-devbind.py -u $tmp_str
  echo './dpdk-devbind.py -u' $tmp_str >> $file_run_sh
  ./dpdk-devbind.py --bind=igb_uio $tmp_str
  echo './dpdk-devbind.py --bind=igb_uio' $tmp_str >> $file_run_sh
done
export LD_LIBRARY_PATH=/home/user/DPDK/dpdk-stable-16.11.4/x86_64-native-linuxapp-gcc/lib
echo 'export LD_LIBRARY_PATH=/home/user/DPDK/dpdk-stable-16.11.4/x86_64-native-linuxapp-gcc/lib' >> $file_run_sh

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