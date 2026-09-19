(function() {
  function sendErrorToSupabase(message, stack) {
    if (typeof SUPABASE_URL === 'undefined' || typeof SUPABASE_ANON_KEY === 'undefined') return;
    
    let userId = null;
    try {
      // Intentar obtener el user_id si hay sesión activa en localStorage
      for (let i = 0; i < localStorage.length; i++) {
        let key = localStorage.key(i);
        if (key && key.startsWith('sb-') && key.endsWith('-auth-token')) {
          let session = JSON.parse(localStorage.getItem(key));
          if (session && session.user && session.user.id) {
            userId = session.user.id;
            break;
          }
        }
      }
    } catch(e) {}

    const payload = {
      user_id: userId,
      error_message: message || "Unknown error",
      error_stack: stack || "",
      url: window.location.href,
      user_agent: navigator.userAgent
    };

    fetch(`${SUPABASE_URL}/rest/v1/system_logs`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
      },
      body: JSON.stringify(payload)
    }).catch(err => {
        // Falló el envío del error
    });
  }

  window.addEventListener('error', function(event) {
    sendErrorToSupabase(event.message, event.error ? event.error.stack : '');
  });

  window.addEventListener('unhandledrejection', function(event) {
    let msg = event.reason;
    let stack = '';
    if (event.reason instanceof Error) {
        msg = event.reason.message;
        stack = event.reason.stack;
    } else if (typeof event.reason === 'object') {
        msg = JSON.stringify(event.reason);
    }
    sendErrorToSupabase("Promesa rechazada: " + msg, stack);
  });
})();
