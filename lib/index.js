(function() {
  var plugin;

  plugin = {
    attach: function(options) {
      return this.Cash = (require('./Cash')).Cash;
    },
    Cach: require('./Cach').Cash
  };

  module.exports = plugin;

}).call(this);
