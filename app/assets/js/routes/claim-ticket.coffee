ap.Routes.claim_ticket = (hash) ->
	if hash
		ap.goTo('claim-ticket', {hash: hash})
	else
		ap.navigate('be-there')

