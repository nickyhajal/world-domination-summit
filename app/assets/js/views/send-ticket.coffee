ap.Views.send_ticket = XView.extend
	events:
		'submit #send-ticket-form': 'sendTicketEmail'

	initialize: ->
		@getTicket =>
			@initRender()
	getTicket: (cb) ->
		if ap.tbyh?[@options.hash]?
			@ticket = ap.tbyh?
			cb()
		else
			ap.api 'get ticket', {hash: @options.hash}, (rsp) =>
				@ticket = rsp.ticket
				@ticket.meta_data = JSON.parse(@ticket.meta_data)
				@claim_link = 'http://wds.fm/claim-ticket/'+@ticket.hash
				cb()
	rendered: ->
		$('.ticket-claim-link').val(@claim_link)
		$('input[name=sender_name]').val(@ticket.meta_data.source.name)

	sendTicketEmail: (e) ->
		e.preventDefault()
		e.stopPropagation()
		$f = $(e.currentTarget)
		btn = _.btn($('.button', $f), 'Sending...', 'Saved!')
		post = $f.formToJson()
		post.claim_link = @claim_link
		ap.api 'post ticket/send', post, (rsp) ->
			shell = $('#send-ticket-form').parent()
			$('#send-ticket-form').remove()
			shell.append('<div class="ticket-send-success">Great, this ticket was sent to '+post.first_name+'!</div>')
			btn.finish()


