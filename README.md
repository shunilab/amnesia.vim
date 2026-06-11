# amnesia.vim

> Write Markdown without remembering Markdown.

md 記法を忘れても Markdown が書ける Vim / Neovim プラグイン。記法は `:MD` まで打って補完で思い出せばいい。Notion ライクなコマンド群が、挿入・範囲ラップ・トグルを引き受ける。

旧 myvim の自作スクリプト marksman（Markdown LSP と同名だったため改名）を単体プラグイン化したもの。Vim script 製で Vim / Neovim 両対応。コマンド定義のみ起動時に読み、本体は autoload で遅延ロードする。

## コマンド一覧

すべて範囲指定（ビジュアル選択）対応。範囲なしならカーソル行・カーソル位置に作用する。

| コマンド | 動作 |
|---|---|
| `:MDH1` / `:MDH2` / `:MDH3` | 見出しレベルを設定（同レベル再実行でトグル） |
| `:MDBullet` | 箇条書き `- ` をトグル |
| `:MDNumber` | 番号付きリスト（ネストは `1.` → `a.` → `i.` と自動切替） |
| `:MDCheck` / `:MDCheckDone` | チェックボックス `- [ ]` / `- [x]` |
| `:MDQuote` | 引用 `> ` をトグル |
| `:MDBold` / `:MDItalic` / `:MDInlineCode` | `**` / `*` / `` ` `` でラップ（再実行でトグル） |
| `:MDCode [lang]` | コードブロック（選択範囲をフェンスで包む／その場に挿入） |
| `:MDLink [text] [url]` | リンク。引数や選択テキストが URL かどうかで挿入形を自動判別 |
| `:MDImage [alt] [url]` | 画像。判別ロジックは MDLink と同様 |
| `:MDTable` | テーブル雛形挿入。選択範囲が CSV / タブ区切りなら表へ変換 |
| `:MDFootnote` | 脚注参照を挿入し、定義を文書末尾へ追加 |
| `:MDHR` | 水平線 `---` |
| `:IndentTree` | インデントテキストを `├──` / `└──` の ASCII ツリーへ変換 |

## インストール

Neovim（vim.pack）:

```lua
vim.pack.add({ 'https://github.com/shunilab/amnesia.vim' })
```

Vim（vim-plug）:

```vim
Plug 'shunilab/amnesia.vim'
```
