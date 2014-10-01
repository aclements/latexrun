#!/bin/sh

# Test that latexrun correctly re-runs latex after missing \include
# files are created.

set -e

TMP=tmp.$(basename -s .sh $0)
mkdir -p $TMP
cat > $TMP/test.tex <<EOF
\documentclass{article}

\begin{document}
\include{./$TMP/chap1}
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
## tmp.T-new-include/test.tex: warning: No file ./tmp.T-new-include/chap1.tex
## No pages of output; output/x.pdf not updated
## chap1 now exists
