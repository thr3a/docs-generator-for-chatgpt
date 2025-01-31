#!/bin/bash

# リポジトリのURL
REPO_URL="https://github.com/astral-sh/uv.git"
# クローン先ディレクトリ名
CLONE_DIR="uv"
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
echo > $OUTPUT_FILE
find "$CLONE_DIR/docs/" -name "*.md" -type f ! -name "index.md" | while read file; do
    echo -e "\n# $(basename "$file")\n" >> $OUTPUT_FILE
    cat "$file" >> $OUTPUT_FILE
done
docker run --rm -v ./:/app thr3a/remove-markdown-links $OUTPUT_FILE --override

# クローンしたディレクトリを削除
# rm -rf "$CLONE_DIR"
