ap.Views.SpeakerList = XView.extend
	initialize: ->
		tk 'render'
		@render()
	render: ->
		html = ''
		tk 'what'
		for speaker in ap.speakers[@options.type]
			html += _.t('parts_speaker-description', speaker)
		$(@el).html html
	