const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const moment = require('moment');
const [Ticket, Tickets] = require('../models/tickets');
const [Transaction, Transactions] = require('../models/transactions');
const [Feed, Feeds] = require('../models/feeds');
const [FeedLike, FeedLikes] = require('../models/feed_likes');
const [Connection, Connections] = require('../models/connections');
const [Event, Events] = require('../models/events');
const [EventRsvp, EventRsvps] = require('../models/event_rsvps');
const [User, Users] = require('../models/users');
const [
  CredentialChange,
  CredentialChanges,
] = require('../models/credential_changes');
const UserGraph = require('./users');
const TicketGraphType = require('./TicketGraphType');

const Type = new GraphQLObjectType({
  name: 'Stats',
  description: 'Stats Type',
  fields: () => {
    return {
      current_wave_total: { type: GraphQLInt },
      current_wave_plan: { type: GraphQLInt },
      current_wave_tickets: { type: GraphQLInt },
      total_tickets: { type: GraphQLInt },
      num_assigned: { type: GraphQLInt },
      num_started_profile: { type: GraphQLInt },
      single_buys: { type: GraphQLInt },
      payment_plans: { type: GraphQLInt },
      meetups: { type: GraphQLInt },
      friends: { type: GraphQLInt },
      rsvps: { type: GraphQLInt },
      posts: { type: GraphQLInt },
      likes: { type: GraphQLInt },
      pw: { type: GraphQLInt },
      num_finished_profile: { type: GraphQLInt },
    };
  },
});
const Field = {
  type: Type,
  resolve: async root => {
    const vals = {
      current_wave_tickets: 0,
      total_tickets: 0,
      num_assigned: 0,
      num_started_profile: 0,
      num_finished_profile: 0,
      double_buys: 0,
      single_buys: 0,
      friends: 0,
      rsvps: 0,
      likes: 0,
      meetups: 0,
      posts: 0,
      pw: 0,
    };
    const waveDate = '2019-06-29 00:00:00';
    const posts = await Feeds.query(qb => {
      qb.where('created_at', '>', waveDate);
    }).fetch();
    const pw = await CredentialChanges.query(qb => {
      qb.where('created_at', '>', waveDate);
    }).fetch();
    const likes = await FeedLikes.query(qb => {
      qb.where('created_at', '>', waveDate);
    }).fetch();
    const meetups = await Events.query(qb => {
      qb.where('year', process.yr);
      qb.where('type', 'meetup');
      qb.where('active', 1);
    }).fetch();
    const rsvps = await EventRsvps.query(qb => {
      qb.where('stamp', '>', waveDate);
    }).fetch();
    const friends = await Connections.query(qb => {
      qb.where('created_at', '>', waveDate);
    }).fetch();
    const paymentPlans = await Transactions.query(qb => {
      qb.where('product_id', '23');
      qb.where('paid_amount', '>', '5000');
    }).fetch();
    const paymentPlansThisWave = await Transactions.query(qb => {
      qb.where('product_id', '23');
      qb.where('created_at', '>', waveDate);
      qb.where('paid_amount', '>', '5000');
    }).fetch();
    const singleBuysThisWave = await Transactions.query(qb => {
      qb.where('product_id', '21');
      qb.where('created_at', '>', waveDate);
      qb.where('paid_amount', '>', '63000');
    }).fetch();
    const singleBuys = await Transactions.query(qb => {
      qb.whereIn('product_id', ['16', '21']);
      qb.where('paid_amount', '>', '10000');
    }).fetch();
    const doubleBuys = await Transactions.query(qb => {
      qb.where('product_id', '16');
      qb.where('paid_amount', '>', '5000');
    }).fetch();
    const row = await Tickets.query(qb => {
      qb.where('year', '2019');
    }).fetch();
    vals.current_wave_plans = paymentPlansThisWave.models.reduce((sum, row) => {
      return sum + +row.get('quantity');
    }, 0);
    vals.payment_plans = paymentPlans.models.reduce((sum, row) => {
      return sum + +row.get('quantity');
    }, 0);
    vals.single_buys = singleBuys.models.reduce((sum, row) => {
      return sum + +row.get('quantity');
    }, 0);
    const double_buys = doubleBuys.models.reduce((sum, row) => {
      return sum + +row.get('quantity');
    }, 0);
    vals.single_buys += double_buys;
    vals.current_wave_tickets = singleBuysThisWave.models.reduce((sum, row) => {
      return sum + +row.get('quantity');
    }, 0);
    vals.current_wave_plan = paymentPlansThisWave.models.reduce((sum, row) => {
      return sum + +row.get('quantity');
    }, 0);
    vals.current_wave_total =
      vals.current_wave_plan + vals.current_wave_tickets;
    vals.friends = friends.models.length;
    vals.posts = posts.models.length;
    vals.likes = likes.models.length;
    vals.meetups = meetups.models.length;
    vals.pw = pw.models.length;
    vals.rsvps = rsvps.models.length;
    row.models.forEach(v => {
      const status = v.get('status');
      if (status === 'active' || status === 'unclaimed') {
        vals.total_tickets += 1;
        // if (
        //   moment(v.get('created_at')).format('YYYY-MM-DD') >
        //   '2017-10-01 00:00:00'
        // ) {
        //   vals.current_wave_tickets += 1;
        // }
      }
      if (status === 'active') {
        vals.num_assigned += 1;
      }
    });
    return vals;
  },
};
module.exports = {
  Type,
  Field,
};
