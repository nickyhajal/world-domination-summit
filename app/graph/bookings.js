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
const [Event, Events] = require('../models/events');
const UserGraph = require('./users');
const Type = new GraphQLObjectType({
  name: 'Booking',
  description: 'Bookings',
  fields: () => ({
    booking_id: {
      type: GraphQLInt,
      resolve: row => {
        return row.event_id;
      },
    },
    type: { type: GraphQLString },
    status: { type: GraphQLString },
    created_at: { type: GraphQLString },
    updated_at: { type: GraphQLString },
    hosts: {
      type: new GraphQLList(UserGraph.Type),
      description: 'Hotel Customers',
      resolve: async root => {
        const user = await User.forge({ user_id: root.user_id }).fetch();
        return user.attributes;
      },
    },
  }),
});
const Field = {
  type: Type,
  args: {
    event_id: { type: GraphQLString },
    slug: { type: GraphQLString },
  },
  resolve: async (root, args) => {
    const query = {};
    if (args.event_id !== undefined) query.event_id = args.event_id;
    if (args.slug !== undefined) query.slug = args.slug;
    const row = await Event.forge(query).fetch();
    return row.attributes;
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

module.exports = {
  Type,
  Field,
  // Create,
  Fields,
};
