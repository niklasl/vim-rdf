"===============================================================
" RDF Vocabulary/Model Omni-Completion for Vim 7+
" Maintainer: Niklas Lindström <lindstream@gmail.com>
" Version: 1.2.1
" Updated: 2012-09-22
" Published: 2007-03-25
" URL: <http://www.vim.org/scripts/script.php?script_id=1835>
"===============================================================
"
" USAGE:
" In a file with namespace prefix declarations similar to XML, Turtle/Notation3
" or SPARQL, call
"
"   :RDF
"
" to turn on completion on terms within a namespace using the preceding prefix.
" This will load all RDF/XML and n3-files found in one of the following dirs:
"
"   - $RDF_MODEL_FILES (environment variable)
"   - ~/rdfmodels/
"   - ~/Documents/rdfmodels/
"   - /usr/local/share/rdfmodels/
"
" Completion will work on:
"
"   - [..]:__       -> all terms from vocabulary bound to given prefix
"   - ..            -> anything known, both prefixes and non-prefixed terms
"   - xmlns:..      -> any namespaces gathered from usage in loaded files; xml
"                      atribute-style
"   - prefix [..]   -> -|| -; Notation3/SPARQL-style (<..namespace..>)
"
" Prefixes are bound to vocabularies by looking for anything in:
"
"   - XML "xmlns:[pfx]" style
"   - Notation 3 "@prefix [pfx]" style
"   - SPARQL "PREFIX [pfx]" style
"   - JSON '"PREFIX": "pfx"' style
"
" Call
"
"   :RDF reload
"
" to reload model files, and
"
"   :RDF quit
"
" to restore the original omnifunc (if any).
"
" REQUIRES:
" Vim compiled with Python and RDFLib installed for Python.
"
"===============================================================


func! RdfnsArgs(A,L,P)
    return "reload\nquit"
endfunc

command! -complete=custom,RdfnsArgs -nargs=* RDF :call rdfnscomplete#Rdfns(<f-args>)

