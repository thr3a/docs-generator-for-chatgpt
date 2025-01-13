#!/bin/bash

# リポジトリのURL
REPO_URL="https://github.com/basecamp/kamal-site.git"
# クローン先ディレクトリ名
CLONE_DIR="kamal"
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
find "$CLONE_DIR/docs/configuration/" -name "*.md" -type f | while read file; do
  echo -e "\n# $(basename "$file")\n" >> $OUTPUT_FILE
  # 先頭のYAML Front Matter（---で囲まれた部分）を除去
  cat "$file" | sed '1{/^---$/!q;};1,/^---$/d' >> $OUTPUT_FILE
done

find "$CLONE_DIR/docs/commands/" -name "*.md" -type f | while read file; do
  echo -e "\n# $(basename "$file")\n" >> $OUTPUT_FILE
  # 先頭のYAML Front Matter（---で囲まれた部分）を除去
  cat "$file" | sed '1{/^---$/!q;};1,/^---$/d' >> $OUTPUT_FILE
done

docker run --rm -v ./:/app thr3a/remove-markdown-links index.md --override

# クローンしたディレクトリを削除
rm -rf "$CLONE_DIR"
