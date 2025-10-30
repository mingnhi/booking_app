import * as paypal from '@paypal/checkout-server-sdk';
import * as dotenv from 'dotenv';
dotenv.config();

function environment() {
  const clientId = process.env.PAYPAL_CLIENT_ID;
  const clientSecret = process.env.PAYPAL_CLIENT_SECRET;
  return new paypal.core.SandboxEnvironment(clientId, clientSecret); // dùng Sandbox
}

export function paypalClient() {
  return new paypal.core.PayPalHttpClient(environment());
}
