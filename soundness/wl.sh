#!/bin/bash

if ! command -v docker &> /dev/null; then
            sudo apt install docker.io -y

https://github.com/icodragon/soundness-layer -b feat/docker-soundness-cli && cd soundness-layer/soundness-cli
sleep 1

docker compose build
sleep 2

docker compose run --rm soundness-cli generate-key --name my-key
