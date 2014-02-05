ap.Views.create = XView.extend
	events:
		'submit #create-form': 'createDuo'
	rendered: ->
	createDuo: (e)->
		form = $(e.currentTarget).formToJson()
		duo = new ap.Duo form
		duo.save {},
			success: (mi, rsp) ->
				ap.me = new ap.User rsp.me
				duo = new ap.Duo rsp.duo
				ap.Duos.add(duo)
				ap.navigate('invite/' + duo.get('hash'))
			error: (me, rsp) ->
				if rsp.responseText.length
					rsp = JSON.parse(rsp.responseText)
					if rsp.err
						for err in rsp.errors
							ap.Notify.now
								msg: err
								clss: 'notice'
				else
					ap.Notify.now
						msg: 'Hmm, there was an error. Do you mind trying again?'
						clss: 'notice'
		return false
