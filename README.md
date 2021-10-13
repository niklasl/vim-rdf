Vim-RDF
=======

This is a bundle of vimfiles for editing
[RDF](http://www.w3.org/TR/rdf11-primer/) data. It includes various RDF syntax
highlighting and a plugin for RDF prefix completion.

## Syntax highlighting

* [Turtle](http://www.w3.org/TR/turtle/)
* [TriG](http://www.w3.org/TR/trig/)
* [Notation 3](http://www.w3.org/TeamSubmission/n3/) (also available on Vim.org as
  [n3.vim](http://www.vim.org/scripts/script.php?script_id=944))
* [JSON-LD](http://www.w3.org/TR/json-ld/)
* [RDFa in HTML](http://www.w3.org/TR/rdfa-in-html/)

## Plugins

### RDF Prefix Completion

(Prerequisites: Python 3 support in Vim and RDFLib installed in a Python
environment available to Vim (I use
[vim-virtualenv](https://github.com/jmcantrell/vim-virtualenv)).)

Call

    :RDF

to enable. This automatically sets up the omnifunc (invoked with `CTRL-X
CTRL-O` in insert mode) to complete on RDF prefixes. It uses http://prefix.cc/
under the hood, and automatically dereferences and caches RDF vocabularies when
completing on defined prefixes.

It also maps <leader>d so you can jump from a term to a term definition (in a
separate window).

Turning this off with `:RDF quit` restores any original omnifunc.

(And older version of this plugin is available on Vim.org as
[RDF Namespace-complete](http://www.vim.org/scripts/script.php?script_id=1835).)
