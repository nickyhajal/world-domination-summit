ap.Routes.logout = ->
	ap.nav 'login'
	ap.api 'post logout'
	localStorage.clear()
	@stop
