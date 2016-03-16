ap.Routes.hub= ->
	if ap.me.get('intro') < 9
		ap.navigate 'welcome'
	else
		ap.loading false
		$('html').removeClass('hide-counter')
		ap.goTo('hub')

