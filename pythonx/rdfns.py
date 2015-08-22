import re
import os
from rdflib import ConjunctiveGraph, RDF, RDFS, Namespace


RDF_MODEL_DIRS = [
        os.environ.get('RDF_MODEL_FILES', ''),
        '~/rdfmodels',
        '~/Documents/rdfmodels',
        '/usr/local/share/rdfmodels/'
    ]

def find_rdf_model_dir():
    for fpath in RDF_MODEL_DIRS:
        fpath = os.path.expanduser(fpath)
        if os.path.isdir(fpath):
            return fpath


MAX_LINE_SCAN = 80
MATCH_NS_DECL = re.compile(
        r'''(?:@prefix\s+|xmlns:?|prefix\s+|PREFIX\s+|")(\w*)"?[:=]\s*[<"'"](.+?)[>"']''')
MATCH_URI_LEAF = re.compile(r'(.+[#/])([A-Za-z0-9_-]+)$')

def get_pfxns_map(buffer):
    return {pfx: ns for line in buffer[:MAX_LINE_SCAN]
            for pfx, ns in MATCH_NS_DECL.findall(line)}

def split_uri(uri):
    uri = unicode(uri)
    for base, leaf in MATCH_URI_LEAF.findall(uri):
        return base, leaf
    return None, None


class Tool(object):

    def __init__(self, basedir):
        self.basedir = basedir
        self.reload()

    def reload(self):
        self.rdfns_namespaces = {}
        self.common_rdfns_prefixes = {}
        self._load_vocabularies()

    def get_completions(self, buffer, context, match):
        prefix = context.split(':')[0]
        pfxns = get_pfxns_map(buffer)
        suggestions = self._get_rdfns_completions(prefix, pfxns.get(prefix),
                withprefixes=not ':' in context)
        return [{'word': value, 'icase': 0}#, 'menu': menu}#, 'info': info}
            for value in suggestions if value.startswith(match)]

    def _get_rdfns_completions(self, prefix, ns, withprefixes):
        if prefix.lower() == 'prefix':
            suggestions = self._get_prefix_suggestions('%s: <%s>')
        elif prefix == 'xmlns':
            suggestions = self._get_prefix_suggestions('%s="%s"')
        else:
            suggestions = self._rdfns_vocabulary_names(ns, withprefixes)

        return suggestions

    def _get_prefix_suggestions(self, fmt):
        for pair in self.common_rdfns_prefixes.items():
            yield fmt % pair

    def _rdfns_vocabulary_names(self, ns, withprefixes=False):
        vocab = self._get_vocabulary(ns) or []
        pfxs = []
        if withprefixes:
            pfxs += [k+':' for k in sorted(self.common_rdfns_prefixes.keys())]
        return pfxs + vocab

    def _get_vocabulary(self, ns):
        # TODO: load from graphcache and store in terms_cache
        vocab = self.rdfns_namespaces.get(ns)
        return vocab

    def _load_vocabularies(self):
        basedir = self.basedir

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
                    print("Error loading <%s>: %s" % (fpath, e))
                else:
                    self._collect_vocab_terms(graph)
                    self._collect_common_rdfns_prefixes(graph)

        for terms in self.rdfns_namespaces.values():
            terms.sort()

    def _collect_vocab_terms(self, graph):
        nss = self.rdfns_namespaces
        items = set(graph.subjects(RDF.type, None))
        for subject in items:
            uri, leaf = split_uri(subject)
            if uri and leaf:
                nss.setdefault(uri, []).append(leaf)

    def _collect_common_rdfns_prefixes(self, graph):
        self.common_rdfns_prefixes.update({key: ns
                for key, ns in graph.namespace_manager.namespaces() if key})

