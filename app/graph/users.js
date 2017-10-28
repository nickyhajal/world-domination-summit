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
// const Create = {
//   type: Type,
//   args: {
//     value: {
//       description: 'The value name',
//       type: new GraphQLNonNull(GraphQLString),
//     },
//   },
//   resolve: async (obj, { value }) => {
//     const existing = await Value.forge({
//       value,
//     }).fetch();
//     if (existing) {
//       return Object.assign({}, { ...existing.attributes }, { existing: true });
//     }
//     const row = await Value.forge({
//       value,
//     }).save();
//     return row.attributes;
//   },
// };
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
  // Create,
  Fields,
};
