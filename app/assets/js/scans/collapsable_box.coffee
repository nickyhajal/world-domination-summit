###

	Toggle following

###

jQuery.fn.scan 
	add: 
		id: 'collapsable-box'
		fnc: ->
			$t = $(this)
			h4 = $('h4', $t).first()

			h4.click (e) ->
				e.preventDefault()
				if $t.hasClass('collapsable-box-closed')
					$t.removeClass('collapsable-box-closed')
				else
					$t.addClass('collapsable-box-closed')



