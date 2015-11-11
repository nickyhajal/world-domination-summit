ap.Views.mission_accomplished = XView.extend
	events:
		'click .claim-ticket': 'claimTicket'
		'click .send-ticket': 'sendTicket'

	initialize: ->
		@getTicket =>
			@initTemplateOptions()
			@initRender()

	claimTicket: (e) ->
		ap.navigate 'claim-ticket/'+@options.hash

	sendTicket: (e) ->
		ap.navigate 'send-ticket/'+@options.hash

	getTicket: (cb) ->
		if ap.tbyh?[@options.hash]?
			@ticket = ap.tbyh?
			cb()
		else
			ap.tbyh = {} if not ap.tbyh?
			ap.api 'get ticket', {hash: @options.hash}, (rsp) =>
				@ticket = rsp.ticket
				@ticket.meta_data = JSON.parse(@ticket.meta_data)
				ap.tbyh[@options.hash] = @ticket
				@claim_link = 'http://wds.fm/claim-ticket/'+@ticket.hash
				cb()

	rendered: ->

		tk 'RENDERED ACC'

