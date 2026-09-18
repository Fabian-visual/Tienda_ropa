-- Aquí creo las tablas principales para almacenar la información de mi aplicación
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  role VARCHAR(50) DEFAULT 'client',
  full_name VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Modifico la estructura o habilito las políticas de seguridad (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Public profiles are viewable by admin" ON public.profiles FOR SELECT USING (auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);


CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    CASE WHEN NEW.email = 'fabianvasquezp13@gmail.com' THEN 'admin' ELSE 'client' END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Aquí creo las tablas principales para almacenar la información de mi aplicación
CREATE TABLE IF NOT EXISTS public.orders (
    
    id              SERIAL          PRIMARY KEY,
    user_id         UUID            REFERENCES auth.users(id) ON DELETE CASCADE,
    
    customer_name   VARCHAR(255),
    customer_email  VARCHAR(255),
    
    items           JSONB           NOT NULL DEFAULT '[]'::jsonb,

    total_amount    DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    payment_method  VARCHAR(50)     NOT NULL,
    payment_reference VARCHAR(255),

    status          VARCHAR(20)     NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'processing', 'shipped', 'completed', 'cancelled', 'refunded')),
    refund_requested BOOLEAN        NOT NULL DEFAULT FALSE,
    refund_reason   TEXT,
    refund_proof_url VARCHAR(500),
    shipping_proof_url VARCHAR(500),
    
    order_code      VARCHAR(20),

    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Modifico la estructura o habilito las políticas de seguridad (RLS)
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can insert their own orders" ON public.orders FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can view their own orders" ON public.orders FOR SELECT TO authenticated USING (auth.uid() = user_id);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can view all orders" ON public.orders FOR SELECT TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can update all orders" ON public.orders FOR UPDATE TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');

INSERT INTO storage.buckets (id, name, public) 
VALUES ('orders_images', 'orders_images', true)
ON CONFLICT (id) DO NOTHING;



-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can upload images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'orders_images' AND auth.uid() = owner);


-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can view their own images"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'orders_images' AND auth.uid() = owner);


-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can view all images"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'orders_images' AND auth.email() = 'fabianvasquezp13@gmail.com');




-- Aquí creo las tablas principales para almacenar la información de mi aplicación
CREATE TABLE IF NOT EXISTS public.categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Modifico la estructura o habilito las políticas de seguridad (RLS)
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Categories are viewable by everyone" ON public.categories FOR SELECT USING (true);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can insert categories" ON public.categories FOR INSERT TO authenticated WITH CHECK (auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can update categories" ON public.categories FOR UPDATE TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can delete categories" ON public.categories FOR DELETE TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');




-- Aquí creo las tablas principales para almacenar la información de mi aplicación
CREATE TABLE IF NOT EXISTS public.system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Modifico la estructura o habilito las políticas de seguridad (RLS)
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Everyone can read settings" ON public.system_settings FOR SELECT USING (true);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can modify settings" ON public.system_settings FOR ALL TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');

INSERT INTO public.system_settings (key, value) VALUES ('bcv_rate', '{"rate": 42.50}') ON CONFLICT (key) DO NOTHING;




-- Aquí creo las tablas principales para almacenar la información de mi aplicación
CREATE TABLE IF NOT EXISTS public.products (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES public.categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    stock INTEGER NOT NULL DEFAULT 0,
    image_url VARCHAR(500),
    has_3d_support BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- Modifico la estructura o habilito las políticas de seguridad (RLS)
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;


-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Products are viewable by everyone" ON public.products FOR SELECT USING (true);


-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can insert products" ON public.products FOR INSERT TO authenticated WITH CHECK (auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can update products" ON public.products FOR UPDATE TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can delete products" ON public.products FOR DELETE TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');




INSERT INTO storage.buckets (id, name, public) VALUES ('catalog_images', 'catalog_images', true) ON CONFLICT (id) DO NOTHING;

-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can upload catalog images" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'catalog_images' AND auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can update catalog images" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'catalog_images' AND auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can delete catalog images" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'catalog_images' AND auth.email() = 'fabianvasquezp13@gmail.com');


DROP POLICY IF EXISTS "Everyone can view catalog images" ON storage.objects;
DROP POLICY IF EXISTS "Everyone can view 3d_models" ON storage.objects;




-- Aquí creo las tablas principales para almacenar la información de mi aplicación
CREATE TABLE IF NOT EXISTS public.product_variants (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    sku VARCHAR(100),
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    stock INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Modifico la estructura o habilito las políticas de seguridad (RLS)
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Variants are viewable by everyone" ON public.product_variants FOR SELECT USING (true);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can insert variants" ON public.product_variants FOR INSERT TO authenticated WITH CHECK (auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can update variants" ON public.product_variants FOR UPDATE TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can delete variants" ON public.product_variants FOR DELETE TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');




-- Aquí creo las tablas principales para almacenar la información de mi aplicación
CREATE TABLE IF NOT EXISTS public.discounts (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('percentage', 'fixed')),
    value DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    usage_limit INTEGER,
    usage_count INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Modifico la estructura o habilito las políticas de seguridad (RLS)
ALTER TABLE public.discounts ENABLE ROW LEVEL SECURITY;
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can manage discounts" ON public.discounts FOR ALL TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Everyone can read discounts" ON public.discounts FOR SELECT USING (true);




-- Aquí creo las tablas principales para almacenar la información de mi aplicación
CREATE TABLE IF NOT EXISTS public.favorites (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
    custom_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- Modifico la estructura o habilito las políticas de seguridad (RLS)
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can manage their own favorites" ON public.favorites 
FOR ALL TO authenticated USING (auth.uid() = user_id);

-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can view all favorites" ON public.favorites 
FOR SELECT TO authenticated USING (auth.email() = 'fabianvasquezp13@gmail.com');




CREATE OR REPLACE FUNCTION public.create_order(
    p_items jsonb,
    p_payment_method character varying,
    p_payment_reference character varying,
    p_customer_name character varying,
    p_customer_email character varying,
    p_payment_receipt_url character varying DEFAULT NULL::character varying
) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path = public -- Agregué el search_path para cumplir con los estándares de seguridad y evitar inyecciones de ruta
    AS $$
DECLARE
    item JSONB;
    v_total_amount DECIMAL(10,2) := 0.00;
    v_item_price DECIMAL(10,2);
    v_product_id INTEGER;
    v_quantity INTEGER;
    v_order_id INTEGER;
    v_order_code VARCHAR(20);
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    
    v_order_code := 'OVM-' || upper(substring(md5(random()::text), 1, 5));

    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (item->>'product_id')::INTEGER;
        v_quantity := COALESCE((item->>'quantity')::INTEGER, 1);
        
        SELECT price INTO v_item_price FROM public.products WHERE id = v_product_id FOR UPDATE;
        
        IF v_item_price IS NULL THEN
            RAISE EXCEPTION 'Producto con ID % no encontrado', v_product_id;
        END IF;

        UPDATE public.products 
        SET stock = stock - v_quantity 
        WHERE id = v_product_id AND stock >= v_quantity;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No hay stock suficiente para el producto ID %', v_product_id;
        END IF;

        v_total_amount := v_total_amount + (v_item_price * v_quantity);
    END LOOP;

    INSERT INTO public.orders (
        user_id,
        customer_name,
        customer_email,
        items,
        total_amount,
        payment_method,
        payment_reference,
        payment_receipt_url,
        status,
        order_code
    ) VALUES (
        auth.uid(),
        p_customer_name,
        p_customer_email,
        p_items,
        v_total_amount,
        p_payment_method,
        p_payment_reference,
        p_payment_receipt_url,
        'pending',
        v_order_code
    ) RETURNING id INTO v_order_id;

    RETURN jsonb_build_object('id', v_order_id, 'order_code', v_order_code, 'total_amount', v_total_amount);
END;
$$;





INSERT INTO storage.buckets (id, name, public) VALUES ('payment_receipts', 'payment_receipts', false) ON CONFLICT (id) DO UPDATE SET public = false;
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can upload receipts" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'payment_receipts' AND auth.uid() = owner);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can view their own receipts" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'payment_receipts' AND auth.uid() = owner);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can view all receipts" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'payment_receipts' AND auth.email() = 'fabianvasquezp13@gmail.com');


INSERT INTO storage.buckets (id, name, public) VALUES ('user_designs', 'user_designs', false) ON CONFLICT (id) DO UPDATE SET public = false;
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can upload designs" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'user_designs' AND auth.uid() = owner);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can view all designs" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'user_designs' AND auth.email() = 'fabianvasquezp13@gmail.com');


INSERT INTO storage.buckets (id, name, public) VALUES ('shipping_proofs', 'shipping_proofs', false) ON CONFLICT (id) DO UPDATE SET public = false;
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can upload shipping proofs" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'shipping_proofs' AND auth.email() = 'fabianvasquezp13@gmail.com');
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Users can view their own shipping proofs" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'shipping_proofs' AND auth.uid() = owner);
-- Defino políticas de seguridad estrictas para que nadie pueda ver datos que no le pertenecen
CREATE POLICY "Admin can view all shipping proofs" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'shipping_proofs' AND auth.email() = 'fabianvasquezp13@gmail.com');







CREATE OR REPLACE FUNCTION public.request_refund(
    p_order_id INTEGER,
    p_reason TEXT,
    p_proof_url text
) RETURNS void
    LANGUAGE plpgsql
    SET search_path = public -- Apliqué el search_path para evitar warnings de seguridad en Supabase
    AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    UPDATE public.orders
    SET 
        refund_requested = true,
        refund_reason = p_reason,
        refund_proof_url = p_proof_url
    WHERE id = p_order_id AND user_id = auth.uid();
END;
$$;

-- Restringí el acceso a la función de reembolso solo a usuarios que hayan iniciado sesión
REVOKE EXECUTE ON FUNCTION public.request_refund(integer, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_refund(integer, text, text) TO authenticated;


REVOKE EXECUTE ON FUNCTION public.request_refund(INTEGER, TEXT, TEXT) FROM public;
REVOKE EXECUTE ON FUNCTION public.request_refund(INTEGER, TEXT, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.request_refund(INTEGER, TEXT, TEXT) TO authenticated;


CREATE OR REPLACE FUNCTION public.create_order(
    p_items JSONB,
    p_payment_method VARCHAR,
    p_payment_reference VARCHAR,
    p_customer_name VARCHAR,
    p_customer_email VARCHAR,
    p_payment_receipt_url VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    item JSONB;
    v_total_amount DECIMAL(10,2) := 0.00;
    v_item_price DECIMAL(10,2);
    v_product_id INTEGER;
    v_quantity INTEGER;
    v_order_id INTEGER;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (item->>'product_id')::INTEGER;
        v_quantity := COALESCE((item->>'quantity')::INTEGER, 1);
        
        SELECT price INTO v_item_price FROM public.products WHERE id = v_product_id FOR UPDATE;
        
        IF v_item_price IS NULL THEN
            RAISE EXCEPTION 'Producto con ID % no encontrado', v_product_id;
        END IF;

        
        UPDATE public.products 
        SET stock = stock - v_quantity 
        WHERE id = v_product_id AND stock >= v_quantity;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No hay stock suficiente para el producto ID %', v_product_id;
        END IF;

        v_total_amount := v_total_amount + (v_item_price * v_quantity);
    END LOOP;

    INSERT INTO public.orders (
        user_id,
        customer_name,
        customer_email,
        items,
        total_amount,
        payment_method,
        payment_reference,
        payment_receipt_url,
        status
    ) VALUES (
        auth.uid(),
        p_customer_name,
        p_customer_email,
        p_items,
        v_total_amount,
        p_payment_method,
        p_payment_reference,
        p_payment_receipt_url,
        'pending'
    ) RETURNING id INTO v_order_id;

    RETURN jsonb_build_object('id', v_order_id, 'total_amount', v_total_amount);
END;
$$;


REVOKE EXECUTE ON FUNCTION public.create_order(JSONB, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) FROM public;
REVOKE EXECUTE ON FUNCTION public.create_order(JSONB, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_order(JSONB, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO authenticated;

