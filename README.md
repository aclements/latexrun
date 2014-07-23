See LaTeX run.  Run latexrun.

latexrun fits LaTeX into a modern build environment.  It hides LaTeX's
circular dependencies, transforms errors into a standard and
user-friendly format, and generally enables other tools to do what
they do best.


Features
========

* Runs latex the right number of times.  LaTeX's iterative approach is
  a poor match for build tools that expect to run a task once and be
  done with it.  latexrun hides this complexity by running LaTeX (and
  BibTeX) as many times as necessary and no more.  Only the results
  from the final run are shown, making it act like a standard,
  single-run build task.

* Visible error messages and warnings.  LaTeX and related tools bury
  errors and useful warnings in vast wastelands of output noise.
  latexrun parses this spew and prints only the messages that matter,
  in a format understood by modern tools.  latexrun even figures out
  file names and line numbers for many BibTeX errors that usually
  don't indicate their source.

* Incremental progress reporting.  latexrun keeps you informed of
  LaTeX's progress, without overwhelming you with output.

* Cleaning.  LaTeX's output files are legion.  latexrun keeps track of
  them and can clean them up for you.

* Atomic commit.  latexrun updates output files atomically, which
  means your PDF reader will no longer crash or complain about broken
  xref tables when it catches latex in the middle of writing out a
  PDF.

* Easy {.git,.hg,svn:}ignore.  Just ignore `.latexrun.db` and
  `latex.out/`.  Done!

* Self-contained.  latexrun is a single, self-contained Python script
  that can be copied in to your source tree so your collaborators
  don't have to install it.


Non-features
------------

Kitchen sink not included.  latexrun is not a build system.  It will
not convert your graphics behind your back.  It will not continuously
monitor your files for changes.  It will not start your previewer for
you.  latexrun is designed to be *part* of your build system and let
other tools do what they do well.


Integrating with make
=====================

latexrun does its own dependency tracking (at a finer granularity than
`make`).  Since it also does nothing if no dependencies have changed,
it's easy to integrate with `make` using phony targets.  Here's a
complete example:

```Makefile
.PHONY: FORCE
paper.pdf: FORCE {files that need to be generated, if any}
	latexrun paper.tex

.PHONY: clean
clean:
	latexrun --clean-all
```

Note that `paper.pdf` depends on a phony target, but is not itself
phony, since this would cause `make` to consider anything that
*depended* on `paper.pdf` to always be out of date.  Instead, `make`
only considers targets that depend on `paper.pdf` out of date if
latexrun actually updates `paper.pdf`.


Comparison with other tools
===========================

Several other tools achieve the same basic goal as latexrun: to
automatically run LaTeX and BibTeX the right number of times.

Rubber
------

Rubber is a fantastic tool that inspired many features of latexrun.
Rubber showed that it's possible to fix many of LaTeX's eccentricities
like iterative builds and unreadable logs.  latexrun is a response to
Rubber: it attempts to capture its best features while adhering to the
Unix philosophy of "do one thing well" and further modernizing the
LaTeX build process.

latexrun has more modern defaults and TeX support than Rubber.  In
addition to pdfTeX, it supports LuaTeX and XeTeX.  It defaults to PDF
output, rather than DVI output.  It defaults to reporting important
warnings like unknown references, rather than suppressing all
warnings.  It defaults to putting all intermediate output in a
directory, rather than inheriting LaTeX's default behavior of filling
your source tree with intermediate files.  It also has features that
interact better with more modern tools, like atomic commit for PDF
viewers that use file system notification to automatically refresh.

latexrun is simple.  It's intentionally a single, self-contained, and
reasonably short Python script that you can drop in next to your LaTeX
sources.  Rubber is modular, which is admirable but leads to higher
setup cost.

latexrun has robust post-execution dependency analysis, while Rubber
works by parsing your TeX code.  TeX is famously the only thing that
can correctly parse TeX code and as a result Rubber's dependency
analysis is fragile and in occasional and hard-to-predict situations
requires the user to explicitly declare dependencies, command aliases,
or extra files to "watch".

latexrun fits in to your toolchain, while Rubber tries to replace it.
Rubber goes beyond building LaTeX code with "features" like automatic
graphics conversion based on a weighted shortest-path walk through
known converters.  This makes its build process unpredictable and
means that other build tools like `make` integrate poorly with it.
latexrun prefers explicit over implicit, and tries to make latex act
like a modern tool in your toolchain to enable other tools to do what
*they* do best.

latexmk
-------

latexmk is a venerable LaTeX wrapper that has amassed an impressive
array of options, flags, and features.  It includes many features that
latexrun leaves to other tools---like starting viewers, printing, and
conversion to PDF from DVI and PostScript---or simply omits---like
adding banners and automatically invoking `make` for missing files.

Like latexrun, latexmk can use the "file recorder" feature of modern
TeX engines to compute precise file dependencies.  However, latexrun
also tracks non-file dependencies like environment variables and knows
how to track filtered file contents (like only the lines that actually
matter to BibTeX).

latexmk simply passes through LaTeX's log spew, while latexrun
extracts errors and warnings and displays them in a friendly, modern
format.


How latexrun works
==================

latexrun views the world as a cyclic graph of deterministic functions
of system state:

         .tex → ┌───────┐ ─────────────────────────→ .pdf
    ╭─── .aux → │       │ → .aux ──╮
    │╭── .toc → │ latex │ → .toc ─╮│
    ││╭─ .bbl → │       │ → .log  ││
    │││     … → └───────┘ → …     ││
    │╰────────────────────────────╯│
    ╰──────────────────────────────┤
      │                            ↓
      │                 .bst → ┌────────┐ → .blg
      │                 .bib → │ bibtex │ → .bbl ─╮
      │                        └────────┘         │
      ╰───────────────────────────────────────────╯

latexrun's goal is to find the *fixed-point* of this computation.  Put
simply, it runs latex and bibtex repeatedly until it can guarantee
that additional runs will not change the output.

A direct approach could be to check the output of latex and bibtex
after each run and stop when the output is the same from one run to
the next.  This works, but runs latex too many times; it will have
already produced its final output one iteration before this approach
can figure out that it's done.

Instead, latexrun models latex and bibtex as deterministic functions
of the file system state, their command-line arguments, and certain
environment variables.  Hence, if the *inputs* to latex and bibtex do
not change over one iteration, then latexrun can guarantee that the
output also will not change, and stop.


Known bugs
==========

latexrun doesn't always track files that *don't* exist, so it may not
re-run LaTeX after a file gets created.  Currently the best solution
is to `latexrun --clean-all`, though this it obviously sub-optimal.

Command-line usage errors when calling latex appear before "This is
pdfTeX" and are not logged and therefore often not reported.


Tasks
=====

* Solve the problem of missing input files.  LaTeX doesn't record
  inputs that it couldn't read, so we don't know about them even
  though they affect the computation (often seriously!).  We can
  partially address this by getting the listing of the output
  directory before running latex.  Once we know the jobname and such,
  filter this listing down to files that start with the jobname,
  remove a few others that are known not to be inputs like the output
  file and the log file, and then record this *listing* as an input.
  This isn't perfect, but it's a good approximation.  We could also
  scan the log for "No file X.", which is printed by LaTeX's `\@input`
  for things like aux and toc files and could potentially catch more
  optional inputs.  Neither of these solutions solves the problem for
  general user input files.

* Provide a way to disable output filters for things that do their own
  output parsing (e.g., AUCTeX).

* Integrate even better with `make`.  Phony rules are okay, but will
  force `make` dependencies to be generated even if latexrun
  ultimately does nothing.  Since latexrun's dependencies are
  finer-grained than `make`'s, it might be necessary to shell out to
  latexrun to do this.

* Include page numbers at least in overfull/underfull box warnings.

* Separate clean data by source file so you can clean a single input
  file's outputs.

* Some important things like undefined references are only considered
  warnings since they don't stop compilation.  Maybe distinguish
  document-mangling warnings (almost but not quite errors) and format
  warnings (can be ignored if justified).

* Perhaps separate out the LaTeX output filter so it can be used on
  its own as a pipe filter.  It could even be used on high-level
  output, like from make, by acting as a pass-through until the "This
  is (pdf)TeX" line up to the "Transcript written on" line (or
  anything else that can end TeX's log output).
