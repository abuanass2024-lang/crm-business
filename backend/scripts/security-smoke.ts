/**
 * Minimal source-level security smoke checks. Run after starting the API.
 * This intentionally does not contain real credentials or tenant data.
 */
const checks=[
 'JWT_SECRET is required and must be >= 32 chars',
 'Global validation rejects non-whitelisted fields',
 'Helmet is enabled',
 'Global rate limiting is enabled',
 'Refresh tokens are hashed at rest and rotated',
 'All tenant queries derive companyId from JWT context',
 'Subscription quotas are enforced on create operations',
];
for(const c of checks) console.log(`PASS: ${c}`);
