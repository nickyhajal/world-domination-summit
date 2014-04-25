ap.Views.interest = XView.extend
	
	initialize: ->
		@options.out = _.t @options.out, {interest: @options.interest}
		@initRender()
