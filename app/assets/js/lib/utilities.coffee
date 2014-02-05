ap.tpl	= (name) ->
	# Template Source
	tpl = $('#tpl_'+name).html();
	tpl = unescape(tpl);

	# Replace {} with <%= %>
	tpl = tpl.replace(/{/g, '<%=').replace(/}/g, '%>');

	# Parse IDs
	tpl = tpl.replace(/_Tmp/g, ''); 

	return tpl;

ap.a = (toDo, data, callback, opts)-> 
	d 'replace fm.a'
	d toDo
window.dpl = 
	ari : (a, i) ->
		return a[i];
	distance: (from, to) ->
		radius      = 3958      # Earth's radius (miles)
		pi          = 3.1415926
		deg_per_rad = 57.29578  # Number of degrees/radian (for conversion)
		distance = ( radius * pi * Math.sqrt( (from['lat'] - to['lat']) * (from['lat'] - to['lat']) + Math.cos(from['lat'] / deg_per_rad) * Math.cos(to['lat'] / deg_per_rad) * (from['lon'] - to['lon']) * (from['lon'] - to['lon'])) / 180);
		return distance; # Returned using the units used for $radius.
	near: (from, to, maxDist) ->
		dist = dpl.distance(from, to);
		if (dist < maxDist) 
			return dist
		else 
			return false
window.px = (str) ->
	return str + 'px'
window.isset = ->
	a = arguments
	l = a.length
	i = 0
	if (l is 0)
		throw new Error('Empty isset'); 
	while (i is not l)
		if (not a[i]? || not a[i]?)
			return false;
		i++
	return true;
String.prototype.addSlashes = () ->
	return (this+'').replace(/([\\"'])/g, "\\$1").replace(/\u0000/g, "\\0");
String.prototype.stripSlashes = () ->
	return (this+'').replace(/\\(.?)/g, (s, n1) ->
		switch (n1) 
			when '\\'
				return '\\'
			when '0'
				return '\0'
			when ''
				return ''
			else	
				return n1
	);
String.prototype.trim = ->
	return (this+'').replace(/^\s*([\S\s]*?)\s*$/, '$1');
Array.prototype.binarySearch = (needle, case_insensitive) ->
	if !this.length
		return -1
	high = this.length - 1
	low = 0
	case_insensitive = if (typeof(case_insensitive) is not 'undefined' and case_insensitive) then true else false
	needle = if (case_insensitive) then needle.toLowerCase() else needle
	while (low <= high) 
		mid = parseInt((low + high) / 2)
		element = if (case_insensitive) then this[mid].toLowerCase() else this[mid]
		if (element > needle) 
			high = mid - 1
		else if (element < needle) 
			low = mid + 1
		else 
			return mid
	return -1