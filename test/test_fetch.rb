# Author:: Joe Winter <jwinter@jwinter.org>
# Copyright:: 2013 jwinter.org
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

class TestFetch < Minitest::Test

  def test_trivial_fetch
    cb.fetch(uniq_id) do
      123
    end
    val = cb.get(uniq_id)
    assert_equal 123, val
  end

  def test_returns_existing_key_if_exists
    cb.set(uniq_id, 'abc')

    cb.fetch(uniq_id) do
      'xyz'
    end

    assert_equal 'abc', cb.get(uniq_id)
  end

  def test_can_include_get_options
    cb.set(uniq_id, 'abc')

    get_options = { extended: true }
    value, _, cas = cb.fetch(uniq_id, {}, get_options) do
      'unused'
    end

    assert_equal value, 'abc'
    assert cas.is_a?(Fixnum)
  end

  def test_can_include_set_options
    set_options = { ttl: 1 }

    cb.expects(:set).with(uniq_id, 'abc', set_options)
    cb.fetch(uniq_id, set_options) do
      'abc'
    end
  end

  def test_fetch_works_with_quiet_mode
    cb.quiet = true
    cb.fetch(uniq_id) do
      'xyz'
    end
    assert_equal 'xyz', cb.get(uniq_id)
  ensure
    cb.quiet = false
  end

end
