ap.Routes.logout = ->
	@stop
	ap.logout()
	ap.navigate 'login'
