const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLBoolean,
  GraphQLList,
} = require('graphql');
const moment = require('moment');
const NotificationGraphType = require('./NotificationGraphType');
const [
  AdminNotification,
  AdminNotifications,
] = require('../models/admin_notifications');

const Field = {
  type: NotificationGraphType,
  args: {
    admin_notification_id: { type: GraphQLString },
  },
  resolve: async (root, { admin_notification_id }, req) => {
<<<<<<< HEAD
    console.log(admin_notification_id);
    const obj = AdminNotifications.forge();
    obj.query('where', 'admin_notification_id', admin_notification_id);
=======
    const obj = AdminNotifications.forge();
    if (req.me) {
      obj.query('where', 'admin_notification_id', admin_notification_id);
    }
>>>>>>> d2870ffaf26e39b937ba50e78bda366944f9670c
    const rows = await obj.fetch();
    if (rows.models.length) {
      return rows.models[0].attributes;
    }
    return {};
  },
};
const Fields = {
  type: new GraphQLList(NotificationGraphType),
  args: {
    sent_on: { type: GraphQLString },
    send_on: { type: GraphQLString },
  },
  resolve: async (root, { year, status }) => {
    const query = AdminNotifications.forge();
    query.query('orderBy', 'created_at', 'desc');
    const rows = await query.fetch();
    return rows.models.map(row => (row ? row.attributes : null));
  },
};
const Add = {
<<<<<<< HEAD
  type: NotificationGraphType,
=======
  type: new GraphQLList(NotificationGraphType),
>>>>>>> d2870ffaf26e39b937ba50e78bda366944f9670c
  args: {
    test: { type: GraphQLString },
    device: { type: GraphQLString },
    registered: { type: GraphQLString },
    attendee_type: { type: GraphQLString },
    msg: { type: GraphQLString },
    title: { type: GraphQLString },
    content: { type: GraphQLString },
    channel_type: { type: GraphQLString },
    channel_id: { type: GraphQLString },
    send_on: { type: GraphQLString },
  },
  resolve: async (root, args) => {
    const row = await AdminNotification.forge(args).save();
<<<<<<< HEAD
    await AdminNotifications.forge().sendUnsent();
=======
>>>>>>> d2870ffaf26e39b937ba50e78bda366944f9670c
    return row.attributes;
  },
};
const Update = {
<<<<<<< HEAD
  type: NotificationGraphType,
=======
  type: new GraphQLList(NotificationGraphType),
>>>>>>> d2870ffaf26e39b937ba50e78bda366944f9670c
  args: {
    admin_notification_id: { type: GraphQLString },
    test: { type: GraphQLString },
    device: { type: GraphQLString },
<<<<<<< HEAD
    attendee_type: { type: GraphQLString },
=======
>>>>>>> d2870ffaf26e39b937ba50e78bda366944f9670c
    registered: { type: GraphQLString },
    attendee_type: { type: GraphQLString },
    msg: { type: GraphQLString },
    title: { type: GraphQLString },
    content: { type: GraphQLString },
    channel_type: { type: GraphQLString },
    channel_id: { type: GraphQLString },
    send_on: { type: GraphQLString },
  },
<<<<<<< HEAD
  resolve: async (root, args) => {
    const notn = await AdminNotification.forge({
      admin_notification_id: args.admin_notification_id,
    }).fetch();
    if (notn) {
      notn.set(args);
=======
  resolve: async (
    root,
    {
      admin_notification_id,
      msg,
      title,
      content,
      channel_type,
      channel_id,
      type,
      link,
      send_on,
    }
  ) => {
    const notn = await AdminNotification.forge({
      admin_notification_id,
    }).fetch();
    if (notn) {
      const rows = await query.fetch();
      notn.set({
        msg,
        title,
        content,
        channel_type,
        channel_id,
        type,
        link,
        send_on,
      });
>>>>>>> d2870ffaf26e39b937ba50e78bda366944f9670c
      const updated = await notn.save();
      return updated.attributes;
    }
    return {};
  },
};
module.exports = {
  Type: NotificationGraphType,
  Field,
  Fields,
  Add,
  Update,
};
