const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const [User, Users] = require('../models/users');
const [Ticket, Tickets] = require('../models/tickets');
const [Transaction, Transactions] = require('../models/transactions');
const [Transfer, Transfers] = require('../models/transfers');
const [UserNote, UserNotes] = require('../models/user_notes');
const [EventRsvp, EventRsvps] = require('../models/event_rsvps');
const TransactionGraph = require('./transactions');
const UserNoteGraphType = require('./UserNoteGraphType');
const TicketGraphType = require('./TicketGraphType');
const tickets = require('../models/tickets');

const UserType = new GraphQLObjectType({
  name: 'User',
  description: 'User',
  fields: () => {
    const TransferGraphType = require('./TransferGraphType');
    const TransactionGraphType = require('./TransactionGraphType');
    const EventGraphType = require('./EventGraphType');
    const TicketGraphType = require('./TicketGraphType');
    return {
      user_id: { type: GraphQLString },
      hash: { type: GraphQLString },
      attending14: { type: GraphQLString },
      attending15: { type: GraphQLString },
      attending16: { type: GraphQLString },
      attending17: { type: GraphQLString },
      attending18: { type: GraphQLString },
      attending19: { type: GraphQLString },
      pre18: { type: GraphQLString },
      pre19: { type: GraphQLString },
      ticket_type: { type: GraphQLString },
      type: { type: GraphQLString },
      email: { type: GraphQLString },
      first_name: { type: GraphQLString },
      last_name: { type: GraphQLString },
      user_name: {
        type: GraphQLString,
        resolve: row => {
          const u = row.user_name;
          if (u === undefined) return '';
          return u.length === 40 ? '' : u;
        },
      },
      password: {
        type: GraphQLBoolean,
        resolve: row => {
          const pw = row.password;
          return pw !== undefined && pw && pw.length;
        },
      },
      email_hash: { type: GraphQLString },
      site: { type: GraphQLString },
      facebook: { type: GraphQLString },
      twitter: { type: GraphQLString },
      instagram: { type: GraphQLString },
      location: { type: GraphQLString },
      lat: { type: GraphQLString },
      lon: { type: GraphQLString },
      distance: { type: GraphQLString },
      academy: { type: GraphQLString },
      location: { type: GraphQLString },
      address: { type: GraphQLString },
      address2: { type: GraphQLString },
      city: { type: GraphQLString },
      region: { type: GraphQLString },
      zip: { type: GraphQLString },
      country: { type: GraphQLString },
      calling_code: { type: GraphQLString },
      phone: { type: GraphQLString },
      accomodation: { type: GraphQLString },
      intro: { type: GraphQLString },
      size: { type: GraphQLString },
      created_at: { type: GraphQLString },
      updated_at: { type: GraphQLString },
      stripe: { type: GraphQLString },
      merge_log: { type: GraphQLString },
      merged: { type: GraphQLString },
      merge_user: {
        type: UserType,
        resolve: async row => {
          if (row.merged && +row.merged > 0) {
            const u = await User.forge({ user_id: row.merged }).fetch();
            return u.attributes;
          }
          return {};
        },
      },
      merged_users: {
        type: new GraphQLList(UserType),
        resolve: async row => {
          const rows = await Users.forge()
            .query('where', { merged: row.user_id })
            .fetch();
          return rows.map(v =>
            v.attributes !== undefined ? v.attributes : {}
          );
        },
      },
      emails: {
        type: new GraphQLList(EmailType),
        resolve: async row => {
          const [Email, Emails] = require('../models/emails');
          const emails = await Emails.forge()
            .query(qb => {
              qb.where('user_id', row.user_id);
              qb.orderBy('created_at', 'desc');
            })
            .fetch();
          return emails.map(v =>
            v.attributes !== undefined ? v.attributes : {}
          );
        },
      },
      transactions: {
        type: new GraphQLList(TransactionGraphType),
        resolve: async row => {
          const ts = await Transactions.forge()
            .query(qb => {
              qb.where('user_id', row.user_id);
            })
            .fetch();
          return ts.map(v => (v.attributes !== undefined ? v.attributes : {}));
        },
      },
      rsvps: {
        type: new GraphQLList(EventGraphType),
        resolve: async row => {
          const query = EventRsvps.forge().query(qb => {
            qb.select('*');
            qb.where('user_id', row.user_id);
            qb.where('year', process.yr);
            qb.orderBy('events.start');
            qb.leftJoin('events', 'events.event_id', 'event_rsvps.event_id');
          });
          const rsvps = await query.fetch();

          // console.log(rsvps);
          return rsvps.map(v =>
            v.attributes !== undefined && v ? v.attributes : {}
          );
        },
      },
      transfers_to: {
        type: new GraphQLList(TransferGraphType),
        resolve: async row => {
          const ts = await Transfers.forge()
            .query(qb => {
              qb.where('to_id', row.user_id);
            })
            .fetch();
          return ts.map(v =>
            v.attributes !== undefined && v ? v.attributes : {}
          );
        },
      },
      transfers_from: {
        type: new GraphQLList(TransferGraphType),
        resolve: async row => {
          const ts = await Transfers.forge()
            .query(qb => {
              qb.where('user_id', row.user_id);
            })
            .fetch();
          return ts.map(v =>
            v.attributes !== undefined && v ? v.attributes : {}
          );
        },
      },
      tickets: {
        type: new GraphQLList(TicketGraphType),
        resolve: async row => {
          const ts = await Tickets.forge()
            .query(qb => {
              qb.where('user_id', row.user_id);
              qb.orWhere('purchaser_id', row.user_id);
            })
            .fetch();
          return ts.map(v =>
            v.attributes !== undefined && v ? v.attributes : {}
          );
        },
      },
      admin_notes: {
        type: new GraphQLList(UserNoteGraphType),
        resolve: async row => {
          const notes = await UserNotes.forge()
            .query(qb => {
              qb.where('about_id', row.user_id);
              qb.where('admin', '1');
            })
            .fetch();
          return notes.map(v =>
            v.attributes !== undefined ? v.attributes : {}
          );
        },
      },
    };
  },
});

const EmailType = new GraphQLObjectType({
  name: 'Email',
  description: 'Email',
  fields: () => {
    return {
      email_id: { type: GraphQLString },
      user_id: { type: GraphQLString },
      promo: { type: GraphQLString },
      data: { type: GraphQLString },
      subject: { type: GraphQLString },
      created_at: { type: GraphQLString },
      resent_from: { type: GraphQLString },
      promo: { type: GraphQLString },
    };
  },
});

module.exports = UserType;
