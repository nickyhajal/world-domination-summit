ap.Views.attendees = XView.extend
	initialize: ->
		_.whenReady 'assets', =>
			tk 'nice'
			@initRender()
	rendered: ->

