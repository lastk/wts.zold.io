/**
 * Copyright (c) 2018-2019 Zerocracy, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the 'Software'), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

function wts_error(xhr) {
  $('#error').addClass('red').html(
    'ERROR: <strong>' + xhr.getResponseHeader('X-Zold-Error') + '</strong>. If the description of the ' +
    'error doesn\'t help, most likely this ' +
    'is our internal problem. Try to reload this page and start from scratch. ' +
    'If this doesn\'t help, please submit a ticket to our '+
    '<a href="https://github.com/zold-io/wts.zold.io">GitHub repository</a> or ' +
    'seek help in our <a href="https://t.me/zold_io">Telegram group</a>.'
  );
}

function wts_recalc() {
  $.ajax({
    dataType: 'json',
    url: '/rate.json?noredirect=1',
    success: function(json) {
      var rate = json.usd_rate;
      var btc = parseFloat($('#btc').val());
      var months = parseFloat($('#months').val());
      var zld = btc / json.effective_rate;
      $('#zld').text(Math.round(zld));
      var spend = zld * rate
      $('#spend').text(Math.round(spend));
      var back = spend * Math.pow(1.04, months) * 0.92;
      $('#back').text(Math.round(back));
      var $profit = $('#profit');
      $profit.text(Math.round(back - spend));
      if (back > spend) {
        $profit.removeClass('red').addClass('green');
      } else {
        $profit.addClass('red').removeClass('green');
      }
    },
    error: function(xhr) {
      wts_error(xhr);
      window.setTimeout(wts_recalc, 3000);
    }
  });
}

function wts_step5(token) {
  $('#step4').hide();
  $('#amount').text($('#btc').text());
  console.log('Requesting BTC address for user ' + token + '...');
  $.ajax({
    dataType: 'text',
    url: '/btc?noredirect=1',
    headers: { 'X-Zold-Wts': token },
    success: function(data, textStatus, request) {
      var address = request.getResponseHeader('X-Zold-BtcAddress');
      $('#step5').show();
      $('#step6').show();
      $('#address').text(address);
      $('#qr').attr('src', 'https://chart.googleapis.com/chart?chs=256x256&cht=qr&chl=bitcoin:' + address);
    },
    error: function(xhr) { wts_error(xhr); }
  });
}

function wts_step4(token) {
  console.log('Confirming keygap of ' + token + '...');
  $.ajax({
    dataType: 'text',
    url: '/confirmed?noredirect=1',
    headers: { 'X-Zold-Wts': token },
    success: function(text) {
      if (text == 'yes') {
        wts_step5(token);
      } else {
        $.ajax({
          dataType: 'text',
          url: '/keygap?noredirect=1',
          headers: { 'X-Zold-Wts': token },
          success: function(text) {
            var keygap = text;
            $('#step4').show();
            $('#keygap').text(keygap);
            $('#button').val('Confirm').off('click').on('click', function () {
              $.ajax({
                dataType: 'text',
                url: '/do-confirm?noredirect=1&keygap=' + keygap,
                headers: { 'X-Zold-Wts': token },
                success: function(text) {
                  wts_step5(token);
                },
                error: function(xhr) { wts_error(xhr); }
              });
            });
          },
          error: function(xhr) { wts_error(xhr); }
        });
      }
    }
  });
}

function wts_step3() {
  var phone = $('#phone').text();
  var code = $('#code').val();
  console.log('Confirming ' + phone + ' with ' + code + '...');
  $.ajax({
    dataType: 'text',
    url: '/mobile/token?noredirect=1&phone=' + phone + '&code=' + code,
    success: function(text) {
      $('#step3').hide();
      $('#step5').hide();
      $('#step4').show();
      wts_step4(text);
    },
    error: function(xhr) { wts_error(xhr); }
  });
}

function wts_step2() {
  var phone = $('#phone').val();
  console.log('Sending SMS to phone ' + phone + '...');
  $.ajax({
    dataType: 'text',
    url: '/mobile/send?noredirect=1&phone=' + phone,
    success: function(text) {
      $('#step3').show();
      $('#phone').replaceWith('<strong id="phone">' + $('#phone').val() + '</strong>');
      $('#step2-help').hide();
      $('#button').val('Confirm').off('click').on('click', wts_step3);
      $('#code').focus();
    },
    error: function(xhr) { wts_error(xhr); }
  });
}

function wts_step1() {
  $('#step2').show();
  $('#btc').replaceWith('<span id="btc">' + $('#btc').val() + '</span>');
  $('#months').replaceWith('<span id="months">' + $('#months').val() + '</span>');
  $('#button').val('Send').off('click').on('click', wts_step2);
  $('#phone').focus();
}

$(function() {
  wts_recalc();
  $('#button').on('click', wts_step1);
});

