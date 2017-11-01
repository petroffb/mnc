#!/bin/bash

cond="bad"
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
      echo "IP-адресс для share-сервера (для тех, кто в танке - адрес этого сервера):"
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
      else :
      fi
      done
      echo "IP-адресс для share-сервера:"
      read share_server_ip
      echo "Установлен адрес share-сервера: $share_server_ip"
      ;;
  * ) echo "Нет понятия о варианте установки"
      exit;;
esac
echo "Номер первого ядра:"
read first_cpu_core
echo "Номер последнего ядра:"
read last_cpu_core
echo "Используются следующие параметры:"
echo "Вариант установки ПО - $srv_clnt"
if [ $srv_clnt == "server" ]
then
echo "Порт для подключения клиентов time_syncro - $time_syncro_srv_port"
echo "IP-адресс share-сервера - $share_server_ip"
else
echo "Адрес сервера time_syncro - $time_syncro_srv_ip:$time_syncro_srv_port"
echo "IP-адресс share-сервера - $share_server_ip"
fi
echo "Используются ядра $first_cpu_core - $last_cpu_core"
echo "Всё верно?(если да - пиши 'ок')"
read cond
done