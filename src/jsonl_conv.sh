#!/usr/bin/env bash

command=$1
input_file=$2
output_file=$3

if [[ -z "$command" || -z "$input_file" || -z "$output_file" ]]; then
    exit 1
fi

if [[ ! -f "$input_file" ]]; then
    exit 2
fi

function is_comment() {
    local line="$1"
    if [[ "$line" =~ ^\s*# ]]; then
        return 0
    else
        return 1
    fi
}

function get_line_state() {
    local line="$1"
    if [ -z "$line" ] || is_comment "$line" ; then
        line_number=$(( line_number + 1 ))
        echo "ignore"
    else
        echo "normal"
    fi
}

case "$command" in
    encode)
        line_nr=1
        while IFS= read -r p; do
            line_state=$(get_line_state "$p")
            jq -n -c --argjson line_nr "$line_nr" --arg line "$p" --arg line_state "$line_state" '{line_number:$line_nr,state:$line_state,line:$line}' >> "$output_file"
            line_nr=$(( line_nr + 1 ))
        done <"$input_file"
        ;;
    decode)
        jq -r 'select(.state == "normal" or .state == "ignore") | .line' "$input_file" > "$output_file"
        ;;
    *)
        exit 4
        ;;
esac
