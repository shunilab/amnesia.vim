" amnesia.vim - Write Markdown without remembering Markdown
" コマンド定義のみ。本体は autoload/amnesia.vim（初回実行時にロード）

if exists('g:loaded_amnesia')
    finish
endif
let g:loaded_amnesia = 1

command! -range -nargs=* -bar MDCode call amnesia#code_block({'line1': <line1>, 'line2': <line2>, 'range': <range>}, <q-args>)
command! -range -bar MDH1 call amnesia#h1({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDH2 call amnesia#h2({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDH3 call amnesia#h3({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDBullet call amnesia#bullet({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDNumber call amnesia#numbered({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDCheck call amnesia#checkbox({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDQuote call amnesia#quote({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDBold call amnesia#bold({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDItalic call amnesia#italic({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -nargs=* -bar MDLink call amnesia#link({'line1': <line1>, 'line2': <line2>, 'range': <range>}, <q-args>)
command! -range -nargs=* -bar MDImage call amnesia#image({'line1': <line1>, 'line2': <line2>, 'range': <range>}, <q-args>)
command! -range -bar MDHR call amnesia#hr({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDInlineCode call amnesia#inline_code({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDTable call amnesia#table({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDCheckDone call amnesia#checkbox_done({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar MDFootnote call amnesia#footnote({'line1': <line1>, 'line2': <line2>, 'range': <range>})
command! -range -bar IndentTree call amnesia#indent_tree({'line1': <line1>, 'line2': <line2>, 'range': <range>})
