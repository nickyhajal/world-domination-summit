const _ = require('underscore');
const redis = require('redis');
const rds = redis.createClient();
const twitterAPI = require('node-twitter-api');
const moment = require('moment');
const crypto = require('crypto');
const async = require('async');
const _s = require('underscore.string');

const routes = function(app) {
  let racetask;
  const [RaceTask, RaceTasks] = require('../../models/racetasks');
  const [
    RaceSubmission,
    RaceSubmissions,
  ] = require('../../models/race_submissions');

  return (racetask = {
    add(req, res, next) {
      return req.me.getCapabilities().then(function() {
        if (req.me.hasCapability('race')) {
          const post = _.pick(
            req.query,
            RaceTask.prototype.permittedAttributes
          );
          post.slug = _s.slugify(post.task);
          post.year = process.yr;
          RaceTask.forge(post)
            .save()
            .then(task => next(), err => console.error(err));
        } else {
          res.r.msg = "You don't have permission to do that!";
          res.status(403);
          next();
        }
      });
    },

    upd(req, res, next) {
      req.me.getCapabilities().then(function() {
        if (req.me.hasCapability('race')) {
          const post = _.pick(
            req.query,
            RaceTask.prototype.permittedAttributes
          );
          post.slug = _s.slugify(post.task);
          RaceTask.forge(post)
            .save()
            .then(() => next());
        } else {
          res.r.msg = "You don't have permission to do that!";
          res.status(403);
          next();
        }
      });
    },

    search(req, res, next) {
      RaceTasks.forge()
        .query('orderBy', 'section')
        .fetch()
        .then(function(tasks) {
          res.r.racetasks = tasks.models;
          next();
        });
    },

    get_submissions(req, res, next) {
      RaceSubmissions.forge()
        .query('where', 'rating', '0')
        .fetch()
        .then(function(rsp) {
          res.r.submissions = rsp.models;
          next();
        });
    },

    get_all_submissions(req, res, next) {
      RaceSubmissions.forge()
        .query('orderBy', 'rating', 'DESC')
        .fetch()
        .then(function(rsp) {
          res.r.submissions = rsp.models;
          next();
        });
    },
  });
};

module.exports = routes;
