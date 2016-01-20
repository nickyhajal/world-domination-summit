ap.Views.admin_add_speaker = XView.extend
	events:
		'submit #admin-add-speaker': 'addUser_submit'
	initialize: ->
		@initRender()
	addUser_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		post = el.formToJson()
		post['attending'+ap.yr] = '1'
		btn = _.btn($('.button', el), 'Adding...', 'Added!')
		ap.api 'post speaker', post, (rsp) ->
			ap.speakers = rsp.speakers
			btn.finish()
			setTimeout ->
				ap.lastSpeakerSearch = post.display_name
				ap.navigate('admin/speakers')
			, 1200