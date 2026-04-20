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


# ATS extraction check
check: all
    #!/usr/bin/env sh
    for f in pdf/*.pdf; do
        echo "=== $f ===" && pdftotext -layout "$f" - && echo "———————————————————————————"
    done

# Remove compiled PDFs
clean:
    @rm -rf pdf/
