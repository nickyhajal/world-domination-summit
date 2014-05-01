ap.Views.SpeakerList = XView.extend
	initialize: ->
		tk 'render'
		@render()
	render: ->
		html = ''
		for speaker in ap.speakers[@options.type]
			speaker.speaker_url = '/speakers/'+_.slugify(speaker.display_name)
			html += _.t('parts_speaker-description', speaker)
		$(@el).html html
	