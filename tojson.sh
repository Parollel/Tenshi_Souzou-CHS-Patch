#!/usr/bin/bash
IFS=$'\n'

cleanup() {
    [[ -f "${predecode}" ]] && rm "${predecode}"
}

trap cleanup EXIT

declare -i head="$(rg 'karaoke' "${1}" -n | head -1 | cut -d':' -f1)"
declare -i tail="$(rg 'karaoke' "${1}" -n | tail -1 | cut -d':' -f1)"

declare predecode="$(mktemp)"

awk "NR >= ${head} && NR <= ${tail}" "${1}" |\
sd '\{.+\}' '' > "${predecode}"

paste -d'\n' <(cut -d',' -f1 "${predecode}" | cut -d' ' -f2) <(cut -d',' -f10- "${predecode}") |\
awk '
{if (NR % 2 != 0) {
    if ($0 == "0") {
        printf "\n";
        state = 0;
    } else if ($0 == "1") {
        state = 1;
    } else {
        state = 2;
    }
} else {
    if (state == 0) {
        printf "%s", $0;
    } else if (state == 1) {
        printf "#%s", $0;
    }
}}
END {
    printf "\n";
}
' | tail --lines=+2 | sd '」?#「?' ' ' | jq -R | jq -s
