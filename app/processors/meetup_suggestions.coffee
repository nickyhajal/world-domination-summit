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
    return meetup.get('what')

  meetupHtml = (meetups) ->
    html = '
    <style type="text/css">
      .meetup-av {
        width:40px;
        height: 40px;
      }
      .meetup-table {
        width: 530px;
      }
      .meetup-table a {
        display:block;
        color: #E27F1C;
        font-weight:bold;
      }
      .meetup-table td {
        padding:2px 5px 2px 15px;
      }
      .meetup-table tr {
        background:#F2F2EA;
        border-bottom:1px solid #fff;
      }
      .meetup-table tr td:first-of-type {
        padding:5px 5px 2px 5px;
        width: 30px;
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
