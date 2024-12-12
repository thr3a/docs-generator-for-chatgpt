import requests
from bs4 import BeautifulSoup
import csv
import re


def clean_text(text):
    # 改行、空白を整理して1行のテキストにする
    text = re.sub(r"\s+", " ", text.strip())
    return text


def main():
    # URLからデータを取得
    url = "https://shinagawa-sodai.com/receipts/home/item"
    response = requests.get(url)
    response.encoding = "utf-8"

    # BeautifulSoupでパース
    soup = BeautifulSoup(response.text, "html.parser")

    # テーブルを見つける
    table = soup.find("table", class_="table")

    # CSVファイルを書き込みモードで開く
    with open("sodaigomi.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        # ヘッダーを書き込む
        writer.writerow(["分類", "品目名", "料金"])

        # 各行を処理
        for row in table.find_all("tr")[1:]:  # ヘッダー行をスキップ
            cols = row.find_all("td")
            if len(cols) >= 4:
                # 分類
                category = clean_text(cols[1].get_text())

                # 品目名 (brとdivを削除)
                item_name = clean_text(
                    cols[2].get_text().replace("◆", "").replace("◇", "")
                )

                # 料金 (brを削除)
                price_cell = cols[3]
                for br in price_cell.find_all("br"):
                    br.decompose()
                price = clean_text(price_cell.text)

                # CSVに書き込む
                writer.writerow([category, item_name, price])


if __name__ == "__main__":
    main()
