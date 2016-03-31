ap.Views.forgot_password = XView.extend
	events:
		'submit #reset-form': 'reset'

	initialize: ->
		@initRender()

	reset: (e) ->
		e.preventDefault()
		$t = $(e.currentTarget)
		post = $t.formToJson()
		ap.api 'post user/reset', post, (rsp) =>
			if rsp.not_existing?
				$('.login-error').show()
				setTimeout ->
					$('.login-error').hide()
				, 4000
			else
				$('#reset-shell', @el).hide()
				$('#reset-form-success', @el).show()
