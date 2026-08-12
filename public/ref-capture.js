// #15 referral capture — reads ?ref=NAME on arrival, stores first-touch, exposes window.pcsRef().
(function () {
  try {
    var r = new URLSearchParams(location.search).get('ref');
    if (r && !localStorage.getItem('pcslend_ref')) localStorage.setItem('pcslend_ref', r.slice(0, 80));
  } catch (e) {}
  window.pcsRef = function () { try { return localStorage.getItem('pcslend_ref') || ''; } catch (e) { return ''; } };
})();
