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
const [Booking, Bookings] = require('../models/bookings');
const UserGraph = require('./users');
const Type = new GraphQLObjectType({
  name: 'Booking',
  description: 'Bookings',
  fields: () => ({
    booking_id: {
      type: GraphQLInt,
    },
    type: { type: GraphQLString },
    status: { type: GraphQLString },
    created_at: { type: GraphQLString },
    updated_at: { type: GraphQLString },
    user: {
      type: UserGraph.Type,
      description: 'Customers',
      resolve: async root => {
        const user = await User.forge({ user_id: root.user_id }).fetch();
        return user.attributes;
      },
    },
    extra: { type: GraphQLString },
  }),
});
const Field = {
  type: Type,
  args: {
    booking_id: { type: GraphQLString },
  },
  resolve: async (root, args, req) => {
    const bks = Bookings.forge();
    if (req.me) {
      bks.query('where', 'user_id', req.me.user_id);
    }
    bks.query('orderBy', 'created_at', 'desc');
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
    type: { type: GraphQLString },
  },
  resolve: async (root, args) => {
    const evs = Bookings.forge();
    if (args.type !== undefined && args.type !== null) {
      evs.query('where', 'type', args.type);
    }
    // if (args.showInactive === undefined) {
    //   evs.query('where', 'active', '1');
    // }
    evs.query('orderBy', 'created_at', 'desc');
    const rows = await evs.fetch();
    return rows.models.map(row => row.attributes);
  },
};
const Update = {
  type: Type,
  args: {
    booking_id: { type: GraphQLString },
    extra: { type: GraphQLString },
    status: { type: GraphQLString },
  },
  resolve: async (root, args, req) => {
    const query = {};
    const booking = await Booking.forge({
      booking_id: args.booking_id,
    }).fetch();
    if (req.me) {
      if (+booking.get('user_id') === +req.me.get('user_id')) {
        if (args.extra) {
          booking.set('extra', args.extra);
        }
        if (args.status) {
          booking.set('status', args.status);
        }
        const row = await booking.save();
        return row.attributes;
      }
    }
    return {};
  },
};

module.exports = {
  Type,
  Field,
  Update,
  // Create,
  Fields,
};
