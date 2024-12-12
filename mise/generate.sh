#!/bin/bash

REPO_URL="https://github.com/jdx/mise.git"
REPO_DIR="mise"

if [ ! -d "$REPO_DIR" ]; then
    echo "リポジトリをクローン"
    git clone --depth 1 "$REPO_URL"
else
    echo "リポジトリを更新"
    cd "$REPO_DIR"
    git pull
    cd ..
fi

FILES_TO_DELETE=(
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

# mise/docs以下の全mdファイルを結合
echo > mise.md
find mise/docs -name "*.md" -type f | while read file; do
    echo -e "\n# $(basename "$file")\n" >> mise.md
    cat "$file" >> mise.md
done

# "**Source code**"の行を削除
sed -i '/\*\*Source code\*\*/d' mise.md

rm -rf mise

