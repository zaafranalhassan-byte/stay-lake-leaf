ALTER TABLE public.bookings
  ALTER COLUMN check_in TYPE timestamptz USING check_in::timestamptz,
  ALTER COLUMN check_out TYPE timestamptz USING check_out::timestamptz;

DROP FUNCTION IF EXISTS public.get_reserved_ranges();
CREATE OR REPLACE FUNCTION public.get_reserved_ranges()
RETURNS TABLE(check_in timestamptz, check_out timestamptz)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT check_in, check_out FROM public.bookings
  WHERE status IN ('new','contacted','confirmed') AND check_out >= now();
$function$;