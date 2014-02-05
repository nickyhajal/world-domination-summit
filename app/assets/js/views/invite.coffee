ap.Views.invite = XView.extend
	events:
		'submit #invite-form': 'sendInvite'
	rendered: ->
		duo = @options.duo
		$('.new-invitee-name').html(duo.get('invitee'))
		$('#new-duo-invite-url').val('https://letsduo.com/join-duo/'+duo.get('hash'))
	sendInvite: (e) ->
		form = $(e.currentTarget).formToJson()
		form.duoid = @options.duo.get('duoid')
		ap.api 'post invite', form, (rsp) ->
			$('#duo-invite-email-shell').hide()
			$('#invite-success').show()
		return false