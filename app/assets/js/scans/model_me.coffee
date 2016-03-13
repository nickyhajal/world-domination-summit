###

	This is kind of an experiment that binds any element
	with the class 'model-me' to the ap.me Model.

	Anytime that element is changed, the model automatically
	responds and, optionally, can be saved.

###

jQuery.fn.scan
	add:
		id: 'model-me'
		fnc: ->
			$t = $(this)
			name = $t.attr('name')

			# If value is already set, init the element with that value
			if (''+ap.me?.get(name)).length
				$t.val(ap.me.get(name)).change()

			# If value isn't set, init me with the default value
			else if $t.val()? and $t.val().length
				ap.me.set(name, $t.val())

			save = $t.data('data-save')? and $t.data('data-save')

			changeFnc = ->
				val = $t.val()
				ap.me.set(name, val)
				tk name
				tk 'change:'+name
				ap.me.trigger('change:'+name)
				XHook.trigger('model-me-'+name+'-changed', val)
				if save
					ap.me.save()
			$t.change changeFnc
			$t.keyup changeFnc


