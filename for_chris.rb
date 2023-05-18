require 'linkeddata'

graph = RDF::Graph.load(" https://pathvisio.org/")
query = SPARQL.parse("select DISTINCT ?p ?o where {<https://pathvisio.org/> ?p ?o}")
r = query.execute(graph)

# schema:name, url, description, citation, license, applicationCategory, operatingSystem
# r.each do |res|
#   title = res[:p]

name = r.select {|res| res[:p] == "http://schema.org/name"; return res[:o]}
url = r.select {|res| res[:p] == "http://schema.org/url"; return res[:o]}
description = r.select {|res| res[:p] == "http://schema.org/description"; return res[:o]}
citation = r.select {|res| res[:p] == "http://schema.org/citation"; return res[:o]}
license = r.select {|res| res[:p] == "http://schema.org/license"; return res[:o]}
applicationCategory = r.select {|res| res[:p] == "http://schema.org/applicationCategory"; return res[:o]}
operatingSystem = r.select {|res| res[:p] == "http://schema.org/operatingSystem"; return res[:o]}
