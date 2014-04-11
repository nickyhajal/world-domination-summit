jQuery.fn.scan 
	add: 
		id: 'speaker_list'
		fnc: ->
			$el = $(this)
			type = $el.data('speaker-type')
			new ap.Views.SpeakerList({el: $el, type: type})