ap.Views.race = XView.extend
	initialize: ->
		@options.out = _.template @options.out, ap.me.attributes
		@initRender()

	rendered: ->

