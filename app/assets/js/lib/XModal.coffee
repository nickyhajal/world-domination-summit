XModal = XModel.extend(
	model: 'XModal'
	defaults:
		model: 'XModal'
	initialize: (opts = {})->
		@initViews()
		@modalView = new @view.modal({el: $('body')});
	open: ->
		@get('modal').fadeIn(100)
		return false
	close: (opts = {}) ->
		opts = _.defaults(opts, 
			remove: true
		)
		baseid = @get('modalid')
		model = @;
		@get('modal').fadeOut(100, =>
			if modals[baseid]? && modals[baseid].closed?
				modals[baseid].closed(model)
			if opts.remove
				$('#unc_modal_'+@get('modalid')).remove()
		)
		return false
	initViews: -> 
		model = this;
		@view = {}
		@view.modal = XView.extend({
			initialize: ->
				modal = $('#unc_modal_'+model.get('modalid'))
				if !modal.length
					@prep('append')
				else
					model.set({modal: modal})
			prep: (output)->
				baseid = model.get('modalid')
				modalid = 'unc_modal_' + baseid

				# Get a modal's filler
				# Generally defined in pagejs
				baseid = baseid.replace('-', '__');
				if modals[baseid]? && modals[baseid].prep?
					filler =  modals[baseid].prep(model)
				else
					filler = {}

				# Apply modal content
				content = _.t(modalid.replace('unc_', ''), filler)
				@out = _.t('modal', {content: content, modalid: modalid})
				@render(output)
			rendered: ->
				baseid = model.get('modalid')
				el = $('#unc_modal_'+baseid)
				$('.unc_modal_shell', el).center().data('modal', model)
				model.set({modal: el})
				$('.unc_modal_closed', el).live('click', ->
					model.close()
					return false
				)
				$(el).scan()
				baseid = baseid.replace('-', '__');
				if modals[baseid]? && modals[baseid].rendered?
					modals[baseid].rendered(model)
		})
)