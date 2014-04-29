ap.Modals = {}

ap.Modals.init = ->
	$('body')
	.on('keyup', ap.Modals.key)
	.on('click', '.modal-close', ap.Modals.click)


ap.Modals.open = (modal) ->
	ap.Modals.close()
	$('#modal-'+modal).show()

ap.Modals.close = (modal = false) ->
	if modal
		$('#modal-'+modal).hide()
	else 
		$('.modal').hide()

ap.Modals.key = (e) ->
	e.preventDefault()
	if e.keyCode is 27
		ap.Modals.close()

ap.Modals.click = (e) ->
	e.preventDefault()
	ap.Modals.close()
