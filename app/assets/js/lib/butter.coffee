window.butter = 
	init: ->
		butter.labelize()
		#butter.initButtons()
	labelize: ->
		$('.butter_labelize').each(->
			$(this).hide()
			name = $(this).attr('for')
			form = $(this).closest('form')
			$('input[name="'+name+'"]', form).labeledInput($(this).text())
			$('textarea[name="'+name+'"]', form).labeledInput($(this).text())
		)
	initButtons: ->
		d 'what'
		$('.ui-listview').each(->
			$t = $(this)
			li = $('li', $t)
				.addClass('ui-btn')
				.addClass('ui-li')
				.addClass('ui-btn-up-a')
			inner = li.html()
			newInner = $('<div/>')
				.addClass('ui-btn-inner').addClass('ui-li')
			newInner.append(
				$('<div/>').addClass('ui-btn-text').html(inner)
			)
			li.html(newInner)
		)

twoDigits = (d) ->
	if 0 <= d && d < 10
		return "0" + d.toString();
	if -10 < d && d < 0
		return "-0" + (-1*d).toString();
	return d.toString();
 
Date.prototype.toMysql = ->
    return this.getUTCFullYear() + "-" + twoDigits(1 + this.getUTCMonth()) + "-" + twoDigits(this.getUTCDate()) + " " + twoDigits(this.getHours()) + ":" + twoDigits(this.getUTCMinutes()) + ":" + twoDigits(this.getUTCSeconds());


Array.prototype.remove = (from, to) ->
  rest = this.slice((to || from) + 1 || this.length);
  this.length = if from < 0 then this.length + from else from;
  return this.push.apply(this, rest);


Number.prototype.ordinal = () ->
	if (this % 10 == 1 && this % 100 != 11) 
		str = 'st'
	else if (this % 10 == 2 && this % 100 != 12)
		str = 'nd'
	else if (this % 10 == 3 && this % 100 != 13) 
		str = 'rd' 
	else 
		str = 'th'
	return this + str;

(($)->
	$.fn.idData = (opts = {combine: false})->
		obj = $(this).attr('id')
		bits = obj.split('-')
		if bits.length > 2 and opts.combine
			_d.rRemove(bits, 0)
			return bits.join('-')
		else 
			return bits[1]
)(jQuery)

(($)->
	$.fn.labeledInput = (val, opts = {})->
		$(obj).unbind('focus').unbind('blur')
		opts.focusText ?= ''
		opts.init ?= false
		opts.activated ?= false
		opts.cleared ?= false
		if typeof opts.focusText is 'function'
			opts.focusText = opts.focusText()
		obj = this;
		if obj.val() is '' or opts.forceChange
			obj.val(val)
			obj.addClass('labeledInput-clear')
			if opts.init
				opts.init()

		# Define Set Focus Function
		obj.setFocusFnc = (fnc) ->
			if not obj.focusFnc?
				obj.focusFnc = ->
			existing = obj.focusFnc
			obj.focusFnc = ->
				fnc()
				existing()
		# Define Set Blur Function
		obj.setBlurFnc = (fnc) ->
			if not obj.blurFnc?
				obj.blurFnc = ->
			existing = obj.blurFnc
			obj.blurFnc = ->
				fnc()
				existing()

		# Set Focus Function
		obj.setFocusFnc(->
			if obj.val() is val
				obj.val(opts.focusText)
				obj.removeClass('labeledInput-clear')
				obj.addClass('labeledInput-active')
				if opts.activated
					opts.activated()
		)
		obj.focus(obj.focusFnc)

		# Set Blur Function
		obj.setBlurFnc(->
			if obj.val() is opts.focusText
				obj.val(val)
				obj.addClass('labeledInput-clear')
				obj.removeClass('labeledInput-active')
				if opts.cleared
					opts.cleared()
		)
		obj.blur(obj.blurFnc)
		return this
)(jQuery)


##
# Center an element in relation to another
# by default, it horizontally centers against <body> 
# also automatically recenters on resize by default
#
# @param object opts options as described below:
# @opt string parent 
# @opt bool horizontal 
# @opt bool vertical
# @opt int offsetX
# @opt int offsetY
# @opt bool onresize
#
(($)->
	$.fn.center = (opts = {})->
		opts = _.defaults(opts,
			parent: 'body'
			horizontal: true
			offsetX: 0
			vertical: false
			offsetY: 0
			onresize: true
		)
		$p = $(opts.parent)
		$t = $(this)

		if opts.horizontal
			p_width = $p.outerWidth()
			t_width = $t.outerWidth()
			$t.css('left', _.x((p_width/2) - (t_width/2) + opts.offsetX))

		if opts.vertical
			p_height = $p.outerHeight()
			t_height = $t.outerHeight()
			$t.css('top', _.x((p_height/2) - (t_height/2) + opts.offsetY))

		if opts.onresize
			$t.data('onresize', ->
				$t.center(parent, opts)
			)
			$(window).resize(->
				$t.data('onresize')()
			)
		return this
)(jQuery)

(($)->
	$.fn.formToJson = $.fn.formToJSON = (opts = {})->
		$t = this
		data = {}
		form = $(this).serializeArray()
		for elm in form
			if elm.name? && elm.name.length
				data[elm.name] = elm.value
		return data;
)(jQuery)

(($) ->
  $.fn.caret = (pos) ->
		target = this[0];
		if target?
			if arguments.length is 0
				if target.selectionStart
					pos = target.selectionStart;
					return if pos > 0 then pos else 0;
				else if target.createTextRange
					target.focus()
					range = document.selection.createRange()
					if (range == null)
						return '0'
					re = target.createTextRange()
					rc = re.duplicate()
					re.moveToBookmark(range.getBookmark())
					rc.setEndPoint('EndToStart', re)
					return rc.text.length
				else return 0
			if target.setSelectionRange? and target.setSelectionRange 
				target.setSelectionRange(pos, pos)
			else if target.createTextRange
				range = target.createTextRange()
				range.collapse(true)
				range.moveEnd('character', pos)
				range.moveStart('character', pos)
				range.select()
)(jQuery)

