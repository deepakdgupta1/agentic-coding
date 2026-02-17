#!/bin/bash

shell_escape_args() {
    local out=""
    local arg=""
    local q=""

    for arg in "$@"; do
        printf -v q '%q' "$arg"
        if [[ -n "$out" ]]; then
            out+=" "
        fi
        out+="$q"
    done

    printf '%s' "$out"
}

# Simulate the array in acfs_container.sh
install_args=(--local --yes --mode vibe --skip-ubuntu-upgrade)

echo " Original array: ${install_args[*]}"

escaped="$(shell_escape_args "${install_args[@]}")"
echo "Escaped string: $escaped"

# Simulate what acfs_sandbox_exec_root does (bash -c "$cmd")
# We'll use a dummy install.sh that just prints its args
cat > dummy_install.sh <<'EOF'
#!/bin/bash
echo "Dummy Install receives $# args:"
for arg in "$@"; do
    echo "  Arg: '$arg'"
done
EOF
chmod +x dummy_install.sh

echo "--- Testing bash -c execution ---"
cmd="bash dummy_install.sh $escaped"
echo "Command: $cmd"
bash -c "$cmd"
