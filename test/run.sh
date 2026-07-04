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
        "$runner" -N -u NONE -i NONE -es \
            -c "set rtp+=${REPO_ROOT}" \
            -c "runtime plugin/amnesia.vim" \
            -c "source ${test_file}" \
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
