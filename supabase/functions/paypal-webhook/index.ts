import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// PayPal webhook event structure (simplified)
interface PayPalWebhookEvent {
  event_type: string;
  resource: {
    id: string;
    supplementary_data?: {
      related_ids?: {
        order_id?: string;
      }
    };
    custom_id?: string; // We will pass the Supabase order ID here when creating the PayPal order
  }
}

serve(async (req: Request) => {
  try {
    // Verificación básica de firma (en producción usar el SDK de PayPal o verificar cabeceras)
    // Para propósitos de este webhook asíncrono, verificamos que sea un POST válido.
    
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const payload: PayPalWebhookEvent = await req.json()

    // Solo nos interesa cuando un pago se ha completado
    if (payload.event_type === 'PAYMENT.CAPTURE.COMPLETED') {
      
      const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
      const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      
      const supabase = createClient(supabaseUrl, supabaseServiceKey)

      // El custom_id debe contener el ID del pedido de Supabase que enviamos al crear el pago
      const orderId = payload.resource.custom_id

      if (!orderId) {
        console.error('No custom_id found in PayPal payload')
        return new Response('Missing order ID in custom_id', { status: 400 })
      }

      // Actualizar el estado del pedido a processing/paid
      const { data, error } = await supabase
        .from('orders')
        .update({ 
          status: 'processing',
          payment_reference: payload.resource.id 
        })
        .eq('id', orderId)

      if (error) {
        console.error('Error updating order:', error)
        return new Response('Database error', { status: 500 })
      }

      console.log(`Order ${orderId} updated successfully to processing.`)
      return new Response('Webhook processed successfully', { status: 200 })
    }

    return new Response('Event type ignored', { status: 200 })

  } catch (err: any) {
    console.error('Webhook error:', err.message)
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }
})
