" amnesia.vim - Write Markdown without remembering Markdown
" コマンド定義のみ。本体は autoload/amnesia.vim（初回実行時にロード）

if exists('g:loaded_amnesia')
    finish
endif
let g:loaded_amnesia = 1

command! -range -nargs=* -bar -complete=customlist,amnesia#complete_lang MDCode call amnesia#code_block({'line1': <line1>, 'line2': <line2>, 'range': <range>}, <q-args>)
command! -range -bar MDH1 call amnesia#h1({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDH2 call amnesia#h2({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDH3 call amnesia#h3({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDH4 call amnesia#h4({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDH5 call amnesia#h5({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDH6 call amnesia#h6({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDBullet call amnesia#bullet({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDNumber call amnesia#numbered({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDCheck call amnesia#checkbox({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDQuote call amnesia#quote({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDBold call amnesia#bold({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDItalic call amnesia#italic({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -nargs=* MDLink call amnesia#link({'line1': <line1>, 'line2': <line2>, 'range': <range>}, <q-args>)
command! -range -nargs=* MDImage call amnesia#image({'line1': <line1>, 'line2': <line2>, 'range': <range>}, <q-args>)
command! -range -bar MDHR call amnesia#hr({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDInlineCode call amnesia#inline_code({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDStrike call amnesia#strike({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDHighlight call amnesia#highlight({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDTable call amnesia#table({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDCheckDone call amnesia#checkbox_done({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDFootnote call amnesia#footnote({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -bar MDFiletype setlocal filetype=markdown
command! -range -bar IndentTree call amnesia#indent_tree({'line1': <line1>, 'line2': <line2>, 'range': <range>})

" <Plug>マッピング（デフォルトキーは提供しない・利用者が任意に割当）
" ノーマル/ビジュアル両モードに対応するコマンド群
for s:pair in [
    \ ['h1', 'MDH1'], ['h2', 'MDH2'], ['h3', 'MDH3'],
    \ ['h4', 'MDH4'], ['h5', 'MDH5'], ['h6', 'MDH6'],
    \ ['bullet', 'MDBullet'], ['number', 'MDNumber'],
    \ ['check', 'MDCheck'], ['check-done', 'MDCheckDone'],
    \ ['quote', 'MDQuote'], ['bold', 'MDBold'], ['italic', 'MDItalic'],
    \ ['inline-code', 'MDInlineCode'], ['code', 'MDCode'],
    \ ['strike', 'MDStrike'], ['highlight', 'MDHighlight'],
    \ ['link', 'MDLink'], ['image', 'MDImage'],
    \ ['table', 'MDTable'], ['footnote', 'MDFootnote'],
    \ ['indent-tree', 'IndentTree'],
    \ ]
    execute printf('nnoremap <silent> <Plug>(amnesia-%s) :%s<CR>', s:pair[0], s:pair[1])
    execute printf('xnoremap <silent> <Plug>(amnesia-%s) <Cmd>call amnesia#visual_dispatch(%s)<CR>', s:pair[0], string(s:pair[1]))
endfor
unlet s:pair

" hr / filetype はビジュアル選択に意味を持たないため、ノーマルモードのみ提供する
nnoremap <silent> <Plug>(amnesia-hr) :MDHR<CR>
nnoremap <silent> <Plug>(amnesia-filetype) :MDFiletype<CR>
