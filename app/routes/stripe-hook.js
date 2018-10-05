const stripe = require('stripe')(process.env.STRIPE_SK);

const { processEvent } = require('./stripe-hook-functions');

const routes = app => {
  return app.all('/stripewh', (req, res) => {
    try {
      let sig = req.headers['stripe-signature'];
      console.log(req.body);
      console.log(sig);
      console.log(process.env.STRIPE_WHSEC);
      let ev = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_WHSEC
      );
      if (ev && ev.type === 'invoice.payment_succeeeded') {
        processEvent(ev).then(() => {
          res.send('success');
        });
      } else {
        console.log('Stripe Hook: ', ev.type);
        res.send('success');
      }
    } catch (e) {
      console.log(e);
      console.log(e.message);
      return res.sendStatus(401);
    }
  });
};
module.exports = routes;
