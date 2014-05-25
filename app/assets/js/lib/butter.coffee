twoDigits = (d) ->
	if 0 <= d && d < 10
		return "0" + d.toString();
	if -10 < d && d < 0
		return "-0" + (-1*d).toString();
	return d.toString();
 
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

