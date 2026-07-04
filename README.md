# amnesia.vim

> Write Markdown without remembering Markdown.

記憶喪失になっても Markdown が書ける Vim / Neovim プラグイン。記法は `:MD` まで打って補完で思い出せばいい。Notion ライクなコマンド群が、挿入・範囲ラップ・トグルを引き受ける。

Vim script 製で Vim / Neovim 両対応。コマンド定義のみ起動時に読み、本体は autoload で遅延ロードする。

## 動作環境

Vim 8.2.2233 以降 / Neovim 0.6 以降が必要（`charidx()` / `<Cmd>` マッピングを使用しているため）。

## コマンド一覧

範囲指定には、ビジュアル選択と Ex 範囲指定がある。ビジュアル選択は選択テキストへの自然な適用として扱う。Ex 範囲指定は `:%MDQuote` のように行範囲へ一括適用する操作で、行単位で意味があるコマンドのみ対応する。

Ex 範囲指定に対応するコマンドは、`MDBullet` / `MDNumber` / `MDCheck` / `MDCheckDone` / `MDQuote` / `MDCode` / `MDTable` / `IndentTree`。それ以外のコマンドに明示的な Ex 範囲を付けた場合は、誤操作防止のためエラーにする。

見出し・箇条書き・チェックボックス・引用・コードブロック・テーブル等、行単位で意味を持つコマンドは、ビジュアル選択が行の一部（文字単位）であっても選択範囲の行全体に適用される。`MDBold` / `MDItalic` / `MDInlineCode` / `MDLink` / `MDImage` / `MDFootnote` はブロック選択（Ctrl-V）に対応しておらずエラーになる。

| コマンド | 動作 |
|---|---|
| `:MDH1` / `:MDH2` / `:MDH3` | 見出しレベルを設定（同レベル再実行でトグル）。明示的な Ex 範囲指定は非対応 |
| `:MDBullet` | 箇条書き `- ` をトグル。Ex 範囲指定対応 |
| `:MDNumber` | 番号付きリスト。既定では全深さ `1.`（GFM準拠）で、選択済みならトグル解除。`g:amnesia_number_style = 'fancy'` で `1.` → `a.` → `i.` のネスト切替に変更可（GFMではリストと解釈されない点に注意）。Ex 範囲指定対応 |
| `:MDCheck` / `:MDCheckDone` | チェックボックス `- [ ]` / `- [x]`（相互変換・同状態への再実行でトグル解除・既存の箇条書き行への昇格に対応）。Ex 範囲指定対応 |
| `:MDQuote` | 引用 `> ` をトグル。Ex 範囲指定対応 |
| `:MDBold` / `:MDItalic` / `:MDInlineCode` | `**` / `*` / `` ` `` でラップ（再実行でトグル）。明示的な Ex 範囲指定は非対応 |
| `:MDCode [lang]` | コードブロック（選択範囲または Ex 範囲指定をフェンスで包む／その場に挿入）。`[lang]` は Tab 補完可能 |
| `:MDLink [text] [url]` | リンク。引数や選択テキストが URL かどうかで挿入形を自動判別。明示的な Ex 範囲指定は非対応 |
| `:MDImage [alt] [url]` | 画像。判別ロジックは MDLink と同様。明示的な Ex 範囲指定は非対応 |
| `:MDTable` | テーブル雛形挿入。選択範囲または Ex 範囲指定が CSV / タブ区切りなら表へ変換（セル内の `\|` は自動エスケープ） |
| `:MDFootnote` | 選択テキストを脚注参照に置き換え、定義を文書末尾へ追加（バッファ内の既存脚注から連番を自動採番）。選択なしなら参照をカーソル位置に挿入し、空の定義を末尾に追加して挿入モードに入る。明示的な Ex 範囲指定は非対応 |
| `:MDHR` | 水平線 `---` をカーソル行の下に挿入。範囲指定は非対応 |
| `:MDFiletype` | カレントバッファのファイルタイプをMDにする。範囲指定は非対応 |
| `:IndentTree` | インデントテキストを `├──` / `└──` の ASCII ツリーへ変換。Ex 範囲指定対応 |

詳細は `:h amnesia`。

## キーマッピング

デフォルトキーは提供しない。ほぼ全コマンドに対応する `<Plug>(amnesia-*)` をノーマル / ビジュアル両モードで公開しているので、任意に割り当てる（`hr` / `filetype` はビジュアル選択に意味を持たないためノーマルモードのみ）：

```vim
xmap <Leader>b <Plug>(amnesia-bold)
nmap <Leader>c <Plug>(amnesia-check)
```

一覧は `:h amnesia-plug`。

## インストール

本体は autoload で遅延ロードされるため、プラグインマネージャー側での遅延設定は不要。

Neovim（vim.pack / 0.12+）:

```lua
vim.pack.add({ 'https://github.com/shunilab/amnesia.vim' })
```

Neovim（lazy.nvim）:

```lua
{ 'shunilab/amnesia.vim' }
```

Vim（vim-plug）:

```vim
Plug 'shunilab/amnesia.vim'
```

Vim（minpac）:

```vim
call minpac#add('shunilab/amnesia.vim')
```

プラグインマネージャー無し（Vim 8+ / Neovim 標準の packages 機構）:

```sh
# Vim
git clone https://github.com/shunilab/amnesia.vim \
  ~/.vim/pack/plugins/start/amnesia.vim

# Neovim
git clone https://github.com/shunilab/amnesia.vim \
  ~/.local/share/nvim/site/pack/plugins/start/amnesia.vim
```

## ライセンス

[MIT](LICENSE)
