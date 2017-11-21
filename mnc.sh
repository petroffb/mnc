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
echo "Сначала читай текст ВНИМАТЕЛЬНО, потом читай ЕЩЁ ВНИМАТЕЛЬНЕЕ, потом ДУМАЙ, потом уже вводи данные!"
srv_clnt=2
time_syncro_srv_port=0
time_syncro_srv_ip=""
while [ $srv_clnt == 2 ]; do
  echo "Выбор варианта установки ПО:"
  printf "0 - [S]erver\n1 - [C]lient\n"
  read response
  case $response in
  0|[sS]* ) echo "Выбран вариант Server"
      srv_clnt="server";;
  1|[cC]* ) echo "Выбран вариант Client"
      srv_clnt="client";;
  * ) echo "Ваще тупой, да? Давай ещё раз попробуй.";;
  esac
done
echo "Вариант реализации пультовой части:"
while [[ $response_pu != [0-1] ]]; do
printf "0 - 83 приказ\n1 - NT\n"
read response_pu
done
case $response_pu in
  0 ) echo "Вариант реализации пультовой части: 83 приказ";;
  1 ) echo "Вариант реализации пультовой части: NT";;
  * ) echo "КОСЯК! Вариант реализации пультовой части: Неизвестно"
      exit;;
esac
case $srv_clnt in
  "server" ) while [[ $time_syncro_srv_port -le 1024 || $time_syncro_srv_port -gt 65535 ]]; do
      echo "Порт [1025 - 65535] для подключения клиентов time_syncro (по умолчанию 27333) : "
      read time_syncro_srv_port
      if [ -z $time_syncro_srv_port ]
      then time_syncro_srv_port=27333
      else :
      fi
      done
      echo "Выбран порт для подключения клиентов time_syncro: $time_syncro_srv_port"
      echo "IP-адрес для share-сервера (для тех, кто в танке - адрес этого сервера):"
      read share_server_ip
      echo "Установлен адрес share-сервера: $share_server_ip"
      ;;
  "client" ) while [[ -z $time_syncro_srv_ip ]]; do
      echo "Адрес сервера time_syncro:"
      read time_syncro_srv_ip
      done
      while [[ $time_syncro_srv_port -le 1024 || $time_syncro_srv_port -gt 65535 ]]; do
      echo "Порт [1025 - 65535] для подключения клиентов time_syncro (по умолчанию 27333) : "
      read time_syncro_srv_port
      if [ -z $time_syncro_srv_port ]
      then time_syncro_srv_port=27333
      else 
      :
      fi
      done
      echo "Выбран порт для подключения клиентов time_syncro: $time_syncro_srv_port"
      echo "Период опроса сервера time_syncro (в минутах):"
      read time_syncro_period
      echo "Установлен период опроса сервера time_syncro (в минутах): $time_syncro_period"
      echo "IP-адресс для share-сервера:"
      read share_server_ip
      echo "Установлен адрес share-сервера: $share_server_ip"
      ;;
  * ) echo "Нет понятия о варианте установки"
      exit;;
esac
echo "Введите через пробел диапазон ядер для изоляции:"
read first_cpu_core last_cpu_core
echo "Используются следующие параметры:"
echo "Вариант установки ПО - $srv_clnt"
if [ $srv_clnt == "server" ]
then
  echo "Порт для подключения клиентов time_syncro - $time_syncro_srv_port"
  echo "IP-адресс share-сервера - $share_server_ip"
else
  echo "Адрес сервера time_syncro - $time_syncro_srv_ip:$time_syncro_srv_port"
  echo "Период опроса сервера time_syncro (в минутах): $time_syncro_period"
  echo "IP-адресс share-сервера - $share_server_ip"
fi
echo "Используются ядра $first_cpu_core - $last_cpu_core"
echo -n "Всё верно?(если да - пиши 'ок'): "
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
echo "/home/user/DPDK/dpdk-stable-16.11.3/x86_64-native-linuxapp-gcc/lib/" | tee -a /etc/ld.so.conf.d/librte.conf
cp /home/user/auto/other/dpdkbind.service /etc/systemd/system/
cp /home/user/auto/other/ipmimon.service /etc/systemd/system/
systemctl enable dpdkbind.service
systemctl enable ipmimon.service
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