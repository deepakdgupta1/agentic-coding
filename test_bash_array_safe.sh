#!/bin/bash

test_array_safe() {
    local -n arr=$1
    echo "Testing array: ${arr[*]}"
    echo "Size: ${#arr[@]}"
    local count=0
    # The fix: remove :-
    for item in "${arr[@]}"; do
        echo "  Item: '$item'"
        count=$((count+1))
    done
    echo "Loop count: $count"
}

echo "--- Unset array (safe) ---"
unset unset_arr
test_array_safe unset_arr

echo "--- Empty array (safe) ---"
empty_arr=()
test_array_safe empty_arr
