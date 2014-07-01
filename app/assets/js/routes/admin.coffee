ap.Routes.admin = (panel, extra = false) ->

	if ap.admin_templates?
		for name,tpl of ap.admin_templates
			ap.templates['pages_admin_'+name] = '<div id="page_content">'+tpl+'</div>'
	else
		ap.api 'get assets', {assets: 'admin_templates'}, (rsp) ->
			ap.admin_templates = rsp.admin_templates
			for name,tpl of ap.admin_templates
				ap.templates['pages_admin_'+name] = '<div id="page_content">'+tpl+'</div>'
			_.nowReady 'admin_templates'

	_.whenReady 'admin_templates', ->
		tk 'hey'
		options = {}
		tk panel
		tk ap.templates
		if ap.templates['pages_admin_'+panel]?
			tk 'no'
			if extra
				options.extra = extra
			ap.goTo('admin_'+panel, options)