(function() {
  var Cash, async, default_memory_store, request;

  request = require('request');

  default_memory_store = require('cookie-mem');

  async = require('async');

  Cash = (function() {
    function Cash(cookie_store, cash_web_session) {
      this.cookie_store = cookie_store;
      this.cash_web_session = cash_web_session;
      if (!this.cookie_store) {
        this.cookie_store = new default_memory_store();
        this.jar = request.jar(this.cookie_store);
      }
      this.request = request.defaults({
        jar: this.jar
      });
      this.jar.setCookie(request.cookie('cash_web_session=' + this.cash_web_session));
    }

    Cash.prototype.account_model = function(callback) {
      return async.auto({
        csrf: this.csrf,
        model: (function(_this) {
          return function(cb, ctx) {
            return request({
              url: 'https://cash.me/account/model'
            }, function(error, res, body) {
              var data, e, error1;
              try {
                data = JSON.parse(body);
                return callback(null, data);
              } catch (error1) {
                e = error1;
                return callback(e);
              }
            });
          };
        })(this)
      });
    };

    Cash.prototype.csrf = function(callback) {
      return this.request({
        url: 'https://cash.me/account/activity'
      }, (function(_this) {
        return function(error, res, body) {
          var $, csrf, e, error1, script;
          try {
            $ = (require('cheerio')).load(body);
            script = $('script:contains("csrf")').first().html();
            csrf = $('script:contains("csrf")').text().split("= '").pop().split("'").shift();
            return callback(null, csrf);
          } catch (error1) {
            e = error1;
            return callback(e);
          }
        };
      })(this));
    };

    return Cash;

  })();

  module.exports = Cash;

}).call(this);
