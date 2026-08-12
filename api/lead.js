// PCS Lending — lead notify (Resend). Leads are stored by the site's Supabase insert;
// this endpoint sends the team an email on every lead. Degrades gracefully: no key = no send.
export default async function handler(req, res) {
  const origin = req.headers.origin || '';
  const allow = /pcstaxservice\.com$|vercel\.app$/.test(origin) ? origin : 'https://lending.pcstaxservice.com';
  res.setHeader('Access-Control-Allow-Origin', allow);
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method not allowed' });

  const b = (req.body && typeof req.body === 'object') ? req.body : JSON.parse(req.body || '{}');
  const name = [b.firstName, b.lastName].filter(Boolean).join(' ') || '(no name)';

  // Recipients: the notify toggle list (notify_recipients, via service role) if wired,
  // else the LEAD_EMAIL_TO env fallback (defaults to the owner).
  let to = [];
  const svc = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const url = process.env.SUPABASE_URL || 'https://gcrzmiwgjvuujffbqjbq.supabase.co';
  if (svc) {
    try {
      const r = await fetch(url + '/rest/v1/notify_recipients?select=email&enabled=eq.true&site=eq.private-lending', { headers: { apikey: svc, Authorization: 'Bearer ' + svc } });
      if (r.ok) to = (await r.json()).map(x => x.email).filter(Boolean);
    } catch (e) { /* fall through to env */ }
  }
  if (!to.length && process.env.LEAD_EMAIL_TO) to = process.env.LEAD_EMAIL_TO.split(',').map(s => s.trim()).filter(Boolean);

  let emailed = false;
  const key = process.env.RESEND_API_KEY;
  const from = process.env.LEAD_EMAIL_FROM || 'leads@pcstaxservice.com';
  if (key && to.length) {
    const text = [
      'New PCS Lending lead', '',
      'Name:      ' + name,
      'Phone:     ' + (b.phone || ''),
      'Email:     ' + (b.email || ''),
      'Loan type: ' + (b.loanType || ''),
      'Has prop:  ' + (b.hasProperty || ''),
      'Prop type: ' + (b.propertyType || ''),
      'Price:     ' + (b.purchasePrice || ''),
      'Credit:    ' + (b.creditScore || ''),
      'Referred:  ' + (b.referredBy || '—'),
      'Submitted: ' + (b.submittedAt || new Date().toISOString())
    ].join('\n');
    try {
      const r = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + key },
        body: JSON.stringify({
          from: 'PCS Lending <' + from + '>',
          to,
          reply_to: b.email || undefined,
          subject: 'New Lending Lead: ' + name + (b.loanType ? (' — ' + b.loanType) : ''),
          text
        })
      });
      emailed = r.ok;
    } catch (e) { /* email best-effort */ }
  }
  return res.status(200).json({ success: true, emailed, notified: to.length });
}
