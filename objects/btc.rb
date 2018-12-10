# Copyright (c) 2018 Yegor Bugayenko
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'backtrace'
require 'zold/http'
require 'zold/json_page'
require_relative 'user_error'

#
# BTC gateway.
#
class Btc
  def initialize(aws, xpub, key, log: Zold::Log::NULL)
    @aws = aws
    @xpub = xpub
    @key = key
    @log = log
  end

  # Current price of one BTC
  def price
    JSON.parse(Zold::Http.new(uri: 'https://blockchain.info/ticker').get.body)['USD']['15m']
  end

  # Create new BTC address
  def create(login)
    callback = 'https://wts.zold.io/btc-hook?' + {
      'zold_user': login
    }.map { |k, v| "#{k}=#{CGI.escape(v)}" }.join('&')
    uri = 'https://api.blockchain.info/v2/receive?' + {
      'xpub': @xpub,
      'callback': callback,
      'key': @key,
      'gap_limit': 256
    }.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    res = Zold::Http.new(uri: uri).get
    raise UserError, "Can't create Bitcoin address for @#{login}, try again: #{res.status_line}" unless res.code == 200
    Zold::JsonPage.new(res.body).to_hash['address']
  end

  # Returns TRUE if transaction with this hash, amount, and target address exists
  def exists?(hash, amount, address)
    txn = Zold::JsonPage.new(Zold::Http.new(uri: "https://blockchain.info/rawtx/#{hash}").get.body).to_hash
    !txn['out'].find { |t| t['addr'] == address && t['value'] == amount }.nil?
  rescue StandardError => e
    @log.error(Backtrace.new(e))
    false
  end

  def paid?(hash)
    !@aws.query(
      table_name: 'zold-btc',
      limit: 1,
      expression_attribute_values: { ':h' => hash },
      key_condition_expression: 'txhash=:h'
    ).items.empty?
  end

  def paid(hash, login, wallet)
    @aws.put_item(
      table_name: 'zold-btc',
      item: {
        'txhash' => hash,
        'login' => login,
        'wallet' => wallet,
        'time' => Time.now.to_i
      }
    )
  end
end
