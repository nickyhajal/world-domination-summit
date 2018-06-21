const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLBoolean,
  GraphQLList,
} = require('graphql');

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
      channel_id: { type: GraphQLString },
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
