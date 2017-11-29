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
    console.log(args);
    const existing = await User.forge({
      email: args.email,
    }).fetch();
    if (existing) {
      console.log('EXISTING');
      return Object.assign({}, existing.attributes, { existing: true });
    }
    console.log('NOT EXISTING');
    const row = await User.forge(args).save();
    return row.attributes;
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
    console.log(user_id);
    const existing = await User.forge({
      user_id,
    }).fetch();
    if (existing) {
      console.log('EXISTING');
      console.log(existing);
      const admin_id =
        req.me !== undefined ? req.me.get('user_id') : 'no-admin';
      console.log(1);
      hash = require('crypto')
        .createHash('md5')
        .update('' + +new Date())
        .digest('hex')
        .substr(0, 5);
      console.log(2);
      existing.registerTicket('ADDED_BY_' + admin_id + '_' + hash);
      console.log(3);
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
  GiveTicket,
  Fields,
};
