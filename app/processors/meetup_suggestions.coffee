async = require('async')
Q = require('q')
juice = require('juice')
_s = require('underscore.string')
moment = require('moment')
shell = (app, db) ->
  process = ->
    tk "Initiating Meetup Emails"
    [User, Users] = require '../models/users'
    User.forge({user_id: '3854'})
    .fetch()
    .then (user) =>
      user.similar_meetups()
      .then (meetups) ->
        meetupHtml(meetups)
        .then (html) ->
          user.sendEmail 'meetup-suggestions', 'Suggested Meetups',
            meetup_html: html

  meetupText = (meetup) ->
    dfr = Q.defer()
    time = moment.utc(meetup.get('start'))
    day = time.format('dddd')
    renderHosts(meetup)
    .then (hosts) ->
      #Formated Meetup Text
      text = '
        <td class="meetup-sidebar">
          <div class="meetup-day">'+day+'</div>
          <div class="meetup-time">'+time.format('h:mm a')+'</div>
          <div class="meetup-host">'+hosts+'</div>
          <a href="http://www.worlddominationsummit.com/meetup/'+_s.slugify(meetup.get('what'))+'">More Details</a>
        </td>
        <td class="meetup-content">
          <div class="meetup-name">'+meetup.get('what')+'</div>
          <div class="meetup-descr-who">A meetup for '+meetup.get('who')+'</div>
          <div class="meetup-descr">'+_s.truncate(meetup.get('descr'), 340)+'</div>
        </td>
      '
      dfr.resolve text
    return dfr.promise

  renderHosts = (ev) ->
    html = ''
    dfr = Q.defer()
    ev.hosts()
    .then (hosts) ->
      for host in hosts
        html += '
          <div class="meetup-descr-host-shell">
            <div class="meetup-descr-host-avatar" style="background:url('+host.get('pic')+')"></div>
            <div class="meetup-descr-host-name">'+host.get('first_name')+' '+host.get('last_name')+'</div>
          </div>
        '
      dfr.resolve html
    return dfr.promise

  meetupHtml = (meetups) ->
    html = '
    <style type="text/css">
      .meetup-table {
        width: 530px;
      }
      tr.row-spacing {
        height: 50px;
      }
      .meetup-content {
          padding-left:               20px;
          width:                      340px;
      }
      div.meetup-time {
          font-size:                  15pt;
          font-family:                karla;
          text-align:                 center;
          background:                 none repeat scroll 0px 0px rgb(242, 242, 234);
          width:                      100%;
      }
      div.meetup-day {
          font-size:                  15pt;
          font-family:                karla;
          text-align:                 center;
          background:                 none repeat scroll 0px 0px rgb(242, 242, 234);
          width:                      100%;
      }
      div.meetup-name {
          font-size:                  24px;
      }
      div.meetup-descr {
          width:                      340px;
      }
      div.meetup-descr-who {
          margin-top:                 10px;
          margin-bottom:              10px;
          font-weight:                bold;
      }
      .meetup-sidebar {
          margin-right:               16px;
          width:                      130px;
      }
      .meetup-sidebar a {
          width:                      auto;
          display:                    block;
          text-decoration:            none;
          text-align:                 center;
          margin-top:                 2px;
          padding:                    9px 8px 7px;
          background:                 none repeat scroll 0px 0px rgb(242, 242, 234);
      }
      div.meetup-descr-host-avatar {
          background-size:            100% auto ! important;
          -webkit-background-size:    100% auto ! important;
          border-radius:              100%;
          -moz-border-radius:         100%;
          -webkit-border-radius:      100%;
          margin:                     0px auto;
          height:                     40px;
          width:                      40px;
      }
      div.meetup-descr-host-name {
          position:                   relative;
          top:                        4px;
          text-align:                 center;
      }
      div.meetup-descr-host-shell {
          background:                 none repeat scroll 0px 0px rgb(242, 242, 234);
          margin:                     2px 0px;
          padding:                    5px 9px;
      }
      div.meetup-host-avatar {
          background-size:            100% auto ! important;
          -webkit-background-size:    100% auto ! important;
          border-radius:              50%;
          -moz-border-radius:         50%;
          -webkit-border-radius:      50%;
          width:                      34px;
          height:                     34px;
          float:                      left;
          margin-right:               5px;
      }
      div.meetup-host-name {
          position:                   relative;
          top:                        9px;
      }
      div.meetup-host-shell {
          margin:                     14px 0px -10px;
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
    dfr = Q.defer()
    async.each meetups, (meetup, cb) =>
      meetupText(meetup)
      .then (text) ->
        html += '<tr class="meetup">'+text+'</tr><tr class="row-spacing"></tr>'
        cb()

    , ->
      html += '</table><div class="freqmsg">
        You can change the frequency or turn off these
        notifications at
        <a href="http://worlddominationsummit.com/settings">http://worlddominationsummit.com/settings</a>
        </div>
      '

      juice.juiceContent html,
        url: 'http://worlddominationsummit.com'
      , (err, html) ->
        dfr.resolve(html)
    return dfr.promise

  process()

module.exports = shell
