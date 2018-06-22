const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLBoolean,
  GraphQLList,
} = require('graphql');
const EventGraphType = require('./EventGraphType');
const [Event, Events] = require('../models/events');

const NotificationType = new GraphQLObjectType({
  name: 'Notification',
  description: 'Notification Type',
  fields: () => {
    return {
      admin_notification_id: { type: GraphQLString },
      msg: { type: GraphQLString },
      test: { type: GraphQLString },
      device: { type: GraphQLString },
      registered: { type: GraphQLString },
      attendee_type: { type: GraphQLString },
      title: { type: GraphQLString },
      content: { type: GraphQLString },
      type: { type: GraphQLString },
      channel_type: { type: GraphQLString },
      event_id: {
        type: GraphQLString,
        resolve: async ({ event_id }) => {
          ev = await Event.forge({ event_id }).fetch();
          if (ev) {
            return ev.attributes;
          }
          return {};
        },
      },
      link: { type: GraphQLString },
      send_on: { type: GraphQLString },
      sent_on: { type: GraphQLString },
      sent_users: { type: GraphQLInt },
      sent_devices: { type: GraphQLInt },
      created_at: { type: GraphQLString },
      updated_at: { type: GraphQLString },
    };
  },
});
module.exports = NotificationType;
