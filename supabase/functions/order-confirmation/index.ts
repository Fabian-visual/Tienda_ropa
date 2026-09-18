import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

serve(async (req: Request) => {
  try {
    const payload = await req.json()
    
    // Listen for UPDATE events where the order status changes to 'processing' (Payment Confirmed)
    if (payload.type === 'UPDATE' && payload.table === 'orders') {
      const oldOrder = payload.old_record
      const order = payload.record
      
      if (!RESEND_API_KEY) {
        console.log('RESEND_API_KEY not configured. Skipping email.')
        return new Response('API Key not configured', { status: 200 })
      }

      let emailHtml = '';
      let subject = '';

      if (oldOrder.status !== 'processing' && order.status === 'processing') {
        subject = `Confirmación de Pedido #${order.order_code || order.id} - OVERMARK`;
        emailHtml = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #0a0a0a; color: #fff; padding: 20px;">
            <h1 style="color: #d4af37; text-align: center;">OVERMARK STUDIO</h1>
            <h2 style="text-align: center;">¡Tu pago ha sido confirmado, ${order.customer_name}!</h2>
            <p>Hemos procesado el pago de tu pedido <strong>#${order.order_code || order.id}</strong> por <strong>$${order.total_amount}</strong> con éxito.</p>
            <hr style="border-color: #333;" />
            <p>Tu diseño está oficialmente en la fila de producción. Te notificaremos nuevamente cuando el pedido sea estampado y enviado.</p>
            <p style="text-align: center; color: #888; font-size: 12px; margin-top: 40px;">OVERMARK Studio - Venta de Ropa Premium</p>
          </div>
        `;
      } else if (oldOrder.status !== 'shipped' && order.status === 'shipped') {
        subject = `Tu Pedido #${order.order_code || order.id} está en camino 🚚 - OVERMARK`;
        emailHtml = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #0a0a0a; color: #fff; padding: 20px;">
            <h1 style="color: #d4af37; text-align: center;">OVERMARK STUDIO</h1>
            <h2 style="text-align: center;">¡Grandes noticias, ${order.customer_name}!</h2>
            <p>Tu pedido <strong>#${order.order_code || order.id}</strong> ha sido estampado, verificado en calidad y acaba de ser entregado a la agencia de envíos.</p>
            <hr style="border-color: #333;" />
            <p>¡Pronto tendrás tu prenda exclusiva en tus manos! Recuerda que puedes contactarnos si tienes alguna duda con tu envío.</p>
            <p style="text-align: center; color: #888; font-size: 12px; margin-top: 40px;">OVERMARK Studio - Venta de Ropa Premium</p>
          </div>
        `;
      } else {
        return new Response('Status unchanged or ignored', { status: 200 })
      }

      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${RESEND_API_KEY}`
        },
        body: JSON.stringify({
          from: 'onboarding@resend.dev',
          to: [order.customer_email],
          subject: subject,
          html: emailHtml
        })
      })

      if (res.ok) {
        console.log(`Email sent successfully to ${order.customer_email}`)
        return new Response('Email sent', { status: 200 })
      } else {
        const err = await res.text()
        console.error('Failed to send email:', err)
        return new Response('Resend Error: ' + err, { status: 500 })
      }
    }


    return new Response('Ignored event', { status: 200 })
  } catch (error: any) {
    console.error('Error handling webhook:', error)
    return new Response('Internal Server Error', { status: 500 })
  }
})
