" L1/L2/L3/L4/L6/L7: Low群修正の回帰テスト

" L7: "#foo"（スペースなし）も見出しとして認識する
%delete _
call setline(1, ['#foo'])
call cursor(1, 1)
MDH1
call assert_equal('foo', getline(1))

" L6: テーブルセル内の "|" はエスケープされる
%delete _
call setline(1, ['a|b,c'])
1MDTable
call assert_equal(['| a\|b | c |', '| --- | --- |'], getline(1, '$'))

" L4: 補完関数は正規表現特殊文字を含む arglead でもエラーにならない
call assert_equal([], amnesia#complete_lang('c++', '', 0))
call assert_equal(['c', 'cpp', 'csharp', 'css'], amnesia#complete_lang('c', '', 0))

" L3: MDLink/MDImage の URL に "|" を含められる
%delete _
call setline(1, [''])
call cursor(1, 1)
MDLink https://example.com/a|b
call assert_equal('[](https://example.com/a|b)', getline(1))

" L1: MDFiletype に明示的な Ex 範囲を付けるとエラーになる
%delete _
call setline(1, ['a', 'b'])
let v:errmsg = ''
try
    1,2MDFiletype
    call assert_report('MDFiletype should reject an explicit line range')
catch
    " Vim標準のE481（範囲非対応コマンド）が期待される
endtry

" L2: hr/filetype にはビジュアルモードの<Plug>が定義されていない
call assert_equal('', maparg('<Plug>(amnesia-hr)', 'x'))
call assert_equal('', maparg('<Plug>(amnesia-filetype)', 'x'))
call assert_notequal('', maparg('<Plug>(amnesia-hr)', 'n'))
call assert_notequal('', maparg('<Plug>(amnesia-filetype)', 'n'))
