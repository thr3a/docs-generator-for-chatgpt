#!/bin/bash

# リポジトリのURL
REPO_URL="https://github.com/jdx/mise.git"
# クローン先ディレクトリ名
CLONE_DIR="mise"
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

FILES_TO_DELETE=(
    "mise/docs/external-resources.md"
    "mise/docs/tips-and-tricks.md"
    "mise/docs/about.md"
    "mise/docs/team.md"
    "mise/docs/project-roadmap.md"
    "mise/docs/contributing.md"
    "mise/docs/paranoid.md"
    "mise/docs/rtx.md"
    "mise/docs/how-i-use-mise.md"
    "mise/docs/cli/index.md"
    "mise/docs/getting-started.md"
    "mise/docs/walkthrough.md"
    "mise/docs/registry.md"
)

for file in "${FILES_TO_DELETE[@]}"; do
    if [ -f "$file" ]; then
        echo $file
        rm "$file"
    fi
done

# 必要なファイルを結合
echo > $OUTPUT_FILE
find "$CLONE_DIR/docs/" -name "*.md" -type f | while read file; do
    echo -e "\n# $(basename "$file")\n" >> $OUTPUT_FILE
    cat "$file" >> $OUTPUT_FILE
done
docker run --rm -v ./:/app thr3a/remove-markdown-links $OUTPUT_FILE --override

# "**Source code**"の行を削除
sed -i '/\*\*Source code\*\*/d' mise.md

# クローンしたディレクトリを削除
# rm -rf "$CLONE_DIR"
