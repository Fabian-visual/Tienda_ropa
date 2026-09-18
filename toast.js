
// Sistema de notificaciones (toasts) que creé para dar feedback al usuario (ej. "Producto añadido")
function showToast(message, type = 'success') {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    Object.assign(container.style, {
      position: 'fixed',
      bottom: '20px',
      right: '20px',
      display: 'flex',
      flexDirection: 'column',
      gap: '10px',
      zIndex: '99999'
    });
    document.body.appendChild(container);
  }

  const toast = document.createElement('div');
  const bgColor = type === 'success' ? '#27AE60' : (type === 'error' ? '#C0392B' : '#C8A96E');
  
  Object.assign(toast.style, {
    background: '#1E1E1E',
    color: '#E0E0E0',
    padding: '12px 20px',
    borderRadius: '8px',
    borderLeft: `4px solid ${bgColor}`,
    boxShadow: '0 4px 12px rgba(0,0,0,0.5)',
    fontFamily: "'Inter', sans-serif",
    fontSize: '0.9rem',
    fontWeight: '500',
    opacity: '0',
    transform: 'translateY(20px)',
    transition: 'all 0.3s cubic-bezier(0.68, -0.55, 0.265, 1.55)',
    display: 'flex',
    alignItems: 'center',
    gap: '10px'
  });

  const icon = type === 'success' ? '✓' : (type === 'error' ? '✕' : 'ℹ');
  toast.innerHTML = `<span style="color: ${bgColor}; font-weight: bold; font-size: 1.1rem;">${icon}</span> ${message}`;
  
  container.appendChild(toast);

  requestAnimationFrame(() => {
    toast.style.opacity = '1';
    toast.style.transform = 'translateY(0)';
  });

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(20px)';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}
