jQuery.fn.scan
  add:
    id: 'xview'
    fnc: ->
      $el = $(this)
      view = $el.data('view').replace('-', '_')
      options = $el.data()
      options.el = $el
      options.render = 'replace'
      tk options
      delete options.view
      tk view
      tk ap.Views[view]
      xview = new ap.Views[view](options)
      tk xview
      $el.data('xview', xview)
