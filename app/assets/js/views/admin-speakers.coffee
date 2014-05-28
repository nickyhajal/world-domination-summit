ap.Views.admin_speakers = XView.extend
	timo: 0
	events: 
		'keyup .speaker-search': 'search_keyup'
		'click #speaker-results tr': 'row_click'

	initialize: ->
		@initRender()
		@speakers = []
		for type,spks of ap.speakers
			for spk in spks
				spk.type = type
				@speakers.push spk
		@speakers.sort (a,b) ->
			if a.year > b.year
				return -1
			if a.year < b.year
				return 1
			return 0

	rendered: ->
		if ap.lastSpeakerSearch? and ap.lastSpeakerSearch
			$('.speaker-search').val(ap.lastSpeakerSearch)
			@search(ap.lastSpeakerSearch)
			ap.lastSpeakerSearch = false
		else
			@search('')

	search_keyup: (e) ->
		val = $(e.currentTarget).val()
		@search(val)

	search: (val) ->
		clearTimeout(@timo)
		@timo = setTimeout =>
			if val.length > 0
				added = []
				results = []
				vals = val.split(' ')
				for val in vals
					check = 'display_name'
					if val[0] is '2'
						check = 'year'
					for spk in @speakers
						if spk[check].toLowerCase().indexOf(val.toLowerCase()) > -1
							if added.indexOf(spk.speaker_id) < 0
								added.push spk.speaker_id
								results.push spk
			else
				results = @speakers

			html = ''
			for spk in results
				html += @renderRow(spk)
			$('#speaker-results').html(html)
			$('#speaker-start').hide()
			$('#speaker-results-shell').show()
		, 500
	renderRow: (atn) ->
		html = '<tr data-speaker="'+atn.speaker_id+'">
			<td>
				<div class="speaker-avatar" style="background:url('+atn.display_avatar+')"></div>
				<span>'+atn.display_name+'</span>
			</td>
			<td>'+atn.year+'</td>'
		return html
	row_click: (e) ->
		ap.lastSpeakerSearch = $('.speaker-search').val()
		speaker_id = $(e.currentTarget).data('speaker')
		ap.navigate('admin/speaker/'+speaker_id)

	whenFinished: ->
		ap.lastSpeakerSearch = $('.manifest-search').val()

