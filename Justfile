# List all available recipes
list:
    @just --list --unsorted

_mkdir:
    @mkdir -p pdf
_run action file: _mkdir
    @typst {{action}} --root . {{file}} pdf/$(basename {{file}} .typ).pdf

# Watch a test file
watch file="tests/default.typ": (_run "watch" file)
# Compile a test file
compile file="tests/default.typ": (_run "compile" file)

# Compile all test files
all:
    @for f in tests/*.typ; do just compile $f; done

# Compile all test files in all styles
all-styles: _mkdir
    #!/usr/bin/env sh
    for f in tests/*.typ; do
        for s in professional minimal technical; do
            typst compile --root . --input style=$s "$f" "pdf/$(basename "$f" .typ)-$s.pdf"
        done
    done

# ATS regression check
check: all
    #!/usr/bin/env sh
    fail=0

    for file in pdf/*.pdf; do
        # pdffonts header is 2 lines; emb is at NF-4
        # (works for both "CID Type 0C" and "CID TrueType" type strings)
        bad=$(pdffonts "$file" 2>/dev/null | tail -n +3 | awk '$(NF-4) != "yes" { print }')
        if [ -n "$bad" ]; then
            printf 'FAIL  [%s]  unembedded font:\n%s\n' "$file" "$bad" >&2
            fail=1
        fi
    done

    if [ "$fail" -eq 0 ]; then
        echo "All ATS checks passed."
    else
        printf '\nATS checks FAILED.\n' >&2
        exit 1
    fi

# Remove compiled PDFs
clean:
    @rm -rf pdf/
