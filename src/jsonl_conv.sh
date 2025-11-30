#!/usr/bin/env bash

command=$1
input_file=$2
output_file=$3
state=${4:-normal}

if [[ -z "$command" || -z "$input_file" || -z "$output_file" ]]; then
    exit 1
fi

if [[ ! -f "$input_file" ]]; then
    exit 2
fi

case "$command" in
    encode)
        if [[ "$state" != "normal" && "$state" != "deleted" ]]; then
            exit 3
        fi
        jq -Rc --arg state "$state" '{line_number: input_line_number, state: $state, line:.}' "$input_file" > "$output_file"
        ;;
    decode)
        jq -r 'select(.state == "normal") | .line' "$input_file" > "$output_file"
        ;;
    *)
        exit 4
        ;;
esac
