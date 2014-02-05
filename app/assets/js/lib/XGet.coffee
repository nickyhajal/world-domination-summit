

## 
 # Extended backbone view
 ##
XView = Backbone.View.extend(
	out: ''
	defaults: 
		output: false

	##
	 # Render now simple outputs in the channel
	 # we request - use @prepare() to template, etc
	 # then call render
	 ##
	render: (output_type)->
		html = @out
		switch output_type
			when 'html'
				tmpEl = @el;
				@el = $('<div/>').html(html)
				@rendered()
				outEl = @el;
				@el = tmpEl
				return outEl.html()
			when 'replace'
				$(@el).html(html)
			when 'append'
				$(@el).append(html)
			when 'prepend'
				$(@el).prepend(html)
		@rendered()
	rendered: ()->
		# Child over-writes
	
)

##
 # Extended backbone model
 ##
XModel = Backbone.Model.extend(
)

##
 # Extended backbone collection
 ##
XCollection = Backbone.Collection.extend(
	indexByCid: (cid) -> 	 
		for index, model of @models
			if +model.cid == +cid
				return index
		return false
	indexById: (id) -> 	 
		for index, model of @models
			if +model.id == +id
				return index
		return false
)