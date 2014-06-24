_d = {}

_d.ari = (a, i)->
	return a[i];

_d.btn = (el, during, done, reset = 1200) ->
	fnc = 'html'
	if el.prop('tagName') is 'INPUT'
		fnc = 'val'
	orig = el[fnc]()
	el[fnc](during)
	return {
		el: el
		during: during
		done: done
		reset: reset
		finish: ->
			el[fnc](done)
			setTimeout ->
				el[fnc](orig)
			, reset
	}

_d.autop = (str) ->
	return '<p>' + str.replace(/\n/g, '</p><p>') + '</p>'

_d.unSlug = (str)->
	str = str.split('-')
	for i, v of str
		str[i] = dpl.ucfirst(v)
	return str.join(' ')

_d.slugify = (str) ->
	from = "ąàáäâãćęèéëêìíïîłńòóöôõùúüûñçżź"
	to = "aaaaaaceeeeeiiiilnooooouuuunczz"
	regex = new RegExp(defaultToWhiteSpace(from), 'g');

	str = (''+str).toLowerCase();

	str = str.replace(regex, (ch)->
		index = from.indexOf(ch)
		return to.charAt(index) || '-';
	)
	return _.trim(str.replace(/[^\w\s-]/g, '').replace(/[-\s]+/g, '-'), '-')

_d.striptags = (input, allowed) ->
	input = input.toString()
	allowed = (((allowed || "") + "").toLowerCase().match(/<[a-z][a-z0-9]*>/g) || []).join('') 
	tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi
	commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/gi
	return input.replace(commentsAndPhpTags, '').replace tags, ($0, $1) ->
		return if allowed.indexOf('<' + $1.toLowerCase() + '>') > -1 then $0 else '' 

_d.toRad = (val) ->
	return val *  (Math.PI / 180)

_d.getDistance = (lat1, lon1, lat2, lon2) ->
  a = 6378137
  b = 6356752.314245
  f = 1 / 298.257223563
  L = _.toRad (lon2 - lon1)
  U1 = Math.atan((1 - f) * Math.tan(_.toRad(lat1)))
  U2 = Math.atan((1 - f) * Math.tan(_.toRad(lat2)))
  sinU1 = Math.sin(U1)
  cosU1 = Math.cos(U1)
  sinU2 = Math.sin(U2)
  cosU2 = Math.cos(U2)
  lambda = L
  lambdaP = undefined
  iterLimit = 100
  loop
    sinLambda = Math.sin(lambda)
    cosLambda = Math.cos(lambda)
    sinSigma = Math.sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) + (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) * (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda))
    return 0  if sinSigma is 0
    cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda
    sigma = Math.atan2(sinSigma, cosSigma)
    sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma
    cosSqAlpha = 1 - sinAlpha * sinAlpha
    cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha
    cos2SigmaM = 0  if isNaN(cos2SigmaM)
    C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha))
    lambdaP = lambda
    lambda = L + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)))
    break unless Math.abs(lambda - lambdaP) > 1e-12 and --iterLimit > 0
  return NaN  if iterLimit is 0
  uSq = cosSqAlpha * (a * a - b * b) / (b * b)
  A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)))
  B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)))
  deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)))
  s = b * A * (sigma - deltaSigma)
  return s

_d.nicetime = (start, end = false, just=60) ->
		# If no end is specified, use now
		if not _.isNumber(start)
			start = +start
		if not end
			end = +(new Date())
		diff = (end - start) / 1000
	
		# Output pretty times
		if(diff < just)
			return 'just now'
		else if(diff < 60)
			outDiff = Math.floor(diff)
			return outDiff+' '+(if outDiff==1 then 'second' else  'seconds')+ ' ago'
		else if(diff < 3600)
			outDiff = Math.floor(diff / 60)
			return outDiff+' '+(if outDiff==1 then 'minute' else  'minutes')+ ' ago'
		else if(diff < 86400)
			outDiff = Math.floor(diff / 3600)
			return  outDiff+' '+(if outDiff==1 then 'hour' else  'hours')+ ' ago'
		else if(diff > 86400)
			outDiff = Math.floor(diff / 86400)
			return  outDiff+' '+(if outDiff==1 then 'day' else  'days')+ ' ago'
		return false

defaultToWhiteSpace = (characters)->
	if (characters != null) 
		return '[' + _.escapeRegExp(''+characters) + ']';
	return '\\s';
_d.rgbToHex = (color)->
	if color.substr(0, 1) is '#' 
		return color
	 digits = /(.*?)rgb\((\d+), (\d+), (\d+)\)/.exec(color)
	 red = parseInt(digits[2])
	 green = parseInt(digits[3])
	 blue = parseInt(digits[4])
	 rgb = blue | (green << 8) | (red << 16)
	rgb = rgb.toString(16)
	while (rgb.length < 6) 
		rgb = '0' + rgb
	return '#' + rgb
_d.resizeStr = (str, size, append = '...')->
	if str.length > size
		str = str.substr(0, size) + append
	return str
_d.x = (str)->
	return str + 'px'
_.templateSettings = {
	  interpolate : /\{\{(.+?)\}\}/g
}

##
 # Turn a query string into an object
 ##
_d.query = (str = false, sep = '&') ->
	if typeof str == 'string'
		queryBits = str.split(sep)
		queries = {}
		for query in queryBits
			bits = query.split('=')
			queries[bits[0]] = bits[1]
		return queries
	return ''

_d.t = (template, data) ->
	html = unescape(ap.templates[template])
	return _.template(html, data)

_d.addSlashes = (str)->
	return (str+'').replace(/([\\"'])/g, "\\$1").replace(/\u0000/g, "\\0");

_d.stripSlashes = (str)->
	return (str+'').replace(/\\(.?)/g, (s, n1)->
		switch (n1) 
			when '\\'
				return '\\'
			when '0'
				return '\0'
			when ''
				return ''
			else
				return n1
	)

_d.money = (num, opts = false) ->
	opts = [] if not opts
	opts.presign ?= '$'
	opts.postsign ?= ''
	opts.div ?= 100
	return opts.presign + (( num * 1 ) / opts.div ).toFixed(2) + opts.postsign

###
 
 Readies allow you to wait for something else to complete
 before executing a function.

 If what you're waiting for already completed, your function
 executes immediately

###
_d.readys = {};
_d.whenReady = (id, fnc) ->
	_d.ready(id, fnc)

_d.ready = (id, fnc)->
	if _.isUndefined(_d.readys[id])
		_d.readys[id] = 
			ready: false
			fnc: false
	if _.isFunction(_d.readys[id].fnc)
		existing = _d.readys[id].fnc
		_d.readys[id].fnc = ->
			fnc()
			existing()
	else 
		_d.readys[id].fnc = ->
			fnc()
	if _d.readys[id].ready
		_d.doReady(id)

_d.nowReady = (id)->
	_d.isReady(id)

_d.isReady = (id)->
	if !_.isUndefined(_d.readys[id])
		_d.readys[id].ready = true;
		_d.doReady(id)
	else
		_d.readys[id] = 
			ready: true
			fnc: false
_d.doReady = (id)->
	if _d.readys[id]? and _d.readys[id].fnc? and _d.readys[id].fnc
		_d.readys[id].fnc();
		_d.readys[id].fnc = null;

if this._?
	this._.mixin(_d)
else 
	this._ = _d

_.readys = _d.readys


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


