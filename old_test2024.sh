#!/bin/bash
set -e

apt update
apt install -y wget screen curl sudo

curl -L https://github.com/cysic-labs/cysic-phase3/releases/download/v1.0.0/setup_prover.sh > ~/setup_prover.sh && \
bash ~/setup_prover.sh 0x66755D560e4447C7D2a50AcBB119d4896B6eAad3 https://eth-mainnet.g.alchemy.com/v2/PQz9FYqFUrRfkkO6UPjRkxW66KGrX90U

for i in {1..10}; do
  SESSION="prover$i"
  DIR="$HOME/cysic-prover$i"

  echo "Запускаем сессию $SESSION → cd $DIR && bash start.sh"
  screen -dmS "$SESSION" bash -c "cd \"$DIR\" && bash start.sh"

  sleep 10
done

echo "Сессии prover1–prover10 созданы."
echo "Посмотреть активные сессии: screen -ls"
echo "Подключиться к конкретной: screen -r proverX"

