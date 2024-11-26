#!/bin/bash

REPO_URL="https://github.com/jdx/mise.git"
REPO_DIR="mise"

if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git pull
    cd ..
else
    echo "リポジトリをクローンします"
    git clone --depth 1 "$REPO_URL"
fi

cat mise/docs/cli/*.md mise/docs/configuration.md > mise.md

# "**Source code**"の行を削除
sed -i '/\*\*Source code\*\*/d' mise.md

# rm -rf "$REPO_DIR"
