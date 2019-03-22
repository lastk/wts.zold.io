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
require 'zold/remotes'
require 'zold/amount'
require_relative 'test__helper'
require_relative '../objects/pgsql'
require_relative '../objects/payables'

class PayablesTest < Minitest::Test
  def test_add_and_fetch
    WebMock.disable_net_connect!
    Dir.mktmpdir 'test' do |dir|
      remotes = Zold::Remotes.new(file: File.join(dir, 'remotes.csv'))
      remotes.clean
      remotes.masters
      m = remotes.all[0]
      remotes.all.each_with_index { |r, idx| remotes.remove(r[:host], r[:port]) if idx.positive? }
      wallets = %w[0000111122223333 ffffeeeeddddcccc 0123456701234567]
      stub_request(:get, "http://#{m[:host]}:#{m[:port]}/wallets").to_return(
        status: 200, body: wallets.join("\n")
      )
      remotes.add('localhost', 444)
      remotes.add(m[:host], m[:port])
      remotes.add('localhost', 123)
      wallets.each do |id|
        stub_request(:get, "http://#{m[:host]}:#{m[:port]}/wallet/#{id}/balance").to_return(
          status: 200, body: '1234567'
        )
      end
      payables = Payables.new(Pgsql::TEST.start, remotes, log: test_log)
      payables.discover
      assert_equal(wallets.count, payables.fetch.count)
      payables.update(max: wallets.count)
      payables.remove_banned
      assert_equal(Zold::Amount.new(zents: 1_234_567), payables.fetch[0][:balance])
      assert(payables.total >= 1)
      assert(payables.balance > Zold::Amount::ZERO)
    end
  end
end
