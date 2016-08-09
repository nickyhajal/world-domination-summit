ap.Views.admin_event_export = XView.extend
	initialize: ->
		ap.api 'get admin/events', {types: ['academy', 'meetup', 'activity', 'spark_session']}, (rsp) =>
			ehtml = ''
			evs = _.sortBy(rsp.events, (ev) -> [ev.type, ev.what])
			for ev in evs
				type = _.titleize(ev.type.replace('_', ' '))
				ehtml += '<option value="'+ev.event_id+'">'+type+': '+_.truncate(ev.what, 45)+'</option>'
			@out = _.template @options.out, {events: ehtml}
			@initRender()