# Author:: Couchbase <info@couchbase.com>
# Copyright:: 2011-2012 Couchbase, Inc.
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
  # This class encapsulates structured JSON document
  #
  # @since 1.2.0
  #
  # It behaves like Hash for document included into row, and has access methods to row data as well.
  #
  # @see http://www.couchbase.com/docs/couchbase-manual-2.0/couchbase-views-datastore.html
  class ViewRow
    include Constants

    # Undefine as much methods as we can to free names for views
    instance_methods.each do |m|
      undef_method(m) if m.to_s !~ /(?:^__|^nil\?$|^send$|^object_id$|^class$|)/
    end

    # The hash built from JSON document.
    #
    # @since 1.2.0
    #
    # This is complete response from the Couchbase
    #
    # @return [Hash]
    attr_accessor :data

    # The key which was emitted by map function
    #
    # @since 1.2.0
    #
    # @see http://www.couchbase.com/docs/couchbase-manual-2.0/couchbase-views-writing-map.html
    #
    # Usually it is String (the object +_id+) but it could be also any
    # compount JSON value.
    #
    # @return [Object]
    attr_accessor :key

    # The value which was emitted by map function
    #
    # @since 1.2.0
    #
    # @see http://www.couchbase.com/docs/couchbase-manual-2.0/couchbase-views-writing-map.html
    #
    # @return [Object]
    attr_accessor :value

    # The document hash.
    #
    # @since 1.2.0
    #
    # It usually available when view executed with +:include_doc+ argument.
    #
    # @return [Hash]
    attr_accessor :doc

    # The identificator of the document
    #
    # @since 1.2.0
    #
    # @return [String]
    attr_accessor :id

    # The meta data linked to the document
    #
    # @since 1.2.0
    #
    # @return [Hash]
    attr_accessor :meta

    # Initialize the document instance
    #
    # @since 1.2.0
    #
    # It takes reference to the bucket, data hash.
    #
    # @param [Couchbase::Bucket] bucket the reference to connection
    # @param [Hash] data the data hash, which was built from JSON document
    #   representation
    def initialize(bucket, data)
      @bucket = bucket
      @data = data
      @key = data[S_KEY]
      @value = data[S_VALUE]
      if data[S_DOC]
        @meta = data[S_DOC][S_META]
        @doc = data[S_DOC][S_VALUE]
      end
      @id = data[S_ID] || @meta && @meta[S_ID]
      @last = data.delete(S_IS_LAST) || false
    end

    # Wraps data hash into ViewRow instance
    #
    # @since 1.2.0
    #
    # @see ViewRow#initialize
    #
    # @param [Couchbase::Bucket] bucket the reference to connection
    # @param [Hash] data the data hash, which was built from JSON document
    #   representation
    #
    # @return [ViewRow]
    def self.wrap(bucket, data)
      self.new(bucket, data)
    end

    # Get attribute of the document
    #
    # @since 1.2.0
    #
    # Fetches attribute from underlying document hash
    #
    # @param [String] key the attribute name
    #
    # @return [Object] property value or nil
    def [](key)
      @doc[key]
    end

    # Check attribute existence
    #
    # @since 1.2.0
    #
    # @param [String] key the attribute name
    #
    # @return [true, false] +true+ if the given attribute is present in in
    #   the document.
    def has_key?(key)
      @doc.has_key?(key)
    end

    # Set document attribute
    #
    # @since 1.2.0
    #
    # Set or update the attribute in the document hash
    #
    # @param [String] key the attribute name
    # @param [Object] value the attribute value
    #
    # @return [Object] the value
    def []=(key, value)
      @doc[key] = value
    end

    # Signals if this row is last in a stream
    #
    # @since 1.2.1
    #
    # @return [true, false] +true+ if this row is last in a stream
    def last?
      @last
    end

    def inspect
      desc = "#<#{self.class.name}:#{self.object_id}"
      [:@id, :@key, :@value, :@doc, :@meta].each do |iv|
        desc << " #{iv}=#{instance_variable_get(iv).inspect}"
      end
      desc << ">"
      desc
    end
  end

  # This class encapsulates information about design docs
  #
  # @since 1.2.1
  #
  # It is subclass of ViewRow, but also gives access to view creation through method_missing
  #
  # @see http://www.couchbase.com/docs/couchbase-manual-2.0/couchbase-views-datastore.html
  class DesignDoc < ViewRow
    # It isn't allowed to change design document ID after
    # initialization
    undef id=

    # Initialize the design doc instance
    #
    # @since 1.2.1
    #
    # It takes reference to the bucket, data hash. It will define view
    # methods if the data object looks like design document.
    #
    # @param [Couchbase::Bucket] bucket the reference to connection
    # @param [Hash] data the data hash, which was built from JSON document
    #   representation
    def initialize(bucket, data)
      super
      @all_views = {}
      @views = @doc.has_key?('views') ? @doc['views'].keys : []
      @spatial = @doc.has_key?('spatial') ? @doc['spatial'].keys : []
      @views.each{|name| @all_views[name] = "#{@id}/_view/#{name}"}
      @spatial.each{|name| @all_views[name] = "#{@id}/_spatial/#{name}"}
    end

    def method_missing(meth, *args)
      if path = @all_views[meth.to_s]
        View.new(@bucket, path, *args)
      else
        super
      end
    end

    def respond_to?(meth, *args)
      if @all_views[meth.to_s]
        true
      else
        super
      end
    end

    def method(meth, *args)
      if path = @all_views[meth.to_s]
        lambda{|*p| View.new(@bucket, path, *p)}
      else
        super
      end
    end

    # The list of views defined or empty array
    #
    # @since 1.2.1
    #
    # @return [Array<View>]
    attr_accessor :views

    # The list of spatial views defined or empty array
    #
    # @since 1.2.1
    #
    # @return [Array<View>]
    attr_accessor :spatial

    # Check if the document has views defines
    #
    # @since 1.2.1
    #
    # @see DesignDoc#views
    #
    # @return [true, false] +true+ if the document have views
    def has_views?
      !@views.empty?
    end

    def inspect
      desc = "#<#{self.class.name}:#{self.object_id}"
      [:@id, :@views, :@spatial].each do |iv|
        desc << " #{iv}=#{instance_variable_get(iv).inspect}"
      end
      desc << ">"
      desc
    end

  end
end
