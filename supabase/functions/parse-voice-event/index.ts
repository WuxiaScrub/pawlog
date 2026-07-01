// Supabase Edge Function: parse-voice-event
//
// Proxies the voice transcript -> structured event JSON call to Claude Haiku
// so the Anthropic API key lives only in this function's secrets, never in
// the Flutter client. Deploy with:
//   supabase functions deploy parse-voice-event
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//
// Called from the app via `supabase.functions.invoke('parse-voice-event', ...)`,
// which forwards the caller's auth JWT — verify_jwt stays on (the default) so
// only signed-in users can reach this function.

import { createClient } from "jsr:@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_MODEL = "claude-haiku-4-5";
const MAX_TRANSCRIPT_CHARS = 500;

const SYSTEM_PROMPT = `You are a cat care logging assistant. Parse the user's voice transcript and extract one or more care events.

Return ONLY valid JSON in this format:
{
  "events": [
    {
      "event_type": "litter_scoop" | "litter_change" | "water_change" | "vomit" | "hairball" | "deworming" | "flea_treatment" | "medication" | "feeding" | "playtime" | "weight" | "note",
      "cat_name": "<name if mentioned, else null>",
      "notes": "<any additional detail mentioned>",
      "metadata": {}
    }
  ]
}

If no recognizable event is found, return: { "events": [] }
Do not include any explanation or text outside the JSON.`;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  if (!ANTHROPIC_API_KEY) {
    return new Response(
      JSON.stringify({ error: "ANTHROPIC_API_KEY is not configured" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  // Verify the caller is a signed-in PawLog user before spending API budget.
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  let transcript: string;
  try {
    const body = await req.json();
    transcript = String(body.transcript ?? "");
  } catch {
    return new Response(JSON.stringify({ error: "Invalid request body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!transcript.trim()) {
    return new Response(JSON.stringify({ events: [] }), {
      headers: { "Content-Type": "application/json" },
    });
  }
  transcript = transcript.slice(0, MAX_TRANSCRIPT_CHARS);

  const anthropicResponse = await fetch(
    "https://api.anthropic.com/v1/messages",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages: [{ role: "user", content: transcript }],
      }),
    },
  );

  if (!anthropicResponse.ok) {
    const detail = await anthropicResponse.text();
    return new Response(
      JSON.stringify({ error: "Claude API error", detail }),
      {
        status: 502,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  const completion = await anthropicResponse.json();
  const rawText: string = completion.content?.[0]?.text ?? "{}";

  let parsed: unknown;
  try {
    parsed = JSON.parse(rawText);
  } catch {
    parsed = { events: [] };
  }

  return new Response(JSON.stringify(parsed), {
    headers: { "Content-Type": "application/json" },
  });
});
