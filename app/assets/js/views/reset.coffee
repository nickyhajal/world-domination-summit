ap.Views.reset_password = XView.extend
	events: 
		'submit #reset-form': 'reset'
	
	initialize: ->
		@initRender()

	reset: (e) ->
		e.preventDefault()
		$t = $(e.currentTarget)
		post = $t.formToJson()
		post.hash = @options.hash
		ap.api 'post user/reset', post, (rsp) =>
			$('#reset-shell', @el).hide()
			$('#reset-form-success', @el).show()
