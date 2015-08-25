import logging
import re
import os
from urllib2 import quote
from rdflib import Graph, ConjunctiveGraph, RDF, RDFS, Namespace
from rdflib.parser import create_input_source
from rdflib.util import guess_format, SUFFIX_FORMAT_MAP


RDF_VOCAB_CACHE_DIRS = [
        os.environ.get('RDF_VOCAB_CACHE', ''),
        '~/rdf-vocab-cache',
        '~/Documents/rdf-vocab-cache',
        '/usr/local/share/rdf-vocab-cache/'
    ]

MAX_LINE_SCAN = 80
MATCH_NS_DECL = re.compile(
        r'''(?:@prefix\s+|xmlns:?|prefix\s+|PREFIX\s+|")(\w*)"?[:=]\s*[<"'"](.+?)[>"']''')
MATCH_URI_LEAF = re.compile(r'(.+[#/])([A-Za-z0-9_-]+)$')

PREFIX_URI_TEMPLATE = 'http://prefix.cc/{pfx}.file.ttl'

SUFFIX_FORMAT_MAP['jsonld'] = 'json-ld'

VOCAB_SOURCE_MAP = {
    "http://schema.org/": "http://schema.org/docs/schema_org_rdfa.html",
    #"http://www.w3.org/2001/XMLSchema#": "./xsd.ttl",
}


logger = logging.getLogger(__name__)


def find_rdf_vocab_cache():
    for fpath in RDF_VOCAB_CACHE_DIRS:
        fpath = os.path.expanduser(fpath)
        if os.path.isdir(fpath):
            return fpath

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
        self._graphcache = GraphCache(basedir)
        self._prefix_file = os.path.join(basedir, 'prefixes.ttl')
        self.reload()

    def reload(self):
        self._terms_by_ns = {}
        self._load_prefixes()

    def _load_prefixes(self):
        self._pfxgraph = Graph()
        if os.path.isfile(self._prefix_file):
            self._pfxgraph.parse(self._prefix_file, format='turtle')

    def get_pfx_iri(self, pfx):
        ns = self._pfxgraph.store.namespace(pfx)
        if not ns:
            url = PREFIX_URI_TEMPLATE.format(pfx=pfx)
            logger.debug("Fetching <%s>" % url)
            try:
                self._pfxgraph.parse(url, format='turtle')
            except: # not found
                logger.debug("Could not read <%s>" % url)
            if self._prefix_file:
                logger.debug("Saving prefixes to '%s'" % self._prefix_file)
                self._pfxgraph.serialize(self._prefix_file, format='turtle')
            ns = self._pfxgraph.store.namespace(pfx)
        return ns

    def get_vocab_terms(self, ns):
        terms = self._terms_by_ns.get(ns)
        if terms is None and ns:
            graph = self._graphcache.load(ns)
            self._collect_vocab_terms(graph, ns)
        return self._terms_by_ns.get(ns)

    def _collect_vocab_terms(self, graph, ns):
        terms = set()
        items = set(graph.subjects(RDF.type|RDFS.isDefinedBy, None))
        for subject in items:
            uri, leaf = split_uri(subject)
            if uri == str(ns) and leaf:
                terms.add(leaf)
        self._terms_by_ns[ns] = sorted(terms)

    def get_completions(self, buffer, context, base):
        prefix = context.split(':')[0]

        if prefix.lower() == 'prefix':
            pfx_fmt = '%s: <%s>'
        elif prefix == 'xmlns':
            pfx_fmt = '%s="%s"'
        else:
            pfx_fmt = None

        if pfx_fmt:
            results = [pfx_fmt % (pfx, ns)
                for pfx, ns in self._pfxgraph.namespaces()
                if pfx.startswith(base)]
            if not results:
                ns = self.get_pfx_iri(base)
                if ns:
                    results = [pfx_fmt % (base, ns)]

        else:
            pfxns = get_pfxns_map(buffer)
            ns = pfxns.get(prefix)
            withprefixes = ':' not in context
            curies = self._rdfns_vocabulary_names(ns, withprefixes)
            results = [value for value in curies if value.startswith(base)]

        return [{'word': value, 'icase': 0} for value in results]

    def _rdfns_vocabulary_names(self, ns, withprefixes=False):
        vocab = self.get_vocab_terms(ns) or []
        pfxs = []
        if withprefixes:
            pfxs += [pfx+':' for pfx, ns in sorted(self._pfxgraph.namespaces())]
        return pfxs + vocab


class GraphCache(object):

    def __init__(self, cachedir):
        self.graph = ConjunctiveGraph()
        self.mtime_map = {}
        self.cachedir = cachedir
        if not os.path.isdir(cachedir):
            os.makedirs(cachedir)

    def load(self, url):
        src = VOCAB_SOURCE_MAP.get(str(url), url)
        if os.path.isfile(url):
            context_id = create_input_source(url).getPublicId()
            last_vocab_mtime = self.mtime_map.get(url)
            vocab_mtime = os.stat(url).st_mtime
            if not last_vocab_mtime or last_vocab_mtime < vocab_mtime:
                logger.debug("Parse file: '%s'", url)
                self.mtime_map[url] = vocab_mtime
                # use CG as workaround for json-ld always loading as dataset
                graph = ConjunctiveGraph()
                graph.parse(src, format=guess_format(src))
                self.graph.remove_context(context_id)
                for s, p, o in graph:
                    self.graph.add((s, p, o, context_id))
                return graph
        else:
            context_id = url

        if any(self.graph.triples((None, None, None), context=context_id)):
            logger.debug("Using context <%s>" % context_id)
            return self.graph.get_context(context_id)

        cache_path = os.path.join(self.cachedir, quote(url, safe="")) + '.ttl'
        if os.path.exists(cache_path):
            logger.debug("Load local copy of <%s> from '%s'", context_id, cache_path)
            return self.graph.parse(cache_path, format='turtle', publicID=context_id)
        else:
            logger.debug("Fetching <%s> to '%s'", context_id, cache_path)
            graph = self.graph.parse(src,
                    format='rdfa' if url.endswith('html') else None)
            with open(cache_path, 'w') as f:
                graph.serialize(f, format='turtle')
            return graph


if __name__ == '__main__':
    import rdfns
    import sys
    args = sys.argv[1:]

    rdfns_tool = rdfns.Tool(rdfns.find_rdf_vocab_cache())

    pfx = args.pop(0) if args else 'schema'
    uri = rdfns_tool.get_pfx_iri(pfx)
    print("%s: %s" % (pfx, uri))
    for t in rdfns_tool.get_vocab_terms(uri):
        print("    %s" % t)
