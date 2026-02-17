#!/bin/bash

test_array() {
    local -n arr=$1
    echo "Testing array: ${arr[*]}"
    echo "Size: ${#arr[@]}"
    local count=0
    for item in "${arr[@]:-}"; do
        echo "  Item: '$item'"
        count=$((count+1))
    done
    echo "Loop count: $count"
}

echo "--- Unset array ---"
unset unset_arr
test_array unset_arr

echo "--- Empty array ---"
empty_arr=()
test_array empty_arr

echo "--- Array with empty string ---"
empty_str_arr=("")
test_array empty_str_arr
