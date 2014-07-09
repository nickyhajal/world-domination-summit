async = require('async')
Q = require('q')
juice = require('juice')

shell = (app, db) ->
  process = ->
    tk "Initiating Meetup Emails"
    [User, Users] = require '../models/users'
    User.forge({user_id: '3854'})
    .fetch()
    .then (user) =>
      user.similar_meetups()
      .then (meetups) ->
        html = meetupHtml(meetups)
        #user.sendEmail 'meetup-suggestions', 'Suggested Meetups',
        #  meetup_html: html

  meetupText = (meetup) ->
    #Formated Meetup Text
    text = '<div class="meetup-descr-shell">
      <div class="meetup-content">
        <div class="meetup-name">'+meetup.get('what')+'</div>
        <div class="meetup-descr-who">A meetup for '+meetup.get('who')+'</div>
        <div class="meetup-descr">'+meetup.get('descr')+'</div>
      </div>
    </div>'
    return text

  meetupHtml = (meetups) ->
    html = '
    <style type="text/css">
      .meetup-table {
        width: 530px;
      }
      div.meetup-descr-shell {
          clear:                      both;
          position:                   relative;
          z-index:                    10;
          margin-top:                 20px;
          margin-bottom:              50px;
          width:                      500px;
      }
      div.meetup-content {
          margin-left:                0px;
          width:                      416px;
          float:                      right;
      }
      div.meetup-actions {
          float:                      left;
      }
      div.meetup-name {
          font-size:                  24px;
          font-family:                VitesseBook;
      }
      div.meetup-descr {
          width:                      340px;
          font-family:                karla;
      }
      div.meetup-descr-who {
          font-family:                karlabold;
          margin-top:                 10px;
          margin-bottom:              10px;
          font-weight:                bold;
      }
      .freqmsg {
          font-size: 8pt;
          margin-top: 24px;
          padding: 15px;
          line-height: 142%;
          background:#F2F2EA;
      }
    </style>
    <table class="meetup-table">'

    for meetup in meetups
      text = meetupText(meetup)
      html += '<tr><td>'+text+'</td></tr>'

    html += '</table><div class="freqmsg">
      You can change the frequency or turn off these
      notifications at
      <a href="http://worlddominationsummit.com/settings">http://worlddominationsummit.com/settings</a>
      </div>
    '

    # juice.juiceContent html,
    #   url: 'http://worlddominationsummit.com'
    # , (err, html) ->
    #   return html
    return html

  process()

module.exports = shell
