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

gem 'minitest'
require 'coveralls'
Coveralls.wear!
if ENV['TRAVIS_BUILD_ID']
  require 'minitest'
else
  require 'minitest/autorun'
end
require 'couchbase'
require 'open-uri'
require 'ostruct'
require_relative 'mock'
require 'pry'

# Surpress connection logging
# java_import java.lang.System
# java_import java.util.logging.Logger
# java_import java.util.logging.Level

# properties = System.getProperties
# properties.put("net.spy.log.LoggerImpl", "net.spy.memcached.compat.log.Log4JLogger")
# System.setProperties(properties)

# Logger.getLogger('net.spy.memcached').setLevel(Level::SEVERE)
# Logger.getLogger('com.couchbase.client').setLevel(Level::SEVERE)
# Logger.getLogger('com.couchbase.client.vbucket').setLevel(Level::SEVERE)

# $stderr = StringIO.new

class Minitest::Test

  def cb
    Couchbase.bucket
  end

  def with_configs(configs = {})
    configs = Couchbase::Bucket::DEFAULT_OPTIONS.merge(configs)
    if configs[:host].nil?
      configs[:host] = configs[:hostname]
    end
    yield OpenStruct.new(configs)
  end

  def uniq_id(*suffixes)
    test_id = [caller.first[/.*[` ](.*)'/, 1], suffixes].compact.join("_")
    @ids ||= {}
    @ids[test_id] ||= Time.now.to_f
    [test_id, @ids[test_id]].join("_")
  end

end

$mock = start_mock

if ENV['TRAVIS_BUILD_ID']
  Dir.glob('test/test_*.rb').each { |test| require test }
  exit_code = Minitest.run(ARGV)
  Couchbase.disconnect
  $mock.stop
  java.lang.System.exit(exit_code ? 0 : 1)
else
  Minitest.after_run do
    $mock.stop
    Couchbase.disconnect
  end
end
