ap.Views.modal_attendee_bio = XView.extend
	timo: 0
	uByHash: {}
	events:
		'submit .attendee-bio-form': 'submit'
		'click #attendee-selection-results tr': 'row_click'
	initialize: ->
		@options.out = _.t('parts_modal-attendee-bio', {})
		@initRender()

	rendered: ->
		$('.attendee-bio-textarea').val(ap.currBio)
	appeared: ->
		$('.attendee-bio-textarea').val(ap.currBio)

	submit: (e) ->
		e.stopPropagation()
		e.preventDefault()
		$t = $(e.currentTarget)
		post = $t.formToJson()
		ap.bioCb(post.bio)
