ap.Modals = {}
ap.Modals.opts =
	esc: true
	body_scroll: true

ap.Modals.init = ->
	$('body')
	.on('keyup', ap.Modals.key)
	.on('click', '.modal-close', ap.Modals.close)
	$('#modals').scan()

ap.Modals.open = (modal, opts = {}) ->
	ap.Modals.close()
	xview = false
	m = $('#modal-'+modal)
	if m.data('lock_scroll')?
		$('body').addClass('no-scroll')
		if ap.isPhone
			$('.contentwrap').css('display', 'none')
		ap.Modals.opts.body_scroll = false
	if m.data('no_esc')?
		ap.Modals.opts.esc = false
	m.show()
	if $('.xview', m).length
		$('.xview', m).scan(opts)
		xview = $('.xview', m).data('xview')
		if xview.appeared?
			xview.appeared()
	else
		m.scan()
	m.show().css('opacity', '1')
	$('#modal-'+modal+' .modal-content').center({offsetY: '-25%', horizontal: true, vertical: true})
	if xview
		return xview

ap.Modals.close = (modal = false) ->
	if modal and typeof modal is 'string'
		$('.modal-remove', '#modal-'+modal).remove()
		$('#modal-'+modal).hide().css('opacity', '0')
	else
		$('.modal-remove').remove()
		$('.modal').each ->
			$t = $(this)
			if $t.is(':visible')
				xview = $('.xview', $t).data('xview')
				if xview && xview.whenFinished?
					xview.whenFinished()
			$t.hide().css('opacity', '0')
	# ap.Notify.closeAll()
	unless ap.Modals.opts.body_scroll
		$('body').removeClass('no-scroll')
		ap.Modals.opts.body_scroll = true
		if ap.isPhone
			$('.contentwrap').css('display', 'block')
	unless ap.Modals.opts.esc
		$('body').removeClass('no-scroll')
		ap.Modals.opts.esc = true
	return false

ap.Modals.key = (e) ->
	e.preventDefault()
	if e.keyCode is 27 and ap.Modals.opts.esc
		ap.Modals.close()

ap.Modals.click = (e) ->
	e.preventDefault()
	ap.Modals.close()
