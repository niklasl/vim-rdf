
if !has('python')
    "echo "Error: Required vim compiled with +python"
    finish
endif


func! s:DefPython()
python <<ENDPY
import vim
import re
import os
try:
    try:
        from rdflib import ConjunctiveGraph, RDF, RDFS, Namespace
    except ImportError:
        # RDFLib >= 2.5 < 3.0
        from rdflib.graph import ConjunctiveGraph
        from rdflib.namespace import RDF, RDFS, Namespace
except ImportError:
    print "Requires rdflib."


class RdfnsLibrary(object):

    MAX_LINE_SCAN = 64
    MATCH_NS_DECL = re.compile(r'''(?:@prefix\s+|xmlns:?|prefix\s+|PREFIX\s+|")(\w*)"?[:=]\s*[<"'"](.+?)[>"']''')
    MATCH_URI_LEAF = re.compile(r'(.+[#/])([A-Za-z0-9_-]+)$')

    _instance = None

    @classmethod
    def get_instance(cls, basedir):
        if not cls._instance:
            cls._instance = cls(basedir)
        cls._instance.collect_namespaces()
        return cls._instance

    def __init__(self, basedir):
        self.basedir = basedir
        self.rdfns_prefixes = {}
        self.rdfns_namespaces = {}
        self.common_rdfns_prefixes = {}
        self.load_vocabularies(basedir)

    def get_vocabulary(self, prefix):
        ns = self.rdfns_prefixes.get(prefix)
        vocab = self.rdfns_namespaces.get(ns)
        return vocab

    def collect_namespaces(self, refetch=False):
        pfxns = self.rdfns_prefixes = {}
        for i, line in enumerate(vim.current.buffer):
            if i > self.MAX_LINE_SCAN:
                break
            for pfx, ns in self.MATCH_NS_DECL.findall(line):
                pfxns[pfx] = ns

    def load_vocabularies(self, basedir=None):
        basedir = basedir or self.basedir
        for fname in os.listdir(basedir):
            ext = os.path.splitext(fname)[-1]
            fpath = os.path.join(basedir, fname)
            if os.path.isfile(fpath):
                graph = ConjunctiveGraph()
                if ext == '.n3':
                    fmt = 'n3'
                elif ext == '.ttl':
                    fmt = 'turtle'
                elif ext in ('.rdf', '.rdfs', '.owl'):
                    fmt = 'xml'
                else:
                    continue
                try:
                    graph.load(fpath, format=fmt)
                except Exception, e:
                    print "Error loading <%s>: %s" % (fpath, e)
                else:
                    self._load_vocabulary(graph)
                    self._collect_common_rdfns_prefixes(graph)
        self._sort_terms()

    def _load_vocabulary(self, graph):
        nss = self.rdfns_namespaces
        items = set(graph.subjects(RDF.type, None))
        for subject in items:
            uri, leaf = self.split_uri(subject)
            if uri and leaf:
                nss.setdefault(uri, []).append(leaf)

    def _sort_terms(self):
        for terms in self.rdfns_namespaces.values():
            terms.sort()

    def _collect_common_rdfns_prefixes(self, graph):
        self.common_rdfns_prefixes.update(dict(
                (key, ns) for key, ns in graph.namespace_manager.namespaces()
                if key
            ))

    @classmethod
    def split_uri(cls, uri):
        uri = unicode(uri)
        for base, leaf in cls.MATCH_URI_LEAF.findall(uri):
            return base, leaf
        return None, None


def vimcomplete_rdfns(context, match):
    completions = _get_rdfns_completions(context, match)
    vimDictRepr = "["
    for cmpl in completions:
        vimDictRepr += '{'
        for kv in cmpl.items():
            vimDictRepr += "'%s': '%s'," % kv
        vimDictRepr += "'icase': 0},"
    if vimDictRepr[-1] == ",":
        vimDictRepr = vimDictRepr[:-1]
    vimDictRepr += "]"
    vim.command("silent let g:rdfns_complete_completions = %s" % vimDictRepr)


def _get_rdfns_completions(context, match):
    basedir = get_rdf_model_dir()
    library = RdfnsLibrary.get_instance(basedir)

    prefix = context.split(':')[0]
    if prefix.lower() == 'prefix':
        suggestions = _rdfns_prefix_values(library)
    elif prefix == 'xmlns':
        suggestions = _rdfns_xmlns_values(library)
    else:
        suggestions = _rdfns_vocabulary_names(library, prefix,
                withprefixes=not ':' in context)

    completions = [{'word': value}#, 'menu': menu}#, 'info': info}
        for value in suggestions if value.startswith(match)]

    return completions

def _rdfns_prefix_values(library):
    for pair in library.common_rdfns_prefixes.items():
        yield '%s: <%s>' % pair

def _rdfns_xmlns_values(library):
    for pair in library.common_rdfns_prefixes.items():
        yield '%s="%s"' % pair

def _rdfns_vocabulary_names(library, prefix, withprefixes=False):
    vocab = library.get_vocabulary(prefix) or []
    pfxs = []
    if withprefixes:
        pfxs += [k+':' for k in sorted(library.rdfns_prefixes.keys())]
    return pfxs + vocab


# TODO: configure better
RDF_MODEL_DIRS = [
        os.environ.get('RDF_MODEL_FILES', ''),
        '~/rdfmodels',
        '~/Documents/rdfmodels',
        '/usr/local/share/rdfmodels/'
    ]

def get_rdf_model_dir():
    for fpath in RDF_MODEL_DIRS:
        fpath = os.path.expanduser(fpath)
        if os.path.isdir(fpath):
            return fpath

ENDPY
endfunc


call s:DefPython()


func! RdfnsComplete(findstart, base)
    let line = getline('.')
    let cpos = col('.') - 1

    " 1 - get the text length
    if a:findstart == 1
        while cpos > 0 && line[cpos - 1] =~ '\a\|_\|-'
            let cpos -= 1
        endwhile
        return cpos

    " 0 - return the list of completions
    else
        let context = ''
        while cpos > 0
            let cpos -= 1
            let c = line[cpos]
            if c =~ '\w' || c =~ '\:'
                let context = c . context
                continue
            elseif strlen(context) > 0 || cpos == 0
                break
            endif
        endwhile
        execute "python vimcomplete_rdfns('" . context . "', '" . a:base . "')"
        return g:rdfns_complete_completions

    endif
endfunc

func! s:RdfnsReload()
    python RdfnsLibrary.get_instance(get_rdf_model_dir()).load_vocabularies()
endfunc


" <none> | reload | quit
func! rdfnscomplete#Rdfns(...)
    if a:0 == 0
        let b:rdfns_saved_omnifunc = &omnifunc
        setlocal omnifunc=RdfnsComplete
    elseif a:1 == 'reload'
        call <SID>RdfnsReload()
    elseif a:1 == 'quit'
        if exists('b:rdfns_saved_omnifunc')
            let &omnifunc=b:rdfns_saved_omnifunc
            unlet b:rdfns_saved_omnifunc
        endif
    endif
endfunc


" TODO: show label and comment for term/vocab under cursor
"
"func! RdfBalloonExpr()
"    return 'Cursor is at line ' . v:beval_lnum . ', column ' . v:beval_col . \
"        ' of file ' .  bufname(v:beval_bufnr) . ' on word "' . v:beval_text . '"'
"endfunc
"
"set bexpr=RdfBallonExpr()

