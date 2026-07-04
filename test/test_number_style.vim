" M3: g:amnesia_number_style によるネスト記法の切替、
" M4: 全行番号付き選択のトグル解除、誤エラーメッセージ修正の回帰テスト

" デフォルト（numeric）は全深さ数字
%delete _
call setline(1, ['one', '  two', '  three', 'four'])
1,4MDNumber
call assert_equal(['1. one', '  1. two', '  2. three', '2. four'], getline(1, '$'))

" fancy指定で従来の a./i. 切替
%delete _
let g:amnesia_number_style = 'fancy'
call setline(1, ['one', '  two', '  three', 'four'])
1,4MDNumber
call assert_equal(['1. one', '  a. two', '  b. three', '2. four'], getline(1, '$'))
unlet g:amnesia_number_style

" M4: 全行番号付きならトグル解除
%delete _
call setline(1, ['1. one', '2. two'])
1,2MDNumber
call assert_equal(['one', 'two'], getline(1, '$'))

" M4: 単一行（範囲なし）でも往復でトグルする
%delete _
call setline(1, ['task'])
call cursor(1, 1)
MDNumber
call assert_equal('1. task', getline(1))
MDNumber
call assert_equal('task', getline(1))

" 誤エラーメッセージ修正: MDNumberでタブインデントのエラーはMDNumber名で出る
%delete _
call setline(1, ['one', "\ttwo"])
try
    1,2MDNumber
catch /.*/
    call assert_match('MDNumber does not support tabs', v:exception)
endtry
