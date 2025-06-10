#!/bin/bash
set -e

apt update
apt install -y screen curl

for i in {1..20}; do cp -a --force /root/cysic-prover/ /root/cysic-prover$i/; done

for i in {1..20}; do
  SESSION="prover$i"
  DIR="$HOME/cysic-prover$i"

  echo "Запускаем сессию $SESSION → cd $DIR && bash start.sh"
  screen -dmS "$SESSION" bash -c "cd \"$DIR\" && bash start.sh"

  sleep 10
done

echo "Сессии prover1–prover10 созданы."
echo "Посмотреть активные сессии: screen -ls"
echo "Подключиться к конкретной: screen -r proverX"

