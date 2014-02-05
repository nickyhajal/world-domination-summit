ap.Views.home = XView.extend
	initialize: ->
		if ap.me
			if ap.me.get('duos')?.length
				@initPersonalizedHome()
				@initRender()
			else
				ap.navigate 'create'
		else
			@initRender()
	rendered: ->
		if ap.me
			duolist = new ap.Views.Duolist
				el: $('.duolist-shell', @el)
				render: 'replace'
				duos: ap.me.get('duos')
	initPersonalizedHome: ->
		out = ap.templates['pages_home_loggedin'] + '<div class="clear"></div>'
		greeting = @makeGreeting()
		this.options.out = _.template out, 
			greeting: greeting
	makeGreeting: ->
		return 'Sup, ' + ap.me.get('first_name') + '?'
