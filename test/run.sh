#!/usr/bin/env bash
# amnesia.vim テストランナー。test/test_*.vim を vim と（あれば）nvim の両方で実行する。
set -uo pipefail
cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"

overall_status=0

for runner in vim nvim; do
    if ! command -v "$runner" >/dev/null 2>&1; then
        echo "skip: $runner not found"
        continue
    fi

    echo "== running with $runner ($("$runner" --version | head -1)) =="

    for test_file in test/test_*.vim; do
        errfile="$(mktemp)"
        # source 中に assert 以外の例外（未定義関数・構文エラー等）が起きると
        # スクリプトがその場で中断し、以降の assert が黙って未実行になる。
        # try/catch で全体を包み、捕捉した例外を v:errors に積んで
        # 「途中で落ちて何もチェックされなかった」を偽PASSにしない。
        "$runner" -N -u NONE -i NONE -es \
            -c "set rtp+=${REPO_ROOT}" \
            -c "runtime plugin/amnesia.vim" \
            -c "try | source ${test_file} | catch | call add(v:errors, 'UNCAUGHT: ' . v:exception) | endtry" \
            -c "call writefile(v:errors, '${errfile}')" \
            -c "qall!" >/tmp/amnesia_test_stdout.log 2>&1

        if [ -s "$errfile" ]; then
            echo "FAIL: ${runner} ${test_file}"
            sed 's/^/    /' "$errfile"
            overall_status=1
        else
            echo "PASS: ${runner} ${test_file}"
        fi
        rm -f "$errfile"
    done
done

exit $overall_status
