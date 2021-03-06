# Author:: Joe Winter <jwinter@jwinter.org>
# Copyright:: 2013 jwinter.org
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

module Couchbase::Operations
  module Fetch

    def fetch(key, set_options = {}, get_options = {}, &block)
      fail ArgumentError 'Must pass a block to #fetch' unless block_given?

      get_options[:quiet] = false
      get(key, get_options)
    rescue Couchbase::Error::NotFound
      yield(block).tap {|value| set(key, value, set_options) }
    end

  end
end
