#| Makefile
#| ========
#|
#| This Makefile compiles the Elm sources and generates the
#| HTML documentation.
#|
#| Usage
#| -----
#|
#|      make [help|clean|weave|watch] [V=0|1]
#|
#| Prerequisites
#| -------------
#|
#| * Pandoc >= 2.3 (with Lua filter support)
#| * pandoc-citeproc, pandoc-eqnos, pandoc-fignos (`pip install`)
#| * elm (`npm install -g elm`)
#| * inotify-tools (for watching)
#| * browser-sync (`npm install -g browser-sync`, for watching)
#| * tmux (for watching)

deps := pandoc pandoc-citeproc pandoc-eqnos pandoc-fignos elm
deps += inotifywait browser-sync tmux

format := markdown+fenced_code_attributes+citations
format := $(format)+all_symbols_escapable+fenced_divs
format := $(format)+multiline_tables+bracketed_spans

html_args := -s --lua-filter scripts/annotate-code-blocks.lua
html_args += --filter pandoc-fignos
html_args += --filter pandoc-eqnos -M eqnos-warning-level:0
html_args += --filter pandoc-citeproc
html_args += -H static/header.html
html_args += --syntax-definition scripts/elm.xml
html_args += --mathjax --toc --base-header-level=2 --css style.css

#|
#| Targets
#| -------

#| * `help`: print this help
help:
	@ grep -e '^#|' Makefile \
	| sed -e 's/^#| \?\(.*\)/\1/' \
	| pandoc -f markdown -t scripts/terminal.lua \
	| fold -s -w 80

#| * `weave`: build everything
weave: docs/index.html docs/zeeman.js docs/style.css static/header.html

docs: check-deps
	mkdir -p docs; \
	touch docs/.nojekyll

docs/%.html: lit/%.md Makefile | docs
	$(PRINTF) "weaving '$@'\n"
	$(AT)pandoc -f $(format) $(html_args) -t html5 $< -o $@

docs/style.css: static/style.css | docs
	$(PRINTF) "copying style sheet\n"
	$(AT)cp $< $@

docs/zeeman.js: $(wildcard src/*.elm) | docs
	$(PRINTF) "compiling '$@'\n"
	$(AT)elm make src/Main.elm --output=$@ --optimize

#| * `clean`: clean up build files
clean:
	$(PRINTF) "cleaning docs\n"
	$(AT)rm -rf docs

#| * `watch-weave`: watch source files
watch-weave:
	$(PRINTF) "\033[1mWatching for \033[33mweave\033[m ...\n"
	$(AT)while true ; do \
		inotifywait -q -e close_write lit/*.md src/*.elm static/*; \
		make weave; \
	done

#| * `watch-browser`: start browser-sync
watch-browser:
	$(PRINTF) "\033[1mStarting \033[33mbrowser-sync\033[m ...\n"
	$(AT)browser-sync start -s docs -f docs --no-notify

#| * `watch-tangle`: start entangled
watch-tangle:
	$(PRINTF) "\033[1mStarting \033[33mentangled\033[m ...\n"
	$(AT)entangled lit/*.md

#| * `watch`: starts entangled, weave watch and browser-sync in a tmux
watch: check-deps
	@tmux new-session make --no-print-directory watch-tangle \; \
		split-window -v make --no-print-directory watch-weave \; \
		split-window -v make --no-print-directory watch-browser \; \
		select-layout even-vertical \;

check-deps:
	$(AT)for f in $(deps) ; do \
		if ! command -v $$f > /dev/null; then \
			echo "Missing dependency: $$f" ; \
			false ; \
		fi ; \
	done

#|
#| Arguments
#| ---------
#|
#| * `V=1`: verbose output
V = 0
AT_0 := @
AT_1 :=
AT = $(AT_$(V))

ifeq ($(V), 1)
    PRINTF := @\#
else
    PRINTF := @printf
endif

.PHONY: weave clean help watch-tangle watch-browser watch-weave watch check-deps

