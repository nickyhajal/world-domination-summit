ap.Modals = {}

ap.Modals.init = ->
	$('body')
	.on('keyup', ap.Modals.key)
	.on('click', '.modal-close', ap.Modals.close)

ap.Modals.open = (modal) ->
	if not ap.isMobile
		ap.Modals.close()
		$('#modal-'+modal).show()

ap.Modals.close = (modal = false) ->
	if modal and typeof modal is 'string'
		$('.modal-remove', '#modal-'+modal).remove()
		$('#modal-'+modal).hide()
		$('#modal-'+modal).hide()
	else 
		$('.modal-remove').remove()
		$('.modal').hide()
	return false

ap.Modals.key = (e) ->
	e.preventDefault()
	if e.keyCode is 27
		ap.Modals.close()

ap.Modals.click = (e) ->
	e.preventDefault()
	ap.Modals.close()
