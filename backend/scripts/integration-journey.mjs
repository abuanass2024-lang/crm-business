const base = (process.env.API_BASE_URL || 'http://localhost:3000/api').replace(/\/$/, '');
const stamp = Date.now();

async function call(method, path, body, token) {
  const res = await fetch(`${base}${path}`, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let data; try { data = text ? JSON.parse(text) : {}; } catch { data = { raw: text }; }
  return { status: res.status, data };
}
function assert(ok, msg) { if (!ok) throw new Error(`FAIL: ${msg}`); console.log(`PASS: ${msg}`); }

const h = await call('GET', '/health');
assert(h.status === 200 && h.data.ok === true && h.data.database === 'ok', 'health + database');

const aEmail = `qa_a_${stamp}@example.com`;
const bEmail = `qa_b_${stamp}@example.com`;
const password = 'TestPassword!2026';
const aReg = await call('POST', '/auth/register-company', { companyName: `QA Company A ${stamp}`, ownerName: 'QA Owner A', email: aEmail, password });
assert(aReg.status === 201 && aReg.data.accessToken && aReg.data.refreshToken, 'register company A');
const aToken = aReg.data.accessToken;
const me = await call('GET', '/auth/me', undefined, aToken);
assert(me.status === 200 && me.data.company?.id === aReg.data.company.id, 'auth me');

const c = await call('POST', '/customers', { name: 'QA Customer A', companyName: 'QA Client', email: `customer_${stamp}@example.com` }, aToken);
assert(c.status === 201 && c.data.id, 'create customer');
const customerId = c.data.id;

const opp = await call('POST', '/opportunities', { customerId, title: 'QA Opportunity', value: 10000, currency: 'USD', probability: 50 }, aToken);
assert(opp.status === 201 && opp.data.id, 'create opportunity');

const task = await call('POST', '/tasks', { title: 'QA Follow-up', customerId, priority: 'HIGH' }, aToken);
assert(task.status === 201 && task.data.id, 'create task');

const dash = await call('GET', '/dashboard', undefined, aToken);
assert(dash.status === 200 && dash.data.customers >= 1 && dash.data.openOpportunities >= 1, 'dashboard reflects data');

const pipe = await call('GET', '/opportunities/pipeline', undefined, aToken);
assert(pipe.status === 200 && Number(pipe.data.pipelineValue) >= 10000, 'pipeline reflects opportunity');

const analytics = await call('GET', '/analytics/dashboard', undefined, aToken);
assert(analytics.status === 200, 'analytics dashboard');

const sub = await call('GET', '/subscriptions/current', undefined, aToken);
assert(sub.status === 200, 'subscription current');

const bReg = await call('POST', '/auth/register-company', { companyName: `QA Company B ${stamp}`, ownerName: 'QA Owner B', email: bEmail, password });
assert(bReg.status === 201 && bReg.data.accessToken, 'register company B');
const bToken = bReg.data.accessToken;
const cross = await call('GET', `/customers/${customerId}`, undefined, bToken);
assert(cross.status === 404 || cross.status === 403, 'cross-tenant customer access blocked');

const refresh = await call('POST', '/auth/refresh', { refreshToken: aReg.data.refreshToken });
assert(refresh.status === 201 && refresh.data.accessToken && refresh.data.refreshToken, 'refresh token rotation');

console.log('\nINTEGRATION JOURNEY: PASS');
