const AfricasTalking = require('africastalking');

let _sms = null;

function getSms() {
  if (!_sms) {
    const at = AfricasTalking({
      apiKey: process.env.AT_API_KEY,
      username: process.env.AT_USERNAME,
    });
    _sms = at.SMS;
  }
  return _sms;
}

// Best-effort — never throws, never blocks the caller.
async function sendSms(phone, message) {
  if (!phone || !message) return;
  try {
    await getSms().send({ to: [phone], message });
    console.log(`[SMS] Sent to ${phone}`);
  } catch (err) {
    console.error('[SMS] Failed:', err?.message ?? err);
  }
}

module.exports = { sendSms };
