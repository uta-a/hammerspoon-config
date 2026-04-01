# hammerspoon-config

macOS 用ウィンドウマネージャ [Hammerspoon](https://www.hammerspoon.org/) の個人設定。

## 機能

### ウィンドウ操作

| キー | 動作 |
|------|------|
| `Option + F` | ギャップ付きフルスクリーン（各辺10px） |
| `Option + C` | 中央配置（サイズはそのまま） |
| `Option + V` | 1200x800 にリサイズ |

### Caps Lock LED ↔ IME 連動

日本語入力がオンのとき Caps Lock の LED を点灯させ、IME の状態を視覚的に確認できるようにする。

外部バイナリ [`setleds`](https://github.com/damieng/setledsmac) が必要。

## セットアップ

1. [Hammerspoon](https://www.hammerspoon.org/) をインストール
2. このリポジトリをクローン
   ```bash
   git clone https://github.com/uta-a/hammerspoon-config.git
   ```
3. `~/.hammerspoon` にシンボリックリンクを作成（既存の設定があればバックアップ）
   ```bash
   mv ~/.hammerspoon ~/.hammerspoon.bak  # 既存設定のバックアップ
   ln -s /path/to/hammerspoon-config ~/.hammerspoon
   ```
4. `bin/setleds` を用意（Caps Lock LED 連動を使う場合）
   ```bash
   git clone https://github.com/damieng/setledsmac.git
   cd setledsmac
   make
   cp bin/setleds ~/.hammerspoon/bin/
   ```
5. Hammerspoon を再起動（メニューバー → Reload Config）
