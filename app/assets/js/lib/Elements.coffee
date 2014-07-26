window.E = Elements = 
	el: (tag, content, attrs) ->
		html = '<'+tag
		opts = attrs
		attrs = _.omit attrs, ['open']
		for attr,val of attrs
			html += ' '+attr+'="'+val+'"'
		if not content?
			html += '/>'
		else if not attrs.open?
			html += '>'+content+'</'+tag+'>'
		return html
	p: (attrs, content) ->
		return @el('p', attrs, content)
	div: (attrs, content) ->
		return @el('div', attrs, content)
	input: (attrs, content) ->
		return @el('input', attrs, content)
	span: (attrs, content) ->
		return @el('span', attrs, content)
	a: (attrs, content) ->
		return @el('a', attrs, content)
	img: (attrs, content) ->
		return @el('img', attrs, content)
