ap.Views.propose_a_meetup = XView.extend
	controlsTimo: 0
	events:
		'submit #meetup-proposal-form': 'postMeetup'

	initialize: ->
		@render('append')

	rendered: ->

	postMeetup: (e) ->
		e.preventDefault()
		post = $(e.currentTarget).formToJson()
		btn = _.btn($('input[type="submit"]', $(@el)), 'Submitting...', 'Submitted!')
		ap.api 'post event', post, ->
			btn.finish()
			$('#page_content').html "
				<h2 id='header-title'>Success!</h2> 
				<h3>Your Meetup Was Submitted!</h3>
				We'll be in touch with you shortly so keep an eye on your inbox over the next week!
			"
			$.scrollTo(0)

