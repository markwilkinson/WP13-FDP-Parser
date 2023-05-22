require "./resource"
require "./catalog"
require "./dataset"
require "./distribution"
require "./access_service"
require "linkeddata"
VPQUERYABLE = "http://purl.org/ejp-rd/vocabulary/VPQueryable"
VPDISCOVERABLE = "http://purl.org/ejp-rd/vocabulary/VPDiscoverable"
SITES = %w[https://bridgedb.org/ https://graphviz.org https://www.bridgedb.org/pages/webservice.html
           http://bioconductor.org/packages/release/bioc/html/BridgeDbR.html
           https://anaconda.org/bioconda/orsum https://pypi.org/project/ODAMNet/
           http://www.ensembl.org/info/docs/tools/vep/index.html https://cytargetlinker.github.io/ https://github.com/CyTargetLinker/linksetCreator]
def main
  # ENV['FDPUSER']
  # ENV['FDPPASS']
  warn "Starting"
  serverURL = ENV["FDP_SERVER"] || "http://localhost:7070"
  baseURI = ENV["BASE_URI"] || "http://localhost:7070"

  title = "EJP WP13 Catalog of Data Services"
  description = "Catalog of tools and analytical services identified by WP13 as important to the EJP"
  hasVersion = "1.0"
  issued = Time.now.strftime("%Y-%m-%d")
  modified = @issued
  publisher = "https://www.ejprarediseases.org/"
  creator = "https://www.ejprarediseases.org/"
  creatorName = "Mark D Wilkinson"
  parentURI = @baseURI
  license = "http://rdflicense.appspot.com/rdflicense/cc-by-nc-nd4.0"
  parentURI = baseURI

  warn "creating catalog with parent #{parentURI}"
  catalog =  @catalog = DCATCatalog.new(
    serverURL: serverURL,
    baseURI: baseURI,
    title: title,
    description: description,
    hasVersion: hasVersion,
    issued: issued,
    modified: modified,
    publisher: publisher,
    license: license,
    creator: creator,
    creatorName: creatorName,
    parentURI: parentURI
  )

  warn "done"

  SITES.each do |site|
    graph = RDF::Graph.load(site)
    warn "TRIPLES"
    warn graph.triples

    options = process_url(url: site)
    # warn "select DISTINCT ?p ?o where {VALUES ?s {#{options}} ?s ?p ?o}"
    # query = SPARQL.parse("select DISTINCT ?p ?o where {VALUES ?s {#{options}} ?s ?p ?o}")
    query = SPARQL.parse("select DISTINCT ?p ?o where {?s ?p ?o}")
    r = query.execute(graph)
    warn "RESULTS"
    warn r.inspect
    warn "extracting annotations"

    applicationCategory ,title, landingPage, description, citation,
    license, operatingSystem, keywords, title, endpointURL, 
    description, citation, license = extractAnnotations(r: r)
    if title.empty?
      warn "Could not find a title for #{site}"
      file = File.open("failures", "a")
      file.write("#{site}\n")
      file.close
      next
    end
    # create dataset
    # hasVersion = "1.0"
    # issued = DateTime.now.strftime("%Y-%m-%d")
    # modified = DateTime.now.strftime("%Y-%m-%d")
    # parentURI = catalog.identifier
    # theme = [VPDISCOVERABLE]
    # title = "Dataset for: #{@otitle}"
    # description = "The Dataset underlying the functionality of #{@otitle}.  #{@odescription}"
    # warn "create dataset"
    # dataset = DCATDataset.new(
    #   serverURL: serverURL,
    #   baseURI: baseURI,
    #   title: title,
    #   description: description,
    #   hasVersion: hasVersion,
    #   issued: issued,
    #   modified: modified,
    #   publisher: publisher,
    #   license: license,
    #   creator: creator,
    #   creatorName: creatorName,
    #   landingPage: landingPage,
    #   theme: theme,
    #   parentURI: parentURI,
    #   parent_catalog: parent_catalog
    # )
    # catalog.datasets << @dataset

    # create Distribution
    # title = "Distribution of: #{@otitle}"
    # description = "The distribution of #{otitle} is made available through the data access services shown below.  #{odescription}"
    # parentURI = dataset.identifier
    # mediaType = "https://www.iana.org/assignments/media-types/text/html"
    # warn "create distribution"
    # distribution = DCATDistribution.new(
    #   serverURL: serverURL,
    #   baseURI: baseURI,
    #   title: title,
    #   description: description,
    #   hasVersion: hasVersion,
    #   issued: issued,
    #   modified: modified,
    #   publisher: publisher,
    #   creator: creator,
    #   creatorName: creatorName,
    #   contactName: contactName,
    #   contactEmail: contactEmail,
    #   conformsTo: conformsTo,
    #   license: license,
    #   accessRights: accessRights,
    #   dist_downloadURL: downloadURL,
    #   mediaType: mediaType,
    #   format: format,
    #   parent_dataset: parent_dataset,
    #   parentURI: parentURI,
    #   landingPage: landingPage
    # )
    # dataset.distributions << @distribution

    # create accessService
    # title = "Accessing: #{otitle}"
    # description = "Access to #{otitle} is made available through the 'landing page' button to the right."
    hasVersion = "1.0"
    issued = DateTime.now.strftime("%Y-%m-%d")
    modified = DateTime.now.strftime("%Y-%m-%d")
    parentURI = catalog.identifier
    warn "create accessService endpointURL: #{landingPage}"
    endpointURL = landingPage
    endpointDescription = landingPage
    as = DCATDataService.new(
      serverURL: serverURL,
      baseURI: baseURI,
      title: "Accessing: #{title}",
      name: "Accessing: #{title}",
      description: "Access to #{title} is made available through the 'landing page' button to the right.",
      hasVersion: hasVersion,
      issued: issued,
      modified: modified,
      publisher: publisher,
      creator: creator,
      creatorName: creatorName,
#      contactEmail: contactEmail,
#      conformsTo: conformsTo,
      license: license,
#      accessRights: accessRights,
#      endpointDescription: endpointDescription,
      endpointURL: endpointURL,
      parentURI: catalog.identifier,
      landingPage: landingPage,
      parent: catalog
    )
    catalog.accessServices << as
  end
end

def extractAnnotations(r:)
  applicationCategory = title = landingPage = description = citation = nil
  license = operatingSystem = keywords = title = endpointURL = nil
  description  = citation  = license = nil

  title = r.map { |res| res[:o] if res[:p] == "http://schema.org/name" }
  title = title.compact.first.to_s
  warn "title1 #{title}"
  if title.empty?
    title = r.map { |res| res[:o] if res[:p] == "http://ogp.me/ns#title" }
    title = title.compact.first.to_s
    warn "title2 #{title}"
  end
  if title.empty?
    title = r.map { |res| res[:o] if res[:p] == "http://ogp.me/ns#site_name" }
    title = title.compact.first.to_s
    warn "title3 #{title}"
  end
  landingPage = r.map { |res| res[:o] if res[:p] == "http://schema.org/url" }
  landingPage = landingPage.compact.first.to_s
  if landingPage.empty?
    landingPage = r.map { |res| res[:o] if res[:p] == "http://ogp.me/ns#url" }
    landingPage = landingPage.compact.first.to_s
  end

  description = r.map { |res| res[:o] if res[:p] == "http://schema.org/description" }
  description = description.compact.first.to_s
  if description.empty?
    description = r.map { |res| res[:o] if res[:p] == "http://ogp.me/ns#description" }
    description = description.compact.first.to_s
  end
  citation = r.map { |res| res[:o] if res[:p] == "http://schema.org/citation" }
  license = r.map { |res| res[:o] if res[:p] == "http://schema.org/license" }
  applicationCategory = r.map { |res| res[:o] if res[:p] == "http://schema.org/applicationCategory" }
  operatingSystem = r.map { |res| res[:o] if res[:p] == "http://schema.org/operatingSystem" }
  keywords = [applicationCategory + operatingSystem] # TODO
  citation = citation.compact.first.to_s
  license = license.compact.first.to_s
  applicationCategory = applicationCategory.compact.first.to_s
  operatingSystem = operatingSystem.compact.first.to_s
  return [applicationCategory ,title, landingPage, description, citation,
    license, operatingSystem, keywords, title, endpointURL, 
    description, citation, license]
end

def process_url(url:)
  options_string = ""
  url.strip!
  options = []
  options << url.sub("/www.", "/")
  options << url.sub("//", "//www.")
  options << url.sub("http://", "https://")
  options << url.sub("https://", "http://")
  options << url.sub("/www.", "/").sub("http://", "https://")
  options << url.sub("/www.", "/").sub("https://", "http://")
  options << url.sub("//", "//www.").sub("http://", "https://")
  options << url.sub("//", "//www.").sub("https://", "http://")

  moreoptions = []
  options.each do |o|
    moreoptions << (o + "/")
    moreoptions << url.gsub(%r{/$}, "")
  end
  options << moreoptions
  options.flatten!
  warn options.inspect
  options.each do |o|
    options_string += "<#{o}> "
  end
  warn options_string
  options_string
end

main

f = File.open("to_delete", "a")
@catalog.datasets.each do |ds|
  ds.distributions.each do |dist|
    dist.accessServices.each do |as|
      as.write_accessService
      f.write "#{as.identifier}\n"
      as.publish
    end
    dist.write_distribution
    f.write "#{dist.identifier}\n"
    dist.publish
  end
  ds.write_dataset
  f.write "#{ds.identifier}\n"
  ds.publish
end
@catalog.accessServices.each do |as|
    as.write_accessService
    f.write "#{as.identifier}\n"
    as.publish
end

@catalog.write_catalog
@catalog.publish
f.write "#{@catalog.identifier}\n"
f.close
