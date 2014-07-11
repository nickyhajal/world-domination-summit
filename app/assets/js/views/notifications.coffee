ap.Views.notifications = XView.extend
  initialize: ->
    _.whenReady 'assets', =>
      @initRender()

  rendered: ->
    _.whenReady 'users', =>
      @renderNotifications()
      @readNotifications()

  renderNotifications: ->
    shell = $('#notification-shell')
    html = ''
    ap.api 'get user/notifications', {}, (rsp) =>
      if rsp.notifications?.length > 0
        for notification in rsp.notifications
          html += @renderNotification(notification)
        shell.html(html)

  renderNotification: (notn) ->
    data = JSON.parse(notn.content)
    link = '<a href="http://worlddominationsummit.com'+notn.link+'">'
    text = ''

    switch notn.type
      when 'feed_like'
        user = ap.Users.get(data.liker_id)
        text += '<div class="notification-content-shell">'
        text += link+'<div style="background:url('+user.get('pic')+')" class="notification-content-userpic"></div></a>'
        text += '<div class="notification-content-section">'
        text += link+user.get('first_name')+' '+user.get('last_name')+' liked your post!</a>'
        text += '<br/><br/>'+data.content_str
        text += '</div>'
        text += '</div>'

      when 'feed_comment'
        user = ap.Users.get(data.commenter_id)
        text += '<div class="notification-content-shell">'
        text += link+'<div style="background:url('+user.get('pic')+')" class="notification-content-userpic"></div>'
        text += '<div class="notification-content-section">'
        text += link+user.get('first_name')+' '+user.get('last_name')+' commented on your post!</a>'
        text += '<br/><br/>'+data.content_str
        text += '</a>'
        text += '</div>'
        text += '</div>'

      when 'connected'
        user = ap.Users.get(data.from_id)
        text += '<div class="notification-content-shell">'
        text += link+'<div style="background:url('+user.get('pic')+')" class="notification-content-userpic"></div>'
        text += '<div class="notification-content-section">'
        text += link+user.get('first_name')+' '+user.get('last_name')+' friended you!</a>'
        text += '</a>'
        text += '</div>'
        text += '</div>'

  readNotifications: ->
    ap.api 'get user/notifications/read', {}, (rsp) =>
      return rsp 
