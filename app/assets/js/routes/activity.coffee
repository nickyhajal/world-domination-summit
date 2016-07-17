ap.Routes.activity = (activity) ->
	tk activity
	if activity
		ap.goTo('activity', {activity: activity})
	else
		ap.navigate('activity')

