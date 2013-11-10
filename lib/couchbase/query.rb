module Couchbase
  class Query

    java_import com.couchbase.client.protocol.views.Stale

    METHOD_MAPPING = {
      :include_docs       => :setIncludeDocs,
      :descending         => :setDescending,
      :key                => :setKey,
      :keys               => :setKeys,
      :start_key          => :setRangeStart,
      :startkey           => :setRangeStart,
      :startkey_docid     => :setStartkeyDocID,
      :endkey             => :setRangeEnd,
      :endkey_docid       => :setEndkeyDocID,
      :inclusive_end      => :setInclusiveEnd,
      :limit              => :setLimit,
      :skip               => :setSkip,
      :reduce             => :setReduce,
      :group              => :setGroup,
      :group_level        => :setGroupLevel,
      :connection_timeout => nil
    }.freeze

    def initialize(params)
      @params = params
    end

    def generate
      query = Java::ComCouchbaseClientProtocolViews::Query.new

      if stale = @params.delete(:stale)
        case stale
        when :after_update
          query.setStale(Stale::UPDATE_AFTER)
        when :ok
          query.setStale(Stale::OK)
        when false
          query.setStale(Stale::FALSE)
        end
      end

      @params.each_pair do |meth, val|
        if METHOD_MAPPING.key?(meth)
          if java_meth = METHOD_MAPPING[meth]
            query.send(java_meth, val)
          end
        else
          fail ArgumentError, "Query does not support #{meth}"
        end
      end

      
    # @option params [true, false] :quiet (true) Do not raise error if
    #   associated document not found in the memory. If the parameter +true+
    #   will use +nil+ value instead.
    # @option params [String, Symbol] :on_error (:continue) Sets the
    #   response in the event of an error. Supported values:
    #   :continue:: Continue to generate view information in the event of an
    #               error, including the error information in the view
    #               response stream.
    #   :stop::     Stop immediately when an error condition occurs. No
    #               further view information will be returned.
    # @option params [Fixnum] :connection_timeout (75000) Timeout before the
    #   view request is dropped (milliseconds)


    # @option params [Hash] :body 
      query
    end

  end
end