#!/bin/bash

# リポジトリのURL
REPO_URL="https://github.com/BerriAI/litellm.git"
# クローン先ディレクトリ名
CLONE_DIR="litellm"
# 出力ファイル名
OUTPUT_FILE="index.md"

# クローンディレクトリの存在確認
if [ ! -d "$CLONE_DIR" ]; then
    # ディレクトリが存在しない場合、depth 1でクローン
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
else
    # ディレクトリが存在する場合、pull
    cd "$CLONE_DIR"
    git pull
    cd ..
fi

# 必要なファイルを結合
cat "$CLONE_DIR/docs/my-website/docs/proxy/config_settings.md" \
    "$CLONE_DIR/docs/my-website/docs/proxy/configs.md" \
    > "$OUTPUT_FILE"

# クローンしたディレクトリを削除
rm -rf "$CLONE_DIR"
