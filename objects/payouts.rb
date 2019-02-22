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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative 'pgsql'

# Payouts.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
# License:: MIT
class Payouts
  def initialize(pgsql, log: Log::NULL)
    @pgsql = pgsql
    @log = log
  end

  # Add a new one, which just happened.
  def add(login, id, amount, details)
    pid = @pgsql.exec(
      [
        'INSERT INTO payout (login, wallet, zents, details)',
        'VALUES ($1, $2, $3, $4)',
        'RETURNING id'
      ].join(' '),
      [login, id.to_s, amount.to_i, details]
    )[0]['id'].to_i
    @log.info("New payout ##{pid} registered by @#{login} for wallet #{id}, \
amount #{amount}, and details: \"#{details}\"")
    pid
  end

  # Still allowed to send a payout for this amount to this user?
  def allowed?(login, amount)
    daily = Zold::Amount.new(
      zents: @pgsql.exec(
        'SELECT SUM(zents) FROM payout WHERE login = $1 AND created > NOW() - INTERVAL \'24 HOURS\'',
        [login]
      )[0]['sum'].to_i
    )
    return false if daily + amount > Zold::Amount.new(zld: 32.0)
    weekly = Zold::Amount.new(
      zents: @pgsql.exec(
        'SELECT SUM(zents) FROM payout WHERE login = $1 AND created > NOW() - INTERVAL \'7 DAYS\'',
        [login]
      )[0]['sum'].to_i
    )
    return false if weekly + amount > Zold::Amount.new(zld: 256.0)
    monthly = Zold::Amount.new(
      zents: @pgsql.exec(
        'SELECT SUM(zents) FROM payout WHERE login = $1 AND created > NOW() - INTERVAL \'31 DAYS\'',
        [login]
      )[0]['sum'].to_i
    )
    return false if monthly + amount > Zold::Amount.new(zld: 2048.0)
    true
  end
end
