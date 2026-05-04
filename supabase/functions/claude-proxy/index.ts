import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, apikey, content-type",
      },
    })
  }

  const authHeader = req.headers.get("Authorization")
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 })
  }

  // Validate the user's Supabase JWT
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  )
  const { error } = await supabase.auth.getUser()
  if (error) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 })
  }

  // Forward request body to Anthropic
  const body = await req.text()
  let wantsStream = false
  try {
    const parsed = JSON.parse(body)
    wantsStream = parsed.stream === true
  } catch {
    wantsStream = false
  }
  const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
      "accept": wantsStream ? "text/event-stream" : "application/json",
    },
    body,
  })

  if (wantsStream && anthropicRes.body) {
    return new Response(anthropicRes.body, {
      status: anthropicRes.status,
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    })
  }

  const resBody = await anthropicRes.text()
  return new Response(resBody, {
    status: anthropicRes.status,
    headers: { "Content-Type": "application/json" },
  })
})
