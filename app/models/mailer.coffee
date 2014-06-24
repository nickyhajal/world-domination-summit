_ = require('underscore')
Q = require('q')
request = require('request')
YAML = require('yamljs')

mailer =
	send: (promo, subject, to, params = {}) ->
		dfr = Q.defer()
		use_to = 'nhajal@gmail.com'
		if process.env.NODE_ENV is 'production'
			use_to = to

		email_options = 
			promotion_name: 'WDS_'+promo
			subject: '[WDS] '+subject
			recipient: use_to
			from: 'Chris Guillebeau <chris.guillebeau@gmail.com>'
			
		@request('mailer', email_options, params)
		.then (transaction_id) ->
			tk 'MAILED: '+transaction_id
			dfr.resolve(transaction_id)
		return dfr.promise
	request: (path, params, body = false) ->
		dfr = Q.defer()
		defs = 
			username: process.env.MM_USER
			api_key: process.env.MM_PW
		params = _.defaults params, defs
		call = 
			url: 'https://api.madmimi.com/'+path
			method: 'post'
			form: params
		if body
			call.form.body = "--- \n"+YAML.stringify(body, 4)
		request call, (err, code, rsp) ->
			dfr.resolve(rsp)
		return dfr.promise

module.exports = mailer