ap.Views.admin_ambassadors = XView.extend
  timo: 0
  events:
    'keyup .ambassador-search': 'search_keyup'
    'click #ambassador-results tr': 'row_click'
  initialize: ->
    @initRender()
    @search()

  rendered: ->
    if ap.lastSearch? and ap.lastSearch
      $('.ambassador-search').val(ap.lastSearch)
      @search(ap.lastSearch)
      ap.lastSearch = false

  search_keyup: (e) ->
    val = $(e.currentTarget).val()
    @search(val)

  search: (val) ->
    clearTimeout(@timo)
    @timo = setTimeout ->
      ap.api 'get admin/ambassadors', {}, (rsp) ->
        html = ''
        for atn in rsp.users
          atn = new ap.User(atn)
          html += '<tr data-speaker="'+atn.get('user_id')+'">
            <td>
              <span>'+atn.get('first_name')+' '+atn.get('last_name')+'</span>
            </td>
            <td>'+atn.get('email')+'</td>'
        $('#speaker-results').html(html)
        $('#ambassador-start').hide()
        $('#speaker-results-shell').show()
    , 500

  whenFinished: ->
    ap.lastSearch = $('.ambassador-search').val()
