# Author:: Mike Evans <mike@urlgonomics.com>
# Copyright:: 2013 Urlgonomics LLC.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


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

      stale = @params.delete(:stale)
      if !stale.nil?
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

      query
    end

  end
end
