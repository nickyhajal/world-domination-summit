ap.Views.AcademyList = XView.extend
	initialize: ->
		@render()
	render: ->
		html = ''
		lastDay = ''
		ap.api 'get academies', {}, (rsp) =>
			for a in rsp.events
				day = moment(a.start).format('dddd, MMMM Do')
				if day != lastDay
					lastDay = day
					html += '<h3>'+day+'</h3>'
				html += _.t('parts_academy-row', a)
			$(@el).html html
