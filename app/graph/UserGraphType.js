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

const RsvpType = new GraphQLObjectType({
  name: 'RSVP',
  description: 'RSVP',
  fields: () => {
    return {
      transfer_id: { type: GraphQLString },
      user_id: { type: GraphQLString },
      to_id: { type: GraphQLString },
      new_attendee: { type: GraphQLString },
      year: { type: GraphQLString },
      status: { type: GraphQLString },
      from: {
        type: UserType,
        resolve: async row => {
          const user = await User.forge({ user_id: row.user_id }).fetch();
          return user.attributes;
        },
      },
      to: {
        type: UserType,
        resolve: async row => {
          const user = await User.forge({ user_id: row.to_id }).fetch();
          return user.attributes;
        },
      },
      ticket: {
        type: TicketGraphType,
        resolve: async row => {
          const ticket = await Ticket.forge({
            user_id: row.to_id,
            year: row.year,
          }).fetch();
          return ticket.attributes;
        },
      },
      created_at: { type: GraphQLString },
    };
  },
});

const UserType = new GraphQLObjectType({
  name: 'User',
  description: 'User',
  fields: () => {
    const TransactionGraphType = require('./TransactionGraphType');
    const EventGraphType = require('./EventGraphType');
    const TicketGraphType = require('./TicketGraphType');
    return {
      user_id: { type: GraphQLString },
      hash: { type: GraphQLString },
      attending14: { type: GraphQLInt },
      attending15: { type: GraphQLInt },
      attending16: { type: GraphQLInt },
      attending17: { type: GraphQLInt },
      attending18: { type: GraphQLInt },
      pre18: { type: GraphQLInt },
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
          const rsvps = await EventRsvps.forge()
            .query(qb => {
              qb.where('user_id', row.user_id);
              qb.where('year', process.yr);
              qb.leftJoin('events', 'events.event_id', 'event_rsvps.event_id');
            })
            .fetch();
          console.log(rsvps);
          return rsvps.map(
            v => (v.attributes !== undefined ? v.attributes : {})
          );
        },
      },
      transfers_to: {
        type: new GraphQLList(TransferType),
        resolve: async row => {
          const ts = await Transfers.forge()
            .query(qb => {
              qb.where('to_id', row.user_id);
            })
            .fetch();
          return ts.map(v => (v.attributes !== undefined ? v.attributes : {}));
        },
      },
      transfers_from: {
        type: new GraphQLList(TransferType),
        resolve: async row => {
          const ts = await Transfers.forge()
            .query(qb => {
              qb.where('user_id', row.user_id);
            })
            .fetch();
          return ts.map(v => (v.attributes !== undefined ? v.attributes : {}));
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
          return ts.map(v => (v.attributes !== undefined ? v.attributes : {}));
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
          return notes.map(
            v => (v.attributes !== undefined ? v.attributes : {})
          );
        },
      },
    };
  },
});

const TransferType = new GraphQLObjectType({
  name: 'Transfer',
  description: 'Transfer',
  fields: () => {
    const TransactionGraphType = require('./TransactionGraphType');
    const TicketGraphType = require('./TicketGraphType');
    return {
      transfer_id: { type: GraphQLString },
      user_id: { type: GraphQLString },
      to_id: { type: GraphQLString },
      new_attendee: { type: GraphQLString },
      year: { type: GraphQLString },
      status: { type: GraphQLString },
      from: {
        type: UserType,
        resolve: async row => {
          const user = await User.forge({ user_id: row.user_id }).fetch();
          return user.attributes;
        },
      },
      to: {
        type: UserType,
        resolve: async row => {
          const user = await User.forge({ user_id: row.to_id }).fetch();
          return user.attributes;
        },
      },
      ticket: {
        type: TicketGraphType,
        resolve: async row => {
          const ticket = await Ticket.forge({
            user_id: row.to_id,
            year: row.year,
          }).fetch();
          return ticket.attributes;
        },
      },
      created_at: { type: GraphQLString },
    };
  },
});

module.exports = UserType;
