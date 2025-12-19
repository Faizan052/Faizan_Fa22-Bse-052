import { serve } from 'https://deno.land/std/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { id } = await req.json()

  const supabaseAdmin = createClient(
    Deno.env.get('https://emoevufpoeuqfychejgl.supabase.co')!,
    Deno.env.get('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtb2V2dWZwb2V1cWZ5Y2hlamdsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1NjQ4MTEsImV4cCI6MjA2MzE0MDgxMX0.RkmXgnC4zCogZFI5l8pJONd7TYJZxoTRJsujiGM6FuA')!
  )

  const { error } = await supabaseAdmin.auth.admin.deleteUser(id)
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    })
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
  })
})
