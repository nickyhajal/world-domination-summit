ap.Views.admin_racetasks= XView.extend
  timo: 0
  events:
    'click .racetask-row': 'showTask'
  initialize: ->
    @initRender()

  rendered: ->
    @listing()

  listing: ->
    ap.api 'get racetasks', {}, (rsp) ->
      html = ''
      lastSection = ''
      for task in rsp.racetasks
        if task.section isnt lastSection
          html += '<tr class="search-mid-heading"><th colspan="10">'+task.section+'</th></tr>'
          lastSection = task.section
        html += '<tr class="racetask-row" data-racetask_id="'+task.racetask_id+'">
          <td>'+task.task+'</td>
          <td class="search-actions">
            <a href="#" class="button">Edit</a></span>
          </td>
        '
      $('#racetask-results').html(html)
      $('#racetask-start').hide()
      $('#racetask-shell').show()

  showTask: (e) ->
    e.preventDefault()
    el = $(e.currentTarget)
    racetask_id = el.data('racetask_id')
    ap.navigate('admin/racetask/'+racetask_id)
