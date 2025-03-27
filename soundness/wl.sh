#!/bin/bash

if ! command -v rustc &> /dev/null; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source $HOME/.cargo/env
        else
            rustup update
            source $HOME/.cargo/env
        fi

source $HOME/.cargo/env

curl -sSL https://raw.githubusercontent.com/soundnesslabs/soundness-layer/main/soundnessup/install | bash
source ~/.bashrc

soundnessup install
sleep 2
soundnessup update

soundness-cli generate-key --name my-key
