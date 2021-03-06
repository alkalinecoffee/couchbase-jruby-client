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

class TestArithmetic < Minitest::Test

  def test_trivial_incr_decr
    cb.set(uniq_id, 1)
    val = cb.incr(uniq_id)
    assert_equal 2, val
    val = cb.get(uniq_id)
    assert_equal 2, val

    cb.set(uniq_id, 7)
    val = cb.decr(uniq_id)
    assert_equal 6, val
    val = cb.get(uniq_id)
    assert_equal 6, val
  end

  def test_it_fails_to_incr_decr_missing_key
    assert_raises(Couchbase::Error::NotFound) do
      cb.incr(uniq_id(:missing))
    end
    assert_raises(Couchbase::Error::NotFound) do
      cb.decr(uniq_id(:missing))
    end
  end

  def test_it_allows_to_make_increments_less_verbose_by_forcing_create_by_default
    cb.default_arithmetic_init = true
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id)
    end
    assert_equal 0, cb.incr(uniq_id), "return value"
    assert_equal 0, cb.get(uniq_id), "via get command"
  ensure
    cb.default_arithmetic_init = 0
  end

  def test_it_allows_to_setup_initial_value_during_connection
    cb.default_arithmetic_init = 10
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id)
    end

    assert_equal 10, cb.incr(uniq_id), "return value"
    assert_equal 10, cb.get(uniq_id), "via get command"
  ensure
    cb.default_arithmetic_init = 0
  end

  def test_it_allows_to_change_default_initial_value_after_connection
    assert_equal 0, cb.default_arithmetic_init
    assert_raises(Couchbase::Error::NotFound) do
      cb.incr(uniq_id)
    end

    cb.default_arithmetic_init = 10
    assert_equal 10, cb.default_arithmetic_init
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id)
    end
    assert_equal 10, cb.incr(uniq_id), "return value"
    assert_equal 10, cb.get(uniq_id), "via get command"
  ensure
    cb.default_arithmetic_init = 0
  end

  def test_it_creates_missing_key_when_initial_value_specified
    val = cb.incr(uniq_id(:missing), :initial => 5)
    assert_equal 5, val
    val = cb.incr(uniq_id(:missing), :initial => 5)
    assert_equal 6, val
    val = cb.get(uniq_id(:missing))
    assert_equal 6, val
  end

  def test_it_uses_zero_as_default_value_for_missing_keys
    val = cb.incr(uniq_id(:missing), :create => true)
    assert_equal 0, val
    val = cb.incr(uniq_id(:missing), :create => true)
    assert_equal 1, val
    val = cb.get(uniq_id(:missing))
    assert_equal 1, val
  end

  def test_it_allows_custom_ttl
    val = cb.incr(uniq_id(:missing), :create => true, :ttl => 1)
    assert_equal 0, val
    val = cb.incr(uniq_id(:missing), :create => true)
    assert_equal 1, val
    sleep(2)
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id(:missing))
    end
  end

  def test_decrement_with_absolute_ttl
    skip unless $mock.real?
    # absolute TTL: one second from now
    exp = Time.now.to_i + 1
    val = cb.decr(uniq_id, 12, :initial => 0, :ttl => exp)
    assert_equal 0, val
    assert_equal 0, cb.get(uniq_id)
    sleep(3)
    assert_raises(Couchbase::Error::NotFound) do
      cb.get(uniq_id)
    end
  end

  def test_it_allows_custom_delta
    cb.set(uniq_id, 12)
    val = cb.incr(uniq_id, 10)
    assert_equal 22, val
  end

  def test_it_allows_to_specify_delta_in_options
    cb.set(uniq_id, 12)
    options = {:delta => 10}
    val = cb.incr(uniq_id, options)
    assert_equal 22, val
  end

  def test_multi_incr
    cb.set(uniq_id(:foo) => 1, uniq_id(:bar) => 1)

    assert_equal [2, 2],   cb.incr(uniq_id(:foo), uniq_id(:bar)).values.sort
    assert_equal [12, 12], cb.incr(uniq_id(:foo), uniq_id(:bar), :delta => 10).values.sort
    assert_equal [14, 15], cb.incr(uniq_id(:foo) => 2, uniq_id(:bar) => 3).values.sort
  end

  def test_multi_decr
    cb.set(uniq_id(:foo) => 14, uniq_id(:bar) => 15)

    assert_equal [12, 12], cb.decr(uniq_id(:foo) => 2, uniq_id(:bar) => 3).values.sort
    assert_equal [2, 2],   cb.decr(uniq_id(:foo), uniq_id(:bar), :delta => 10).values.sort
    assert_equal [1, 1],   cb.decr(uniq_id(:foo), uniq_id(:bar)).values.sort
  end
end
