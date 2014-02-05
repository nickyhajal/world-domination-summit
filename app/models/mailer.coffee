_ = require('underscore')
Q = require('q')
elasticemail = require('elasticemail');
client = elasticemail.createClient(process.mail)

module.exports = 
	send: (mail, subject, to, more_params = [], opts = false) ->
		tk mail
		dfr = Q.defer()
		merge = {}
		for i,p of more_params
			merge['merge_'+i] = p
		req =
			template: mail
			from: 'nicky@letsduo.com'
			from_name: 'Nicky Hajal'
			subject: '[LetsDuo] ' + subject	
			to: to
		req = _.defaults req, merge
		tk req
		client.mailer.send req, (err, rsp) =>
			dfr.resolve(err, rsp)
		return dfr.promise