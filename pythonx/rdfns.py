import logging
import re
import os
from urllib2 import quote
from rdflib import Graph, ConjunctiveGraph
from rdflib.namespace import RDF, RDFS, Namespace, split_uri
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
        r'''(?:@prefix\s+|xmlns:?|vocab|prefix\s+|PREFIX\s+|")(?:@vocab|(\w*))"?[:=]\s*[<"'"](.+?)[>"']''')

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


class Tool(object):

    def __init__(self, basedir=None):
        basedir = basedir or find_rdf_vocab_cache()
        self.prefixes = PrefixCache(os.path.join(basedir, 'prefixes.ttl'))
        self.graphcache = GraphCache(basedir)
        self._terms_by_ns = {}

    def get_vocab_terms(self, ns):
        terms = self._terms_by_ns.get(ns)
        if terms is None and ns:
            graph = self.graphcache.load(ns)
            self._collect_vocab_terms(graph, ns)
        return self._terms_by_ns.get(ns)

    def _collect_vocab_terms(self, graph, ns):
        terms = set()
        items = set(graph.subjects(RDF.type|RDFS.isDefinedBy, None))
        for subject in items:
            try:
                uri, leaf = split_uri(subject)
                if uri == unicode(ns) and leaf:
                    terms.add(leaf)
            except:
                pass
        self._terms_by_ns[ns] = sorted(terms)

    def get_completions(self, buffer, context, base):
        prefix = context.split(':')[0]
        pfx_fmt = ('%s: <%s>' if prefix.lower() == 'prefix'
                else '%s="%s"' if prefix == 'xmlns'
                else None)
        if pfx_fmt:
            results = self._get_pfx_declarations(pfx_fmt, base)
        else:
            curies = self._get_values(get_pfxns_map(buffer), prefix,
                    ':' not in context)
            results = (curie for curie in curies if curie.startswith(base))
        return [{'word': value, 'icase': 0} for value in results]

    def _get_pfx_declarations(self, pfx_fmt, base):
        results = [pfx_fmt % (pfx, ns)
            for pfx, ns in self.prefixes.namespaces()
            if pfx.startswith(base)]
        if not results:
            ns = self.prefixes.lookup(base)
            if ns:
                results = [pfx_fmt % (base, ns)]
        return results

    def _get_values(self, pfxns, prefix, withprefixes):
        ns = pfxns.get(prefix)
        terms = self.get_vocab_terms(ns) or []
        if withprefixes:
            return [pfx+':' for pfx in sorted(pfxns)] + terms
        else:
            return terms


class PrefixCache(object):

    PREFIX_URI_TEMPLATE = 'http://prefix.cc/{pfx}.file.ttl'

    def __init__(self, prefix_file):
        self._prefix_file = prefix_file
        self._pfxgraph = Graph()
        if os.path.isfile(self._prefix_file):
            self._pfxgraph.parse(self._prefix_file, format='turtle')

    def lookup(self, pfx):
        ns = self._pfxgraph.store.namespace(pfx)
        return ns or self._fetch_ns(pfx)

    def namespaces(self):
        return self._pfxgraph.namespaces()

    def _fetch_ns(self, pfx):
        url = self.PREFIX_URI_TEMPLATE.format(pfx=pfx)
        logger.debug("Fetching <%s>" % url)
        try:
            self._pfxgraph.parse(url, format='turtle')
        except: # not found
            logger.debug("Could not read <%s>" % url)
        if self._prefix_file:
            logger.debug("Saving prefixes to '%s'" % self._prefix_file)
            self._pfxgraph.serialize(self._prefix_file, format='turtle')
        return self._pfxgraph.store.namespace(pfx)


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
    import sys
    args = sys.argv[1:]
    pfx = args.pop(0) if args else 'schema'

    rdfns_tool = Tool()
    uri = rdfns_tool.prefixes.lookup(pfx)
    print("%s: %s" % (pfx, uri))
    for t in rdfns_tool.get_vocab_terms(uri):
        print("    %s" % t)
