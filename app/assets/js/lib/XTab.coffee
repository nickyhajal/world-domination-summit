Notification = window.XModel.extend
	initialize: ->
		@initViews()
		if @get('display')
			@activeView = new @view.notification
				el: $('#notifications')
	initViews: ->
		self = this
		@view = {}
		@view.notification = XView.extend
			events: 
				'click .close': 'close'
			initialize: ->
				@prep 'prepend'
			prep: (output)->
				@out = _.t 'parts_notification', 
					msg: self.get('msg')
					clss: self.get('clss')
				@render output
				if (self.get('autoclose'))
					setTimeout =>
						$('.close', self.el).click()
					, (self.get('autoclose') * 1000)
			close: (e) ->
				$t = $(e.currentTarget)
				$t.closest('.a_notification').slideUp(150)
				e.stopPropagation()
				return false
ap.Notify = 
	active: []
	now: (opts = {}) ->
		opts = _.defaults opts,
			msg: ''
			clss: 'success'
			autoclose: 30
			display: true
		n = new Notification opts
		ap.Notify.active.push n
	closeAll: ->
		for [i..this.active.length]
			n = this.active[i]
			n.close()
			delete this.active[i]