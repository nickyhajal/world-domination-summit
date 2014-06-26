ap.Routes.meetup = (meetup) ->
	if meetup
		ap.goTo('meetup', {meetup: meetup})
	else
		ap.navigate('meetups')

