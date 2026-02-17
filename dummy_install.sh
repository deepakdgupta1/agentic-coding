#!/bin/bash
echo "Dummy Install receives $# args:"
for arg in "$@"; do
    echo "  Arg: '$arg'"
done
