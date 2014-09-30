#!/bin/sh

# Test that latexrun correctly re-runs latex after missing \input
# files are created.

set -e

TMP=tmp.$(basename -s .sh $0)
mkdir -p $TMP
cat > $TMP/test.tex <<EOF
\documentclass{article}

\begin{document}
\input{./$TMP/chap1}
\end{document}
EOF
rm -f $TMP/chap1.tex

echo chap1 does not exist
"$@" $TMP/test.tex || true

echo Hello > $TMP/chap1.tex

echo chap1 now exists
"$@" $TMP/test.tex

rm -rf $TMP

## output:
## chap1 does not exist
## tmp.T-new-input/test.tex:4: error: File `./tmp.T-new-input/chap1.tex' not found
##       at <read *>
##     from \input{./tmp.T-new-input/chap1}
## tmp.T-new-input/test.tex: Fatal error (no output file produced)
## There were errors; output/x.pdf not updated
## chap1 now exists
