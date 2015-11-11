ap.Routes.mission_accomplished = (hash) ->
	if hash
		ap.goTo('mission-accomplished', {hash: hash})
	else
		ap.navigate('be-there')

