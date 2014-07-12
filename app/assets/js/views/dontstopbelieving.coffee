ap.Views.dontstopbelieving = XView.extend
	initialize: ->
		@initRender()
	rendered: ->
		ap.api 'post user/achieved', {slug: 'complete-the-unconventional-treasure-hunt'}
