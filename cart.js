

const CART_KEY = 'overmark_cart';





function getCart() {
  const cart = localStorage.getItem(CART_KEY);
  return cart ? JSON.parse(cart) : [];
}


function saveCart(cart) {
  localStorage.setItem(CART_KEY, JSON.stringify(cart));
  updateCartBadge();
}


// Esta es mi función principal para añadir productos al carrito y validar la data
async function addToCart(productId, name, price, imageUrl) {
  if (typeof supabaseClient !== 'undefined' && supabaseClient) {
    const { data: { session } } = await supabaseClient.auth.getSession();
    if (!session) {
      if (typeof showToast === 'function') showToast("Debes iniciar sesión para añadir productos", "error");
      if (typeof openModal === 'function') openModal('login');
      return;
    }

    // Validar el stock antes de meterlo al carrito
    const { data: product, error } = await supabaseClient.from('products').select('stock').eq('id', productId).single();
    if (!error && product) {
       const cart = getCart();
       const existingItem = cart.find(item => item.product_id === productId && item.type === 'regular');
       const currentQty = existingItem ? existingItem.quantity : 0;
       
       if (currentQty + 1 > product.stock) {
           if (typeof showToast === 'function') {
               showToast(`No puedes añadir más. Solo quedan ${product.stock} unidades de este producto.`, "error");
           }
           return; // Bloquea la acción
       }
    }
  }

  const cart = getCart();
  const existingItem = cart.find(item => item.product_id === productId && item.type === 'regular');

  if (existingItem) {
    existingItem.quantity += 1;
  } else {
    cart.push({
      id: Date.now().toString(),
      type: 'regular',
      product_id: productId,
      name: name,
      price: parseFloat(price),
      quantity: 1,
      image: imageUrl
    });
  }
  
  saveCart(cart);
  showToast("Producto añadido al carrito", "success");
}


async function addCustomToCart(customProductData) {
  if (typeof supabaseClient !== 'undefined' && supabaseClient) {
    const { data: { session } } = await supabaseClient.auth.getSession();
    if (!session) {
      if (typeof showToast === 'function') showToast("Debes iniciar sesión para añadir productos", "error");
      if (typeof openModal === 'function') openModal('login');
      return;
    }
  }

  const cart = getCart();
  cart.push({
    id: Date.now().toString(),
    type: 'custom',
    ...customProductData,
    quantity: customProductData.quantity || 1
  });
  saveCart(cart);
  showToast("Prenda personalizada añadida al carrito", "success");
  setTimeout(() => window.location.href = 'index.html', 300);
}


function removeFromCart(itemId) {
  // Inicializo el carrito leyendo el localStorage por si el usuario ya tenía cosas guardadas
let cart = getCart();
  cart = cart.filter(item => item.id !== itemId);
  saveCart(cart);
  
  
  if (window.renderCheckout) {
    window.renderCheckout();
  }
}


async function updateCartItemQuantity(itemId, newQuantity) {
  if (newQuantity < 1) return; 
  
  const cart = getCart();
  const item = cart.find(i => i.id === itemId);
  
  if (item) {
    // Validar el stock antes de incrementar
    if (typeof supabaseClient !== 'undefined' && supabaseClient && item.type === 'regular') {
      const { data: product, error } = await supabaseClient.from('products').select('stock').eq('id', item.product_id).single();
      if (!error && product) {
         if (newQuantity > product.stock) {
             if (typeof showToast === 'function') {
                 showToast(`Límite alcanzado: Solo hay ${product.stock} unidades en inventario.`, "error");
             }
             return; // Bloquea la acción
         }
      }
    }

    item.quantity = newQuantity;
    saveCart(cart);
    if (window.renderCheckout) {
      window.renderCheckout();
    }
  }
}


function getCartTotal() {
  const cart = getCart();
  return cart.reduce((total, item) => total + (item.price * item.quantity), 0);
}


function updateCartBadge() {
  const badge = document.getElementById('cartBadge');
  if (badge) {
    const cart = getCart();
    const count = cart.reduce((acc, item) => acc + item.quantity, 0);
    badge.textContent = count;
    badge.style.display = count > 0 ? 'inline-flex' : 'none';
  }
}


function clearCart() {
  localStorage.removeItem(CART_KEY);
  updateCartBadge();
}

window.addEventListener('DOMContentLoaded', updateCartBadge);

