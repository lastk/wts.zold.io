# Copyright (c) 2018-2019 Zerocracy, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'webmock/minitest'
require 'openssl'
require 'zold/key'
require 'zold/id'
require 'zold/http'
require_relative 'test__helper'
require_relative '../objects/pgsql'
require_relative '../objects/item'

class WTS::ItemTest < Minitest::Test
  def test_create_and_read
    WebMock.allow_net_connect!
    item = WTS::Item.new("jeff#{rand(999)}", WTS::Pgsql::TEST.start, log: test_log)
    assert(!item.exists?)
    pvt = OpenSSL::PKey::RSA.new(2048)
    id = Zold::Id.new
    item.create(id, Zold::Key.new(text: pvt.to_pem))
    assert(item.exists?)
    assert_equal(id, item.id)
  end

  def test_wipes_keygap
    WebMock.allow_net_connect!
    item = WTS::Item.new("jeff#{rand(999)}", WTS::Pgsql::TEST.start, log: test_log)
    pvt = OpenSSL::PKey::RSA.new(2048)
    id = Zold::Id.new
    pem = pvt.to_pem
    key = Zold::Key.new(text: pem)
    keygap = item.create(id, key)
    assert_equal(key, item.key(keygap))
    assert_equal(id, item.id)
    assert(!item.wiped?)
    item.wipe(keygap)
    assert(item.wiped?)
    assert_equal(key, item.key(keygap))
  end
end
