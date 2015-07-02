ap.Views.admin_places = XView.extend
  timo: 0
  events:
    'click .place-row': 'showPlace'
  initialize: ->
    @initRender()

  rendered: ->
    @listing()

  listing: ->
    ap.api 'get places', {}, (rsp) ->
      html = ''
      lastSection = ''
      for place in rsp.places
        if place.type_name isnt lastSection
          html += '<tr class="search-mid-heading"><th colspan="10">'+place.type_name+'</th></tr>'
          lastSection = place.type_name
        html += '<tr class="place-row" data-place_id="'+place.place_id+'">
          <td>'+place.name+'</td>
          <td class="search-actions">
            <a href="/admin/place/'+place.place_id+'" class="button">Edit</a></span>
          </td>
        '
      $('#places-results').html(html)
      $('#places-start').hide()
      $('#places-shell').show()

