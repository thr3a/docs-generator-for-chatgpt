#!/bin/bash

# リポジトリのURL
REPO_URL="https://github.com/BerriAI/litellm.git"
REPO_DIR="litellm"
DOCS_DIR="docs/my-website/docs"
OUTPUT_FILE="index.md"

# リポジトリが存在するかチェック
if [ ! -d "$REPO_DIR" ]; then
    echo "リポジトリをクローンします..."
    git clone --depth 1 "$REPO_URL"
else
    echo "リポジトリを更新します..."
    cd "$REPO_DIR"
    git pull
    cd ..
fi

# 出力ファイルを初期化
> "$OUTPUT_FILE"

# docs/my-website/docs内のすべての.mdファイルを結合
if [ -d "$REPO_DIR/$DOCS_DIR" ]; then
    echo "Markdownファイルを結合しています..."
    find "$REPO_DIR/$DOCS_DIR" -name "*.md" -type f | while read file; do
        echo -e "\n\n# $(basename "$file" .md)\n" >> "$OUTPUT_FILE"
        cat "$file" >> "$OUTPUT_FILE"
    done
    echo "ファイルの結合が完了しました"
else
    echo "ドキュメントディレクトリが見つかりません"
fi

rm -rf $REPO_DIR

echo "処理が完了しました"
