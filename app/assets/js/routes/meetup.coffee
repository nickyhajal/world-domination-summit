ap.Routes.meetup = (meetup) ->
	tk 'HEY'
	if meetup
		ap.goTo('meetup', {meetup: meetup})
	else
		ap.navigate('meetups')

