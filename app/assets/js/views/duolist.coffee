ap.Views.Duolist = XView.extend
	initialize: ->
		@out = ap.templates['parts_duolist']
		@initRender()

	rendered: ->
		@options.duo_els = {}
		for duo in @options.duos
			duo_el = new ap.Views.Duorow
				el: @el
				render: 'append'
				duo: new ap.Duo(duo)
			@options.duo_els[duo.duoid] = duo

ap.Views.Duorow = XView.extend
	initialize: ->
		@prepare()
		@initRender()
	prepare: ->
		tpl = ap.templates['parts_duorow']
		filler = @options.duo.attributes
		filler.with_name = filler.with_user.first_name
		tpl = _.template tpl, filler
		@out = tpl
