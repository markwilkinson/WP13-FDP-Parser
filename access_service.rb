class DCATDataService < DCATResource
    attr_accessor :endpointDescription, :endpointURL
    
    def initialize(endpointDescription: nil, endpointURL: nil, parent_distribution:,  **args )
        @endpointDescription = endpointDescription
        @endpointURL = endpointURL
        super 
        $stderr.puts "Building Data Service"
        $stderr.puts self.endpointDescription, self.endpointURL, self.class
        
        self.types = [DCAT.Resource, DCAT.DataService]
        init_accessService   # create record and get GUID
        build # make the RDF
        write_accessService
        parent_distribution.accessServices << self
    end

    def init_accessService
      warn "initializing access Service"
      asinit = <<~END
        @prefix dcat: <http://www.w3.org/ns/dcat#> .
        @prefix dct: <http://purl.org/dc/terms/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        <> a dcat:accessService, dcat:Resource ;
            dct:title "test" ;
            dct:hasVersion "1.0" ;
            dct:publisher [ a foaf:Agent ; foaf:name "Example User" ] ;
            dct:isPartOf <#{@parentURI}> .
END

      warn "#{serverURL}/dataservice"
      warn "#{asinit}\n\n"
      resp = RestClient.post("#{serverURL}/dataservice", asinit, $headers)
      aslocation = resp.headers[:location]
      puts "temporary distribution written to #{aslocation}\n\n"
      self.identifier = RDF::URI(aslocation)  # set identifier to where it lives
    end

    def write_accessService
      build
      location = identifier.to_s.gsub(baseURI, serverURL)
      warn "rewriting access service to #{location}"
      ds = serialize
      warn ds
      resp = RestClient.put(location, ds, $headers)
      warn resp.headers.to_s
    end
  
end

