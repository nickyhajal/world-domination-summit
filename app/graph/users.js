const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const _ = require('underscore');
const [User, Users] = require('../models/users');
const [Ticket, Tickets] = require('../models/tickets');
const [Transaction, Transactions] = require('../models/transactions');
const TransactionGraph = require('./transactions');
const TicketGraph = require('./tickets');
const UserGraphType = require('./UserGraphType');

const Type = UserGraphType;
const Search = {
  type: new GraphQLList(Type),
  args: {
    years: { type: GraphQLString },
    types: { type: GraphQLString },
    search: { type: GraphQLString },
  },
  resolve: async (root, { search, years, types }, req) => {
    const results = await Users.forge().search({
      search,
      years,
      types,
    });
    const final = results.map(v => (v.attributes ? v.attributes : v));
    return final;
  },
};
const Field = {
  type: Type,
  args: {
    id: { type: GraphQLString },
  },
  resolve: async (root, { id }) => {
    const row = await Users.forge().getUser(id);
    return row.attributes;
  },
};
const Add = {
  type: Type,
  args: {
    email: { type: GraphQLString },
    type: { type: GraphQLString },
    ticket_type: { type: GraphQLString },
    first_name: { type: GraphQLString },
    last_name: { type: GraphQLString },
    address: { type: GraphQLString },
    address2: { type: GraphQLString },
    city: { type: GraphQLString },
    region: { type: GraphQLString },
    zip: { type: GraphQLString },
    country: { type: GraphQLString },
  },
  resolve: async (obj, args) => {
    const existing = await User.forge({
      email: args.email,
    }).fetch();
    if (existing) {
      console.log('EXISTING');
      return Object.assign({}, existing.attributes, { existing: true });
    }
    const row = await User.forge(args).save();
    return row.attributes;
  },
};
const RsvpAdd = {
  type: Type,
  args: {
    user_id: { type: GraphQLString },
    event_id: { type: GraphQLString },
  },
  resolve: async (obj, args) => {
    const [EventRsvp, EventRsvps] = require('../models/tickets');
    const existing = await EventRsvp.forge({
      user_id: args.user_id,
      event_id: args.event_id,
    }).fetch();
    if (!existing) {
      const rsvp = await EventRsvp.forge({
        user_id: args.user_id,
        event_id: args.event_id,
      }).save();
    }
    return {};
  },
};
const RsvpDelete = {
  type: Type,
  args: {
    user_id: { type: GraphQLString },
    event_id: { type: GraphQLString },
  },
  resolve: async (obj, args) => {
    const [EventRsvp, EventRsvps] = require('../models/tickets');
    const existing = await EventRsvp.forge({
      user_id: args.user_id,
      event_id: args.event_id,
    }).fetch();
    if (!existing) {
      await existing.delete();
    }
    return {};
  },
};
const Update = {
  type: Type,
  args: {
    user_id: { type: GraphQLString },
    type: { type: GraphQLString },
    ticket_type: { type: GraphQLString },
    email: { type: GraphQLString },
    site: { type: GraphQLString },
    facebook: { type: GraphQLString },
    instagram: { type: GraphQLString },
    first_name: { type: GraphQLString },
    last_name: { type: GraphQLString },
    user_name: { type: GraphQLString },
    address: { type: GraphQLString },
    address2: { type: GraphQLString },
    city: { type: GraphQLString },
    region: { type: GraphQLString },
    zip: { type: GraphQLString },
    country: { type: GraphQLString },
  },
  resolve: async (obj, args) => {
    const post = _.pick(args, User.prototype.permittedAttributes);
    const { user_id } = args;
    const user = await User.forge({ user_id }).fetch();
    let update;
    if (user) {
      update = await user.set(post).save();
    }
    return update.attributes;
  },
};
const GiveTicket = {
  type: Type,
  args: {
    user_id: {
      type: new GraphQLNonNull(GraphQLInt),
    },
  },
  resolve: async (obj, { user_id }, req) => {
    const existing = await User.forge({
      user_id,
    }).fetch();
    console.log('give ticket');
    console.log(existing);
    console.log(existing.attributes);
    if (existing) {
      const admin_id =
        req.me !== undefined ? req.me.get('user_id') : 'no-admin';
      const hash = require('crypto')
        .createHash('md5')
        .update('' + +new Date())
        .digest('hex')
        .substr(0, 5);
      const ticket = await Ticket.forge({
        type: existing.get('ticket_type'),
        eventbrite_id: `ADDED_BY_ADMIN_${hash}`,
        user_id: user_id,
        purchaser_id: user_id,
        status: 'unclaimed',
        year: process.year,
      }).save();
      existing.connectTicket(ticket);
      return Object.assign({}, existing.attributes, { existing: true });
    }
    return {};
  },
};
const Fields = {
  type: new GraphQLList(Type),
  // args: {
  //   q: { type: GraphQLString },
  // },
  resolve: async (root, args) => {
    const rows = await Events.forge().query();
    return rows.models.map(row => row.attributes);
  },
};

module.exports = {
  Type,
  Field,
  Search,
  Add,
  RsvpAdd,
  RsvpDelete,
  Update,
  GiveTicket,
  Fields,
};
