ap.Routes.activity = (activity) ->
	if activity
		ap.goTo('activity', {activity: activity})
	else
		ap.navigate('activity')

