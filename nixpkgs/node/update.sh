#!/bin/bash
DIR="$(cd "$(dirname "$0")"; pwd -P)"

nix-shell -p nodePackages.node2nix --command "cd $DIR && node2nix -14 -i packages.json"
