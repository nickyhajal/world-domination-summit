ap.Routes.hub= ->
	if ap.me.get('intro') < ap.WELCOME_STEPS
		ap.navigate 'welcome'
	else
		ap.loading false
		$('html').removeClass('hide-counter')
		ap.goTo('hub')

