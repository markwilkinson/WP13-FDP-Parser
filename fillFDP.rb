require './resource.rb'
require './catalog.rb'
require './dataset.rb'
require './distribution.rb'
require './access_service.rb'
require 'esv'
require 'linkeddata'

# ENV['FDPUSER']
# ENV['FDPPASS'] 
@fdp_server = ENV['FDP_SERVER'] || "http://localhost:7070"
@baseURI = ENV['BASE_URI'] || "http://localhost:7070"

VPQUERYABLE = "http://purl.org/ejp-rd/vocabulary/VPQueryable"
VPDISCOVERABLE = "http://purl.org/ejp-rd/vocabulary/VPDiscoverable"

@title = "EJP WP13 Data Services Catalog"  
@description = "Catalog of tools and analytical services identified by WP13 as important to the EJP"
@hasVersion = "1.0"
@issued = Time.now.strftime('%Y-%m-%d')
@modified = @issued
@publisher = "https://www.ejprarediseases.org/"
@creator = "https://www.ejprarediseases.org/"
@creatorName = "Mark D Wilkinson"
@parentURI = @fdp_server

@catalog = createCatalog

services = ["https://pathvisio.org/", ]
services.each do |service|
  graph = RDF::Graph.load(service)
  query = SPARQL.parse("select DISTINCT ?p ?o where {<#{service}> ?p ?o}")
  r = query.execute(graph)

  extractAnnotations(r)

  # create dataset
  @hasVersion = "1.0"
  @issued = Datetime()
  @modified = Datetime()  
  @parentURI = @catalog.identifier
  @theme = VPDISCOVERABLE
  @title = "Dataset for: #{otitle}"
  @description = "The Dataset underlying the functionality of #{otitle}.  #{odescription}"
  @dataset = createDataset

  # create Distribution
  @title = "Distribution of: #{otitle}"
  @description = "The distribution of #{otitle} is made available through the data access services shown below.  #{odescription}"
  @parentURI = @dataset.identifier

  # create accessService
  @title = "Accessing: #{otitle}"
  @description = "The access #{otitle} is made available through the access URL indicated."
  @parentURI = @dataset.identifier



  # dataset.distribution= distribution.identifier.to_s
  dataset.write_dataset

end

def extractAnnotations(r:)
  @title = r.map {|res| res[:o] if res[:p] == "http://schema.org/name"}
  @endpointURL = r.map {|res| res[:o] if res[:p] == "http://schema.org/url"}
  @description = r.map {|res| res[:o] if res[:p] == "http://schema.org/description"}
  @citation = r.map {|res| res[:o] if res[:p] == "http://schema.org/citation"}
  @license = r.map {|res| res[:o] if res[:p] == "http://schema.org/license"}
  @applicationCategory = r.map {|res| res[:o] if res[:p] == "http://schema.org/applicationCategory"}
  @operatingSystem = r.map {|res| res[:o] if res[:p] == "http://schema.org/operatingSystem"}
  @keywords = [applicationCategory + operatingSystem]  # TODO
  @title = @title.compact.first.to_s
  @otitle = @title.compact.first.to_s  # copy original, so we can edit it
  @url = @url.compact.first.to_s
  @description = @description.compact.first.to_s
  @odescription = @description.compact.first.to_s # copy original, so we can edit it
  @citation = @citation.compact.first.to_s
  @license = @license.compact.first.to_s
  @applicationCategory = @applicationCategory.compact.first.to_s
  @operatingSystem = @operatingSystem.compact.first.to_s
end

def createCatalog()
  @catalog = DCATCatalog.new(
      serverURL: @fdp_server,
      baseURI: @baseURI,
      title: @title,  
      description: @description,
      hasVersion: @hasVersion,
      issued: @issued, 
      modified: @modified,
      publisher: @publisher, 
      license: @license, 
      creator:  @creator,
      parentURI: @parentURI,
  )
  return @catalog
end

def createDataset()

  @dataset = DCATDataset.new(
    serverURL: @fdp_server,
    baseURI: @baseURI,
    title: @title,  
    description: @description,
    hasVersion: @hasVersion,
    issued: @issued, 
    modified: @modified,
    publisher: @publisher, 
    license: @license, 
    creator: @creator,
    landingPage: @biotool,
    theme: @theme,
    parentURI: @parentURI,
  )
  @catalog.dataset= @dataset.identifier.to_s
  @catalog.themeTaxonomy = @dataset.identifier.to_s + "#conceptscheme"
  @catalog.write_catalog
end

# distribution = nil
# if hash['dist_endpointURL'] or hash['dist_endpointDescription'] 
#     $stderr.puts "starting to create dataservice"
def createDistribution
  warn "starting to create distribution"
  distribution = DCATDistribution.new(
    serverURL: @fdp_server,
    baseURI: @baseURI,
    title: @title,
    description: @description,
    hasVersion: @hasVersion,
    issued: @issued,
    modified: @modified,
    publisher: @publisher,
    creator: @creator,
    creatorName: @creatorName,
    contactName: @contactName,
    contactEmail: @contactEmail,
    conformsTo: @conformsTo,
    license: @license,
    accessRights: @accessRights,
    dist_downloadURL: @downloadURL,
    mediaType: @mediaType,
    format: @format,
    parentURI: @parentURI
  )
  @dataset.distribution= @distribution.identifier.to_s
  @dataset.write_dataset
end

def createDataService
  @ds = DCATDataService.new(
      serverURL: @server,
      baseURI: @baseURI,
      title: @title,
      description: @description,
      hasVersion: @hasVersion,
      issued: @issued,
      modified: @modified,
      publisher: @publisher,
      creator: @creator,
      creatorName: @creatorName,
      contactName: @contactName,
      contactEmail: @contactEmail,
      conformsTo: @conformsTo,
      license: @license,
      accessRights: @accessRights,
      dist_downloadURL: @downloadURL,
      mediaType: @mediaType,
      format: @format,
      endpointDescription: @endpointDescription,
      endpointURL: @endpointURL,
      parentURI: @parentURI
  )
  @distribution.dataService= @ds.identifier.to_s
  @distribution.write_distribution
end

catalog.publish
dataset.publish
# distribution.publish