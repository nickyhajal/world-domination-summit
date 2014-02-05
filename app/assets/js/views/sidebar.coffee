ap.Views.Sidebar = XView.extend
	events:
		'click .button': 'togglePage'
	initialize: ->
		type = this.options.type
		buttons = []
		if type is 'events'
			ap.Events.fetch()
			ap.Events.forEach (event) ->
		@render()
	render: ->
	togglePage: ->
