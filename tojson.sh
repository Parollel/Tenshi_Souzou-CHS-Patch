#!/usr/bin/bash
IFS=$'\n'

cleanup() {
    [[ -f "${predecode}" ]] && rm "${predecode}"
}
trap cleanup EXIT

declare -i head="$(grep --color=never -hnF 'karaoke' "${1}" | head -1 | cut -d':' -f1)"
declare -i tail="$(grep --color=never -hnF 'karaoke' "${1}" | tail -1 | cut -d':' -f1)"

declare predecode="$(mktemp)"

awk "
NR >= ${head} && NR <= ${tail}"' {
    gsub(/\{.+\}/, "", $0);
    print $0;
}
' "${1}" > "${predecode}"

paste -d'\n' <(cut -d',' -f1 "${predecode}" | cut -d' ' -f2) <(cut -d',' -f10- "${predecode}") |\
awk '
{
    if (NR % 2 != 0) {
        if ($0 == "0") {
            printf "\n";
            state = 0;
        }
        else if ($0 == "1") {
            state = 1;
        } else if ($0 == "99") {
            state = 99;
        } else {
            state = 2;
        }
    } else {
        if (state == 0) {
            printf "%s", $0;
        } else if (state == 1) {
            printf "#%s", $0;
        } else if (state == 99) {
            for (i = 1; i <= $0; ++i) {
                printf "\nnull";
            }
        }
    }
}
END {
    printf "\n";
}
' | \
    tail --lines=+2 | \
    sed -re 's/」?#「?//g' | \
    jq -R | jq -s | \
    sed -e 's/^  "null",/  null,/g' | \
    jq .
