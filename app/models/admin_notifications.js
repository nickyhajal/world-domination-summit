const Shelf = require('./shelf');
const Bookshelf = require('bookshelf');
const Q = require('q');
const redis = require('redis');
const rds = redis.createClient();
const crypto = require('crypto');
const apn = require('apn');
const _ = require('underscore');
const async = require('async');
const _s = require('underscore.string');
const moment = require('moment');
const [Device, Devices] = require('./devices');
[Feed, Feeds] = require('./feeds');

const AdminNotification = Shelf.Model.extend({
  tableName: 'admin_notifications',
  idAttribute: 'admin_notification_id',
  hasTimestamps: true,
  async getDevices() {
    const {
      device: device_type,
      test,
      device,
      registered,
      type,
      attendee_type,
      event_id,
      channel_type,
      channel_id,
    } = this.attributes;
    const devices = Devices.forge();
    devices.query(
      'join',
      'users',
      'users.user_id',
      '=',
      'devices.user_id',
      'left'
    );
    devices.query('where', `attending${process.yr}`, '1');
    if (test === 'yes') {
      devices.query('whereIn', 'devices.user_id', [
        '176',
        // '6292',
        // '6256',
        // '179',
        // '216',
        // '6263',
        // '8884',
      ]); //, '179', '216', '6292'])
    }
    if (device_type !== 'all') {
      devices.query('where', 'devices.type', device);
    }
    if (registered !== 'all') {
      if (registered === 'yes') {
        devices.query(
          'join',
          'registrations',
          'registrations.user_id',
          '=',
          'devices.user_id',
          'left'
        );
        devices.query('where', 'registrations.event_id', '=', '1');
        devices.query('where', 'registrations.year', '=', process.yr);
      } else {
        devices.query('whereNotExists', function() {
          return this.select('*')
            .from('registrations')
            .whereRaw(
              `\
devices.user_id = registrations.user_id \
AND event_id='1' \
AND year = '` +
                process.yr +
                "'"
            );
        });
      }
    }
    if (attendee_type !== 'all') {
      const types = attendee_type.split(',');
      const ttypes = [];
      const atypes = [];
      for (let t of Array.from(types)) {
        if (['360', 'connect'].indexOf(t) > -1) {
          ttypes.push(t);
        } else {
          atypes.push(t);
        }
      }
      const _ttypes = _.map(ttypes, v => `'${v}'`).join(', ');
      const _atypes = _.map(atypes, v => `'${v}'`).join(', ');
      if (ttypes.length && atypes.length) {
        devices.query(
          'whereRaw',
          `(users.ticket_type in (${_ttypes}) OR users.type in (${_atypes}))`
        );
      } else if (ttypes.length) {
        devices.query('whereIn', 'users.ticket_type', ttypes);
      } else if (atypes.length) {
        devices.query('whereIn', 'users.type', atypes);
      }
    }
    if (event_id !== 'all' && event_id) {
      devices.query(
        'join',
        'event_rsvps',
        'event_rsvps.user_id',
        '=',
        'devices.user_id',
        'left'
      );
      devices.query('where', 'event_rsvps.event_id', '=', event_id);
    }
    const rsp = await devices.fetch();
    const user_ids = {};
    let id_count = 0;
    for (let device of Array.from(rsp.models)) {
      const key = `u_${device.get('user_id')}`;
      if (user_ids[key] == null) {
        user_ids[key] = 1;
        id_count += 1;
      }
    }
    return {
      user_count: id_count,
      device_count: rsp.models.length,
      devices: rsp.models,
    };
  },
  async send() {
    const {
      device,
      registered,
      event_id,
      channel_type,
      content,
      test,
      attendee_type,
      msg,
      title,
    } = this.attributes;
    if (device != null && registered != null) {
      const { devices, device_count, user_count } = await this.getDevices();
      console.log(devices.map(v => v.get('token')));
      console.log(devices.length);
      if (+device_count > 0) {
        if (content != null) {
          let type;
          const post = {
            content,
            user_id: '8082',
          };
          if (event_id != null && event_id !== 'all') {
            post.channel_type = 'meetup';
            post.channel_id = event_id;
          }
          if (test != null && test === 'yes') {
            post.restrict = 'staff';
          }
          if (attendee_type != null) {
            if (attendee_type === '360') {
              post.restrict = '360';
            }
            if (attendee_type === 'staff') {
              post.restrict = 'staff';
            }
            if (attendee_type === 'ambassador') {
              post.restrict = 'ambassador';
            }
            if (attendee_type === 'staff,ambassador') {
              post.restrict = 'ambnstaff';
            }
          }
          const uniq =
            moment().format('YYYY-MM-DD HH:mm') + post.content + post.user_id;
          post.hash = crypto
            .createHash('md5')
            .update(uniq)
            .digest('hex');
          const existing = await Feed.forge({
            hash: post.hash,
          }).fetch();
          if (!existing) {
            const feed = Feed.forge(post);
            const feed_rsp = await feed.save();
            const feed_id = feed_rsp.get('feed_id');
            // const feed_id = 99999;
            if (feed_id != null && feed_id > 0) {
              // console.log(devices.length);
              for (let device of Array.from(devices)) {
                let tokens = [device.get('token')];
                type = device.get('type');
                const user_id = device.get('user_id');
                const link = `/dispatch/${feed_id}`;
                // console.log(user_id);
                if (type === 'ios') {
                  // and user_id == 176
                  const note = new apn.Notification();
                  note.alert = {
                    title: title ? title : null,
                    body: msg,
                  };
                  note.payload = {
                    content: '{"user_id":"8082"}',
                    type: 'feed_comment',
                    link,
                  };
                  // tk note
                  // tk tokens
                  // console.log(user_id);
                  // console.log(note);
                  // console.log(tokens);
                  const result = await process.APN.pushNotification(
                    note,
                    device.get('token')
                  );
                  // console.log(result);
                  // console.log('error: ', result.failed[0].error);
                  // console.log('error: ', result.failed[0].response);
                } else if (type === 'and') {
                  // and user_id == 176
                  token = device.get('token');

                  message = {
                    to: token,
                    collapse_key: 'WDS Notifications',
                    notification: {
                      title: 'WDS App',
                      body: msg,
                    },
                    data: {
                      title: title ? title : 'WDS App',
                      body: msg,
                      id: post.hash,
                      user_id: '8082',
                      content: '{"user_id":"8082"}',
                      type: 'feed_comment',
                      link: link,
                    },
                  };

                  console.log(message);
                  console.log('SEND FCM');

                  process.fcm.send(message, function(err, result) {
                    tk('FCM RSP:');
                    tk(err);
                    return tk(result);
                  });
                }
              }
              this.set({
                sent_devices: device_count,
                sent_users: user_count,
                sent_on: moment()
                  .utc()
                  .format('YYYY-MM-DD HH:mm:ss'),
              });
              await this.save();
              return true;
            }
          } else {
            return { error: 'Already posted' };
          }
        }
      }
    }
  },
});

const AdminNotifications = Shelf.Collection.extend({
  model: AdminNotification,

  async sendUnsent() {
    console.log('>> Check notifications');
    const now = moment()
      .utc()
      .format('YYYY-MM-DD HH:mm:ss');
    const unsent = await AdminNotifications.forge()
      .query(qb => {
        qb.whereNull('sent_on');
        qb.where('send_on', '<', now);
      })
      .fetch();
    await Promise.all(unsent.map(n => n.send()));
  },
  async watchNotifications() {
    await AdminNotifications.forge().sendUnsent();
    setTimeout(() => {
      console.log('>> Schedule next notifications check (60s)');
      AdminNotifications.forge().watchNotifications();
    }, 60000);
  },
});

// console.log('>> Start watching notifications');
// AdminNotifications.forge().watchNotifications();

module.exports = [AdminNotification, AdminNotifications];
