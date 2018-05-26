const moment = require('moment');

const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLBoolean,
  GraphQLList,
} = require('graphql');
const [User, Users] = require('../models/users');
const [Transfer, Transfers] = require('../models/transfers');
const UserGraph = require('./users');
const Type = new GraphQLObjectType({
  name: 'Transfer',
  description: 'Transfer Type',
  fields: () => ({
    tranfer_id: {
      type: GraphQLInt,
    },
    user_id: { type: GraphQLString },
    to_id: { type: GraphQLString },
    new_attendee: { type: GraphQLString },
    year: { type: GraphQLString },
    status: { type: GraphQLString },
    created_at: { type: GraphQLString },
    updated_at: { type: GraphQLString },
    from: {
      type: UserGraph.Type,
      description: 'Customers',
      resolve: async root => {
        const user = await User.forge({ user_id: root.user_id }).fetch();
        return user ? user.attributes : {};
      },
    },
    to: {
      type: UserGraph.Type,
      description: 'Customers',
      resolve: async root => {
        const user = await User.forge({ user_id: root.to_id }).fetch();
        return user ? user.attributes : {};
      },
    },
    extra: { type: GraphQLString },
  }),
});
const Field = {
  type: Type,
  args: {
    transfer_id: { type: GraphQLString },
  },
  resolve: async (root, { transfer_id }, req) => {
    const bks = Transfers.forge();
    if (req.me) {
      bks.query('where', 'tranfer_id', transfer_id);
    }
    const rows = await bks.fetch();
    if (rows.models.length) {
      return rows.models[0].attributes;
    }
    return {};
  },
};
const Fields = {
  type: new GraphQLList(Type),
  args: {
    year: { type: GraphQLString },
    status: { type: GraphQLString },
  },
  resolve: async (root, { year, status }) => {
    const query = Transfers.forge();
    if (year === undefined || !year) {
      query.query('where', 'year', process.year);
    }
    if (status === undefined || !status) {
      query.query('where', 'status', 'paid');
    }
    evs.query('orderBy', 'created_at', 'desc');
    const rows = await query.fetch();
    return rows.models.map(row => (row ? row.attributes : null));
  },
};
module.exports = {
  Type,
  Field,
  Fields,
};
