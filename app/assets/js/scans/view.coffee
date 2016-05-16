jQuery.fn.scan
  add:
    id: 'xview'
    fnc: ->
      $el = $(this)
      view = $el.data('view').replace('-', '_')
      options = $el.data()
      options.el = $el
      options.ignore_sidebar = true
      options.render = 'replace'
      delete options.view
      xview = new ap.Views[view](options)
      $el.data('xview', xview)
