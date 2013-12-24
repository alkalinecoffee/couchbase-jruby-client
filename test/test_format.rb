# Author:: Couchbase <info@couchbase.com>
# Copyright:: 2011, 2012 Couchbase, Inc.
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

require File.join(File.dirname(__FILE__), 'setup')

class TestFormat < Minitest::Test

  ArbitraryClass = Struct.new(:name, :role)
  class SkinyClass < Struct.new(:name, :role)
    undef to_s rescue nil
    undef to_json rescue nil
  end

  def test_default_document_format
    orig_doc = {'name' => 'Twoflower', 'role' => 'The tourist'}
    assert_equal :document, cb.default_format
    cb.set(uniq_id, orig_doc)
    doc, flags, cas = cb.get(uniq_id, :extended => true)
    assert doc.is_a?(Hash)
    assert_equal 'Twoflower', doc['name']
    assert_equal 'The tourist', doc['role']
  end

  def test_it_raises_error_for_document_format_when_neither_to_json_nor_to_s_defined
    if (MultiJson.respond_to?(:engine) ? MultiJson.engine : MultiJson.adapter).name =~ /Yajl$/
      orig_doc = SkinyClass.new("Twoflower", "The tourist")
      refute orig_doc.respond_to?(:to_s)
      refute orig_doc.respond_to?(:to_json)

      assert_raises(Couchbase::Error::ValueFormat) do
        cb.set(uniq_id, orig_doc)
      end

      class << orig_doc
        def to_json
          MultiJson.dump(:name => name, :role => role)
        end
      end
      cb.set(uniq_id, orig_doc) # OK

      class << orig_doc
        undef to_json
        def to_s
          MultiJson.dump(:name => name, :role => role)
        end
      end
      cb.set(uniq_id, orig_doc) # OK
    end
  end

  def test_it_could_dump_arbitrary_class_using_marshal_format
    orig_doc = ArbitraryClass.new("Twoflower", "The tourist")
    cb.set(uniq_id, orig_doc, :format => :marshal)
    doc, flags, cas = cb.get(uniq_id, :extended => true)
    assert doc.is_a?(ArbitraryClass)
    assert_equal 'Twoflower', doc.name
    assert_equal 'The tourist', doc.role
  end

  def test_it_accepts_only_string_in_plain_mode
    cb.default_format = :plain
    cb.set(uniq_id, "1")

    assert_raises(Couchbase::Error::ValueFormat) do
      cb.set(uniq_id, 1)
    end

    assert_raises(Couchbase::Error::ValueFormat) do
      cb.set(uniq_id, {:foo => "bar"})
    end
  ensure
    cb.default_format = :document
  end

  def test_bignum_conversion
    cb.default_format = :plain
    cas = 0xffff_ffff_ffff_ffff
    assert cas.is_a?(Bignum)
    assert_raises(Couchbase::Error::NotFound) do
      cb.delete(uniq_id => cas)
    end
  ensure
    cb.default_format = :document
  end

  require 'zlib'
  # This class wraps any other transcoder and performs compression
  # using zlib
  class ZlibTranscoder
    FMT_ZLIB = 0x04

    def initialize(base)
      @base = base
    end

    def dump(obj, flags, options = {})
      obj, flags = @base.dump(obj, flags, options)
      z = Zlib::Deflate.new(Zlib::BEST_SPEED)
      buffer = z.deflate(obj, Zlib::FINISH)
      z.close
      [buffer, flags|FMT_ZLIB]
    end

    def load(blob, flags, options = {})
      # decompress value only if Zlib flag set
      if (flags & FMT_ZLIB) == FMT_ZLIB
        z = Zlib::Inflate.new
        blob = z.inflate(blob)
        z.finish
        z.close
      end
      @base.load(blob, flags, options)
    end
  end

  def test_it_can_use_custom_transcoder
    skip
    cb.transcoder = ZlibTranscoder.new(Couchbase::Transcoder::Document)
    cb.set(uniq_id, {"foo" => "bar"})
    doc, flags, _ = cb.get(uniq_id, :extended => true)
    assert_equal({"foo" => "bar"}, doc)
    assert_equal(ZlibTranscoder::FMT_ZLIB|Couchbase::Bucket::FMT_DOCUMENT, flags)
    cb.transcoder = nil
    doc = cb.get(uniq_id)
    assert_equal "x\x01\xABVJ\xCB\xCFW\xB2RJJ,R\xAA\x05\0\x1Dz\x044", doc
  end

end
