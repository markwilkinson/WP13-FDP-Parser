class DCATDataService < DCATDistribution
    attr_accessor :endpointDescription, :endpointURL
    
    def initialize(endpointDescription: nil, endpointURL: nil, **args )
        @endpointDescription = endpointDescription
        @endpointURL = endpointURL
        super 
        $stderr.puts "Building Data Service"
        $stderr.puts self.endpointDescription, self.endpointURL, self.class
        
        self.types = [DCAT.Resource, DCAT.DataService, DCAT.Distribution]

    end
  
    # def accessServices
    #   return $accessServices
    # end
    # def self.accessServices
    #   return $accessServices
    # end

end

