request = require 'request'
default_memory_store = require 'cookie-mem'
async = require 'async'
_  = require 'lodash'
EventEmitter = (require 'eventemitter2').EventEmitter2
validator = require 'validator'
generateNewPaymentToken = () -> return ((t) -> Math.round(Math.pow(36, t + 1) - Math.random() * Math.pow(36, t)).toString(36).slice(1))(20)

class Cash extends EventEmitter 
	constructor: (@cash_web_session, @cookie_store) ->
		@cookie_store = @cookie_store or new default_memory_store()
		@jar = (request.jar(@cookie_store))
		
		@request = request.defaults({ jar: @jar })

		@jar.setCookie(request.cookie('cash_web_session='+@cash_web_session), 'https://cash.me')
		@jar.setCookie(request.cookie('__nsid='+'1758fee3-3cb7-42b8-b886-3600425da107'), 'https://cash.me')

	headers: (csrf = @_csrf, referer = 'https://cash.me/account/activity') =>
		'Referer': referer
		'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36'
		'X-BT-ID': '0.0'
		'X-CSRF-Token': (csrf or @_csrf)
		'X-JS-ID': 'e2dc0a71bf241a5caf5c6843049fa27e'
		'X-Requested-With': 'XMLHttpRequest'
		'Origin': 'https://cash.me'
		'Host':'cash.me'
		'content-type': 'application/json'
		'__nsid': '1758fee3-3cb7-42b8-b886-3600425da107'

	recipient: (person) ->
		recp = {}
		field = (validator.isEmail(person) and 'email') or
			(validator.isMobilePhone(person, 'en-US') and 'phone_number') or
			(person.indexOf('$') is 0) and 'cashtag' 
		if !field
			return null

		recp[field] = person
		return recp

	confirm: (payment_id, passcode, callback, options = {}) =>
		options.passcode = (passcode or options.passcode or null)
		options.action = options.action or null

		@csrf (error, csrf) =>
			request
				url: 'https://cash.me/v1/me/cash/payments/'+payment_id+'/confirm'
				jar: @jar
				headers: @headers()
				method: 'POST'
				json: options 
			,(error, res, payment) =>
				try
					callback null, payment
				catch e
					callback(e)

	payment: (action, recipient, amount, callback, options = {}) => 
		payment_options = 
			recipient: @recipient(recipient or options.recipient)
			amount_money:
				amount: ((amount or options.amount) * 100).toString()
				currency_code: options.currency_code or 'USD'
			card_token: options.card_token or null
			note: options.note or null
			payment_id: (options.payment_id or generateNewPaymentToken())
			action: ((action or options.action) or null).toUpperCase()
			state: options.state or null
			cancellation_reason: options.cancellation_reason or null
			created_at: options.created_at or null
			captured_at: options.captured_at or null
			paid_out_at: options.paid_out_at or null
			canceled_at: options.canceled_at or null 
			refunded_at: options.refunded_at or null
			updated_at: options.updated_at or null
			reached_sender_at: options.reached_sender_at or null
			reached_recipient_at: options.reached_recipient_at or null
			estimated_payout_received_at: options.estimated_payout_received_at or null
			role: options.role or null
			related_payments: options.related_payments or []

		options = _.extend(options, payment_options)
		@csrf (error, csrf) =>
			request
				url: 'https://cash.me/v1/me/cash/payments'
				jar: @jar
				headers: @headers()
				method: 'POST'
				json: options 
			,(error, res, payment) =>
				try
					if payment.blockers
						@emit 'passcode', payment.blockers.confirm, (passcode) =>
							@confirm(payment.payment_id, passcode, callback)
					else
						callback null, payment
				catch e
					callback(e)
	payments: (callback, options = {}) =>
		options = _.extend(options, { limit: 50, order: "DESC", show_completed: true, show_in_flight: false, show_drafts: false })
		@csrf (error, csrf) =>
			request
				url: 'https://cash.me/v1/me/cash/web-payments'
				jar: @jar
				headers: @headers()
				method: 'POST'
				json: options 
			,(error, res, body) =>
				try
					callback null, body
				catch e
					callback(e)
					
	account: (callback) =>
		@csrf (error, csrf) =>
			request
				url: 'https://cash.me/account/model'
				jar: @jar
				headers: @headers()
			,(error, res, body) =>
				try
					data = JSON.parse(body)

					callback null, data
				catch e
					callback(e)
					

	csrf: (callback) =>
		@request {
			url: 'https://cash.me/account/activity'
			headers:
				'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36'
			jar: @jar
		}, (error, res, body) =>
			try
				$ = (require 'cheerio').load(body)

				script = $('script:contains("csrf")').first().html()
		
				csrf = $('script:contains("csrf")').text().split("= '").pop().split("'").shift()
				
				if csrf 
					@_csrf = csrf
					callback null, csrf
				else 
					callback(new Error('Invalid Session'))
			catch e
				callback(e)


module.exports = Cash