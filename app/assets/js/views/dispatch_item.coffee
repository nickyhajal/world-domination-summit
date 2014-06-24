ap.Views.dispatch = XView.extend
	initialize: ->
		@options.out = _.template @options.out, {feed_id: @options.feed_id}
		@initRender()
