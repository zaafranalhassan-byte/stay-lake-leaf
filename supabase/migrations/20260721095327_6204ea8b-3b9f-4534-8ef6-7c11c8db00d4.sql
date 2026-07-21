
CREATE POLICY "bookings authenticated insert" ON public.bookings FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "bookings authenticated update" ON public.bookings FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
