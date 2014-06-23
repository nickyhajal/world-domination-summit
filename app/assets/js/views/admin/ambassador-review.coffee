ap.Views.admin_ambassador_review = XView.extend
  timo: 0
  events:
    'click .ambassador-button': 'review'
  initialize: ->
    @initRender()

  rendered: ->
    @listing()

  listing: ->
    ap.api 'get admin/ambassadors', {}, (rsp) ->
      html = ''
      for atn in rsp.users
        atn = new ap.User(atn)
        html += '<tr data-user_id="'+atn.get('user_id')+'">
          <td>
            <span>'+atn.get('first_name')+' '+atn.get('last_name')+'</span>
          </td>
          <td>'+atn.get('email')+'</td>
          <td class="ambassador-review-actions">
          <a data-action="accept" href="/api/admin/ambassador_accept?id='+atn.get('user_id')+'" class="button ambassador-button">Accept</a>
          <a data-action="reject" href="/api/admin/ambassador_reject?id='+atn.get('user_id')+'" class="button ambassador-button">Reject</a>
          </td>'
      $('#ambassador-review-results').html(html)
      $('#ambassador-start').hide()
      $('#ambassador-review-results-shell').show()

  review: (e) ->
    e.preventDefault()
    el = $(e.currentTarget)
    action = el.data('action')
    str = _.titleize(action)
    user_id = el.closest('tr').data('user_id')
    btn = _.btn(el, str+'ing', str+'ed')
    ap.api 'get admin/ambassador_'+action, {user_id: user_id}, (rsp) ->
      btn.finish()
      setTimeout ->
        el.closest('tr').remove()
      , 500