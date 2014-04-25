###

	Mission Ops Page

###

ap.Views.hub = XView.extend
	
	initialize: ->
		@options.sidebar = 'hub'
		@initRender()
	rendered: ->

	initSelect2: ->

	whenFinished: ->
		$(window).unbind('hashchange')
		$('#counter-shell').show()
		$('.settings-link').unbind()
		$('html').removeClass('attended-before')