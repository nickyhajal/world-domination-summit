jQuery.fn.scan 
	add: 
		id: 'box-select'
		fnc: ->
			$t = $(this)
			opts = $('option', $t)
			$box = $('<div>').attr('class', 'box-select-shell')
			$t.before($box)
			opts.each ->
				$o = $(this)
				selected = ''
				if $o.is(':selected')
					selected = ' box-select-option-selected'
				newopt = $('<a>')
					.attr('href', '#')
					.attr('class', 'box-select-option'+selected)
					.attr('data-value', $o.attr('value'))
					.html($o.html())
				$box.append(newopt)
			$t.css('position', 'absolute').css('left', '-9999px')

			$t.change (e) ->
					val = $t.val()
					$('a', $box).removeClass('box-select-option-selected')
					$('a[data-value="'+val+'"]', $box).addClass('box-select-option-selected')
			$box
				.on 'click', 'a', (e) ->
					$a = $(this)
					$('a', $box).removeClass('box-select-option-selected')
					$a.addClass('box-select-option-selected')
					$t.val($a.data('value')).change()
					e.preventDefault()

