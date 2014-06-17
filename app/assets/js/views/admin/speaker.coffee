ap.Views.admin_speaker = XView.extend
	ticketTimo: 0
	events: 
		'submit #admin-speaker-update': 'speaker_submit'
	initialize: ->
		speaker = false
		for type,spks of ap.speakers
			for spk in spks
				if +spk.speaker_id is +@options.extra
					speaker = spk
		@options.out = _.template @options.out, speaker
		@speaker = speaker
		@initRender()

	rendered: ->
		$('select[name="type"]').val(@speaker.type)

	speaker_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		btn = _.btn($('.button', el), 'Saving...', 'Saved!')
		form = el.formToJson()
		form.admin = 1
		ap.api 'put speaker', form, (rsp) ->
			ap.speakers = rsp.speakers
			btn.finish()
