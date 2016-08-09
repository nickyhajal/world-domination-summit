ap.Views.admin_event_export = XView.extend
	initialize: ->
		ap.api 'get admin/events', {types: ['academy', 'meetup', 'activity', 'spark_session']}, (rsp) =>
			ehtml = ''
			evs = _.sortBy(rsp.events, (ev) -> [ev.type, ev.start])
			for ev in evs
				start = moment(ev.start).format('MMM Do')
				type = _.titleize(ev.type.replace('_', ' '))
				ehtml += '<option value="'+ev.event_id+'">'+type+': ('+start+') '+_.truncate(ev.what, 45)+'</option>'
			@out = _.template @options.out, {events: ehtml}
			@initRender()