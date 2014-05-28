ap.Routes.admin = (panel, extra = false) ->
	_.whenReady 'admin_templates', ->
		options = {}
		if ap.templates['pages_admin_'+panel]?
			if extra
				options.extra = extra
			ap.goTo('admin_'+panel, options)
	ap.api 'get assets', {assets: 'admin_templates'}, (rsp) ->
		for name,tpl of rsp.admin_templates
			ap.templates['pages_admin_'+name] = '<div id="page_content">'+tpl+'</div>'
		_.nowReady 'admin_templates'