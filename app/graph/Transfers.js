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
const TransferGraphType = require('./TransferGraphType');
const Type = TransferGraphType;

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
    query.query('orderBy', 'created_at', 'desc');
    const rows = await query.fetch();
    return rows.models.map(row => (row ? row.attributes : null));
  },
};
module.exports = {
  Type,
  Field,
  Fields,
};
