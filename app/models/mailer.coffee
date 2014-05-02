_ = require('underscore')
Q = require('q')
request = require('request')
YAML = require('yamljs')

mailer =
	send: (mail, subject, to, params = {}) ->
		dfr = Q.defer()
		email_options = 
			promotion_name: mail
			subject: '[WDS] '+subject
			recipient: 'nhajal@gmail.com'
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
		tk call
		request call, (err, code, rsp) ->
			dfr.resolve(rsp)
		return dfr.promise

module.exports = mailer