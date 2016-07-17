ap.Routes.spark_session = (spark_session) ->
	if spark_session
		ap.goTo('spark-session', {spark_session: spark_session})
	else
		ap.navigate('spark-sessions')

