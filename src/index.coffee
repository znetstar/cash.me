plugin = 
	attach: (options) ->
		@Cash = require('./Cash')
	Cash: require('./Cash')
module.exports = plugin