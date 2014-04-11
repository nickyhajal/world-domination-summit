ap.Views.SpeakerList = XView.extend
	initialize: ->
		@render()
	render: ->
		html = ''
		for speaker in ap.speakers[@options.type]
			html += _.t('parts_speaker-description', speaker)
		$(@el).html html
	