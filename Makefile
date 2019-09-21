#| Makefile
#| ========
#|
#| This Makefile compiles the Elm sources and generates the
#| HTML documentation.
#|
#| Usage
#| -----
#|
#|      make [help|clean|weave] [V=1]
#|
#| Targets
#| -------
#|
#| * `help`: print this help
#| * `clean`: clean up build files
#| * `weave`: build everything
#|
#| Arguments
#| ---------
#|
#| * `V=1`: verbose output

.PHONY: weave clean help

help:
	@ grep -e '^#|' Makefile \
	| sed -e 's/^#| \?\(.*\)/\1/' \
	| pandoc -f markdown -t scripts/terminal.lua \
	| fold -s -w 70

format := markdown+fenced_code_attributes+citations
format := $(format)+all_symbols_escapable+fenced_divs
format := $(format)+multiline_tables+bracketed_spans

html_args := -s --lua-filter scripts/annotate-code-blocks.lua
html_args += --filter pandoc-fignos
html_args += --mathjax --toc --base-header-level=2 --css style.css

weave: docs/index.html docs/machine.html docs/zeeman.js docs/style.css

docs:
	mkdir docs

docs/%.html: lit/%.md Makefile | docs
	$(PRINTF) "weaving '$@'\n"
	$(AT)pandoc -f $(format) $(html_args) -t html5 $< -o $@

docs/style.css: static/style.css | docs
	$(PRINTF) "copying style sheet\n"
	$(AT)cp $< $@

docs/zeeman.js: $(wildcard src/*.elm) | docs
	$(PRINTF) "compiling '$@'\n"
	$(AT)elm make src/Main.elm --output=$@ --optimize

clean:
	$(PRINTF) "cleaning docs\n"
	$(AT)rm -rf docs

# To be verbose, run: make V=1
V = 0
AT_0 := @
AT_1 :=
AT = $(AT_$(V))

ifeq ($(V), 1)
    PRINTF := @\#
else
    PRINTF := @printf
endif

