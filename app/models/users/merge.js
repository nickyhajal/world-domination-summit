const [Answer, Answers] = require('../answers');
const [Booking, Bookings] = require('../bookings');
const [Capability, Capabilities] = require('../capabilities');
const [Card, Cards] = require('../cards');
const [Checkin, Checkins] = require('../checkins');
const [Connection, Connections] = require('../connections');
const [Device, Devices] = require('../devices');
const [EventHost, EventHosts] = require('../event_hosts');
const [EventRsvp, EventRsvps] = require('../event_rsvps');
const [Feed, Feeds] = require('../feeds');
const [FeedComment, FeedComments] = require('../feed_comments');
const [FeedLike, FeedLikes] = require('../feed_likes');
const [UserInterest, UserInterests] = require('../user_interests');
const [Notification, Notifications] = require('../notifications');
const [Registration, Registrations] = require('../registrations');
const [Ticket, Tickets] = require('../tickets');
const [Transfer, Transfers] = require('../transfers');
const [TwitterLogin, TwitterLogins] = require('../twitter_logins');
const [UserNote, UserNotes] = require('../user_notes');
const [User, Users] = require('../users');

const update = async (Models, to, from, key = 'user_id') => {
  const Model = Models.forge().model;
  const name = Model.forge().tableName;
  let output = '';
  const by = key === 'user_id' ? '' : ` by ${key}`;
  const willUpdate = await Models.forge()
    .query('where', key, from)
    .fetch();
  const len = willUpdate.models.length;
  if (len > 0) {
    try {
      output = `Updating ${len} in ${name}${by}...`;
      const updated = await Model.where(key, from).save(
        { [key]: to },
        { patch: true, method: 'update' }
      );
      output += `Updated`;
    } catch (e) {
      output = e.message.includes('No rows')
        ? `Nothing to update in ${name}${by} after all`
        : e.message;
    }
  } else {
    output = `Nothing to update in ${name}${by}`;
  }
  return `${output}\n`;
};
const updatePreventingDuplicates = async (
  Models,
  to,
  from,
  key_id,
  content_id
) => {
  let o = '';
  const Model = Models.forge().model;
  const name = Model.forge().tableName;
  const primary = Model.forge().idAttribute;
  const fCs = await Models.forge()
    .query('where', key_id, from)
    .fetch();
  const tCs = await Models.forge()
    .query('where', key_id, to)
    .fetch();
  if (fCs.models.length) {
    if (tCs.models.length) {
      const ids = tCs.models.map(r => r.get(content_id));
      const existing = fCs.models.filter(r => ids.includes(r.get(content_id)));
      const toUpdate = fCs.models.filter(r => !ids.includes(r.get(content_id)));
      o += `Updating ${toUpdate.length} in ${name} by ${key_id}, ignoring ${
        existing.length
      } (duplicate)...`;
      await Promise.all(
        toUpdate.map(r =>
          Model.where(primary, r.get(primary)).save(
            { [key_id]: to },
            { patch: true, method: 'update' }
          )
        )
      );
      o += 'Updated';
    } else {
      o += `Updating ${name} by ${key_id} (none to overwrite)`;
      await Model.where(key_id, from).save(
        { [key_id]: to },
        { patch: true, method: 'update' }
      );
    }
  } else {
    o = `No ${name} to update`;
  }
  return `${o}\n`;
};
const updateCards = async (to, from) => {
  let o = '';
  const name = 'cards';
  const fCs = await Cards.forge()
    .query('where', 'user_id', from)
    .query('orderBy', 'card_id', 'DESC')
    .query('limit', '1')
    .fetch();
  const tCs = await Cards.forge()
    .query('where', 'user_id', to)
    .query('orderBy', 'card_id', 'DESC')
    .query('limit', '1')
    .fetch();
  if (fCs.models.length) {
    const fC = fCs.models[0];
    if (tCs.models.length) {
      const tC = tCs.models[0];
      if (tC.get('card_id') < fC.get('card_id')) {
        o = "From-user's card is newer, updating...";
        await fC.set('user_id', to).save();
        o += 'Updated';
      } else {
        o = "To-user's card is newer, not updating";
      }
    } else {
      o = "From-user's card exists and to-user's card doesn't, updating...";
      await fC.set('user_id', to).save();
      o += 'Updated';
    }
  } else {
    o = `No card to update`;
  }
  return `${o}\n`;
};
const updateAnswers = async (to, from) => {
  let o = '';
  const name = 'answers';
  const fCs = await Answers.forge()
    .query('where', 'user_id', from)
    .fetch();
  const tCs = await Answers.forge()
    .query('where', 'user_id', to)
    .fetch();
  if (fCs.models.length) {
    const fC = fCs.models[0];
    if (tCs.models.length) {
      // Figure out which answers don't exist or are older
      const toUpdate = fCs.models.filter(a => {
        const answer_id = a.get('answer_id');
        const question_id = a.get('question_id');
        const existing = tCs.models.find(
          e => e.get('question_id') == question_id
        );
        return !existing || existing.get('answer_id') < answer_id;
      });
      if (toUpdate.length) {
        o = `From-user has ${toUpdate.length} newer answers, updating...`;
        await Promise.all(
          toUpdate.map(async a => {
            // Set existing to negative userID as a way of deleting without losing data
            const ex = await Answer.where('user_id', to)
              .where('question_id', a.get('question_id'))
              .fetch();
            if (ex) {
              await ex
                .set('merged_delete', to)
                .set('user_id', null)
                .save();
            }
            await Answer.where('user_id', from)
              .where('question_id', a.get('question_id'))
              .save({ user_id: to }, { patch: true, method: 'update' });
          })
        );
      } else {
        o = "To-user's answers are newer, not updating";
      }
    } else {
      o = 'To-user has no answers, updating...';
      await Answer.where('user_id', from).save(
        { user_id: to },
        { patch: true, method: 'update' }
      );
      o += 'Updated';
    }
  } else {
    o = `No answers to update`;
  }
  return `${o}\n`;
};

module.exports = async (to, from, settings) => {
  const fu = await User.forge({ user_id: from }).fetch();
  const tu = await User.forge({ user_id: to }).fetch();
  let output = '';

  if (fu && tu) {
    output += await updateAnswers(to, from);
    output += await updatePreventingDuplicates(
      Connections,
      to,
      from,
      'user_id',
      'to_id'
    );
    output += await updatePreventingDuplicates(
      Connections,
      to,
      from,
      'to_id',
      'user_id'
    );
    output += await updatePreventingDuplicates(
      UserInterests,
      to,
      from,
      'user_id',
      'interest_id'
    );
    output += await updateCards(to, from);
    output += await update(Devices, to, from);
    output += await update(Bookings, to, from);
    output += await update(Capabilities, to, from);
    output += await update(Checkins, to, from);
    output += await update(EventHosts, to, from);
    output += await update(EventRsvps, to, from);
    output += await update(Feeds, to, from);
    output += await update(FeedComments, to, from);
    output += await update(FeedLikes, to, from);
    output += await update(Notifications, to, from);
    output += await update(Registrations, to, from);
    output += await update(TwitterLogins, to, from);
    output += await update(Tickets, to, from);
    output += await update(Tickets, to, from, 'purchaser_id');
    output += await update(Transfers, to, from);
    output += await update(Transfers, to, from, 'to_id');
    output += await update(UserNotes, to, from);
    output += await update(UserNotes, to, from, 'about_id');

    yr = 11;
    while (yr <= process.yr) {
      const col = `attending${yr}`;
      let fromAtning = fu.get(col);
      let toAtning = tu.get(col);
      if (toAtning !== '1' && fromAtning && toAtning != fromAtning) {
        output += `Updating ${col}\n`;
        tu.set(col, fromAtning);
      } else {
        output += `Not changing ${col}\n`;
      }
      yr += 1;
    }
    await tu.save();
    await fu
      .set({ [`attending${process.yr}`]: '-2', merged: to, merge_log: output })
      .save();
    console.log(output);
  }
  return output;
};
