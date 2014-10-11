#!/bin/sh
set -e

# Test running just latexrun empty.tex, where empty.tex produces no output.

TMP=tmp.$(basename -s .sh $0)
mkdir -p $TMP
cat > $TMP/empty.tex <<EOF
\documentclass{article}
\begin{document}
\end{document}
EOF
function clean() {
    rm -rf $TMP
}
trap clean SIGINT SIGTERM

# Intentionally use just the latexrun command to test when -o is not provided.
"$1" "$TMP/empty.tex"

clean

## output:
## No pages of output; output not updated
