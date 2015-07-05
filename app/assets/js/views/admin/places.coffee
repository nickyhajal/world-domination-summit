ap.Views.admin_places = XView.extend
  timo: 0
  events:
    'click .place-row': 'showPlace'
    'click .delete-event': 'confirmDelete'
    'click .actually-delete-event': 'actuallyDelete'
  initialize: ->
    @initRender()

  rendered: ->
    @listing()

  confirmDelete: (e)->
    $t = $(e.currentTarget)
    $t.html("You're Sure?")
    $t.removeClass('delete-event')
    $t.addClass('actually-delete-event')
    setTimeout ->
      $t.addClass('delete-event')
      $t.removeClass('actually-delete-event')
      $t.html("Delete")
    , 750
    e.preventDefault()
  actuallyDelete: (e) ->
    e.preventDefault()
    $t = $(e.currentTarget)
    $t.html("Deleting...")
    place_id = $t.closest('tr').data('place_id')
    ap.api 'delete place', {place_id: place_id}, =>
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
            <a href="#" class="delete-event button">Delete</a></span>
            <a href="/admin/place/'+place.place_id+'" class="button">Edit</a></span>
          </td>
        '
      $('#places-results').html(html)
      $('#places-start').hide()
      $('#places-shell').show()

