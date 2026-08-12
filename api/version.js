// #9 no-stale-cache: returns a value that is unique per deploy so open tabs get a refresh nudge.
export default function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).send(process.env.VERCEL_DEPLOYMENT_ID || process.env.VERCEL_GIT_COMMIT_SHA || process.env.VERCEL_URL || 'dev');
}
