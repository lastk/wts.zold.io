<img src="http://www.zold.io/logo.svg" width="92px" height="92px"/>

[![Donate via Zerocracy](https://www.0crat.com/contrib-badge/CB28FH2NR.svg)](https://www.0crat.com/contrib/CB28FH2NR)

[![EO principles respected here](http://www.elegantobjects.org/badge.svg)](http://www.elegantobjects.org)
[![Managed by Zerocracy](https://www.0crat.com/badge/CAZPZR9FS.svg)](https://www.0crat.com/p/CAZPZR9FS)
[![DevOps By Rultor.com](http://www.rultor.com/b/zold-io/out)](http://www.rultor.com/p/zold-io/out)
[![We recommend RubyMine](http://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/zold-io/wts.zold.io.svg)](https://travis-ci.org/zold-io/wts.zold.io)
[![PDD status](http://www.0pdd.com/svg?name=zold-io/wts.zold.io)](http://www.0pdd.com/p?name=zold-io/wts.zold.io)
[![Test Coverage](https://img.shields.io/codecov/c/github/zold-io/wts.zold.io.svg)](https://codecov.io/github/zold-io/wts.zold.io?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/25b798dc13147f13bb59/maintainability)](https://codeclimate.com/github/zold-io/wts.zold.io/maintainability)

Here is the [White Paper](https://papers.zold.io//wp.pdf).

Join our [Telegram group](https://t.me/zold_io) to discuss it all live.

The license is [MIT](https://github.com/zold-io/wts.zold.io/blob/master/LICENSE.txt).

There is Ruby SDK for the WTS platform: [zold-io/zold-ruby-sdk](https://github.com/zold-io/zold-ruby-sdk).

## API

First, you should get your API token from [this page](https://wts.zold.io/api).

Then, say, you want to send some zolds to `@yegor256`, your token is
`user-111222333444`, and your
[keygap](https://blog.zold.io/2018/07/18/keygap.html) is `84Hjsow9`.
You do the following HTTP request:

```
POST /do-pay HTTP/1.1
Content-Type: application/x-www-form-urlencoded
Host: wts.zold.io
X-Zold-Wts: user-111222333444
bnf=yegor256&amount=19.99&details=For+the+pizza&keygap=84Hjsow9
```

You can do the same from the command line, using
[curl](https://en.wikipedia.org/wiki/CURL):

```bash
curl https://wts.zold.io/do-pay \
  --request POST \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --header "X-Zold-Wts: user-111222333444" \
  --data "bnf=yegor256" \
  --data "amount=19.99" \
  --data "details=For+the+pizza" \
  --data "keygap=84Hjsow9"
```

You will get `302`
response no matter what. The `X-Zold-Job` header of the response will
contain the ID of the job, which is executed on the server. Later,
you can check the status of the job via the `/job` entry point, using its ID.

There are more entry points:

  * `GET /id`: returns your wallet ID.

  * `GET /balance`: returns the current balance of the wallet in Zents (1 ZLD is 2^32 Zents).
    If the wallet is absent on the server, there will be non-200 response code and maybe you need to call /pull.

  * `GET /pull`: asks the server to pull your wallet from the network.

  * `GET /find`: finds and returns all transactions in the wallet that match the criteria.
    You can specify the criteria in the query string. For example,
    to find all transactions that were sent from the wallet
    `012345670.+` with the details `Hello!`
    (they both are regular expressions):
    `/find?bnf=012345670.%2B&details=Hello!`.
    You can match by all transaction fields (see the [White Paper](https://papers.zold.io/wp.pdf)).

  * `GET /job`: checks the status of the jobs, expecting `id` as a query argument.
    Returns `200` and plain text `OK` if the job is completed.
    Returns `200` and plain text `Running` if the job is still in progress.
    Returns `404` if there is no such job.
    Returns `200` and a full stack trace as plain text if the job is finished with an exception.

  * `GET /id_rsa`: returns private RSA key of the user, expecting the keygap
    as an argument.

  * `GET /keygap`: returns the keygap of the user,
    if it's still not confirmed (as plain text).

  * `GET /do-confirm`: removes the keygap from the database and returns `302`.

## Callback API

If you want to integrate Zold into your website or mobile app, where your
customers are sending payments to you, you may try our callback API. First, you
send a `GET` request to `/wait-for` and specify:

  * `wallet`: the ID of the wallet you expect payments to
  * `prefix`: the prefix you expect them to arrive to (get it at `/invoice.json` first)
  * `regexp`: the regular expression to match payment details, e.g. `/pizza$/` (the text has to end with `pizza`)
  * `uri`: the URI where the callback should arrive once we see the payment

If your callback is registered, you will receive `200` response of time `text/plain`
with the ID of the callback in the body.

Once the payment arrives, your URI will receive a `GET` request from us
with the following query arguments:

  * `callback`: the ID of the callback
  * `login`: the user name of the owner of this callback
  * `regexp`: the regular expression just matched
  * `wallet`: the wallet ID
  * `id`: the transaction ID
  * `prefix`: the prefix matched
  * `source`: the ID of the payer
  * `amount`: the amount in zents
  * `details`: the details

Your callback has to return `200` and `OK` as a text. Unless it happens,
our server will send you another `GET` request in 10 minutes and will
keep doing that for 4 hours.

If your callback is never matched, it will be removed from the system
in 24 hours.

You may register up to 8 callbacks in one account.

## Mobile API

If you want to create a mobile client, you may use our mobile API with two
access points:

  * `GET /mobile/send?phone=+15551234567`:
    returns `200` if the SMS has been sent to the user with the authentication code.

  * `GET /mobile/token?phone=+15551234567&code=6666`:
    returns API access token. The `code` is the code from the SMS.

Then, when you have the API token, you can manage the account of the user.

## How to Contribute

First, install
[Java 8+](https://java.com/en/download/),
[Maven 3.2+](https://maven.apache.org/),
[Ruby 2.3+](https://www.ruby-lang.org/en/documentation/installation/),
[Rubygems](https://rubygems.org/pages/download),
and
[Bundler](https://bundler.io/).
Then:

```bash
$ bundle update
$ rake
```

The build has to be clean. If it's not, [submit an issue](https://github.com/zold-io/out/issues).

Then, make your changes, make sure the build is still clean,
and [submit a pull request](https://www.yegor256.com/2014/04/15/github-guidelines.html).

In order to run a single test:

```bash
$ rake run
```

Then, in another terminal:

```bash
$ ruby test/test_item.rb -n test_create_and_read
```
