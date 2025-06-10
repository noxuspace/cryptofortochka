#!/bin/bash
set -e

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

