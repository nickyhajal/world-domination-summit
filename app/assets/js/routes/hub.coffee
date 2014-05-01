ap.Routes.hub= ->
	if ap.me.get('intro') < 8
		ap.navigate 'welcome'
	else
		$('html').removeClass('hide-counter')
		ap.goTo('hub')

