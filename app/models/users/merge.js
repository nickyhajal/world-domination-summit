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

const update = async (Model, to, from) => {
  try {
    await Model.where({ user_id: from }).save(
      { user_id: to },
      { patch: true, method: 'update' }
    );
  } catch (e) {
    console.log(e.message);
  }
};

module.exports = async (to, from, settings) => {
  const fu = await User.forge({ user_id: from }).fetch();
  const tu = await User.forge({ user_id: to }).fetch();

  if (fu && tu) {
    update(Booking, to, from);
    update(Checkin, to, from);
    update(EventHost, to, from);
    update(EventRsvp, to, from);
    update(Feed, to, from);
    update(FeedComment, to, from);
    update(FeedLike, to, from);
    update(Notification, to, from);
    update(Registration, to, from);
    update(Ticket, to, from);
    update(Transfer, to, from);
    update(UserNote, to, from);
  }
};
