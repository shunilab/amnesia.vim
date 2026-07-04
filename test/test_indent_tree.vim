" IndentTree: インデント -> ASCIIツリー変換の回帰テスト

call setline(1, ['root', '  child1', '  child2', '    grandchild'])
1,4IndentTree
call assert_equal(['root', '├── child1', '└── child2', '    └── grandchild'], getline(1, '$'))
