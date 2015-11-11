ap.Routes.send_ticket = (hash) ->
	if hash
		ap.goTo('send-ticket', {hash: hash})
	else
		ap.navigate('be-there')

