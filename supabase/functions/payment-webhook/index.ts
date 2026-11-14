const encoder = new TextEncoder();
const maxBodyBytes = 32_768;
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const providers = new Set(["midtrans", "xendit", "other"]);
const statuses = new Set(["pending", "succeeded", "failed"]);
const methods = new Set([
  "cash",
  "bank_transfer",
  "debit_card",
  "credit_card",
  "qris",
  "ewallet",
  "bpjs",
  "insurance",
]);

function response(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join(
    "",
  );
}

function decodeHex(value: string): Uint8Array | null {
  if (!/^[0-9a-f]{64}$/i.test(value)) return null;
  const bytes = new Uint8Array(32);
  for (let index = 0; index < bytes.length; index += 1) {
    bytes[index] = Number.parseInt(value.slice(index * 2, index * 2 + 2), 16);
  }
  return bytes;
}

function constantTimeEqual(left: Uint8Array, right: Uint8Array): boolean {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference === 0;
}

async function verifySignature(
  body: string,
  signature: string,
  secret: string,
) {
  const supplied = decodeHex(signature);
  if (supplied == null) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signed = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, encoder.encode(body)),
  );
  return constantTimeEqual(signed, supplied);
}

type EnvironmentReader = (name: string) => string | undefined;

export function createHandler(
  readEnvironment: EnvironmentReader = (name) => Deno.env.get(name),
  fetcher: typeof fetch = fetch,
): (request: Request) => Promise<Response> {
  return async (request) => {
    if (request.method !== "POST") return response(405, "method_not_allowed");
    if (!request.headers.get("content-type")?.includes("application/json")) {
      return response(415, "application_json_required");
    }
    const declaredSize = Number(request.headers.get("content-length") ?? 0);
    if (declaredSize > maxBodyBytes) return response(413, "payload_too_large");

    const supabaseUrl = readEnvironment("SUPABASE_URL");
    const serviceRoleKey = readEnvironment("SUPABASE_SERVICE_ROLE_KEY");
    const webhookSecret = readEnvironment("PAYMENT_WEBHOOK_SECRET");
    if (!supabaseUrl || !serviceRoleKey || !webhookSecret) {
      return response(503, "webhook_not_configured");
    }

    const rawBody = await request.text();
    if (encoder.encode(rawBody).length > maxBodyBytes) {
      return response(413, "payload_too_large");
    }
    const signature = request.headers.get("x-prometheon-signature") ?? "";
    if (!(await verifySignature(rawBody, signature, webhookSecret))) {
      return response(401, "invalid_signature");
    }

    let payload: Record<string, unknown>;
    try {
      const parsed: unknown = JSON.parse(rawBody);
      if (
        parsed == null || typeof parsed !== "object" || Array.isArray(parsed)
      ) {
        return response(400, "invalid_payload");
      }
      payload = parsed as Record<string, unknown>;
    } catch {
      return response(400, "invalid_payload");
    }

    const invoiceId = payload.invoice_id;
    const provider = payload.provider;
    const providerRef = payload.provider_ref;
    const amount = payload.amount;
    const method = payload.method;
    const status = payload.status;
    const idempotencyKey = payload.idempotency_key;

    if (
      typeof invoiceId !== "string" ||
      !uuidPattern.test(invoiceId) ||
      typeof provider !== "string" ||
      !providers.has(provider) ||
      typeof providerRef !== "string" ||
      providerRef.length < 1 ||
      providerRef.length > 300 ||
      typeof amount !== "number" ||
      !Number.isSafeInteger(amount) ||
      amount <= 0 ||
      typeof method !== "string" ||
      !methods.has(method) ||
      typeof status !== "string" ||
      !statuses.has(status) ||
      typeof idempotencyKey !== "string" ||
      idempotencyKey.length < 1 ||
      idempotencyKey.length > 200
    ) {
      return response(400, "invalid_payload");
    }

    let rpcResponse: Response;
    try {
      rpcResponse = await fetcher(
        `${supabaseUrl.replace(/\/+$/, "")}/rest/v1/rpc/apply_payment_event`,
        {
          method: "POST",
          headers: {
            apikey: serviceRoleKey,
            authorization: `Bearer ${serviceRoleKey}`,
            "content-type": "application/json",
          },
          body: JSON.stringify({
            p_invoice_id: invoiceId,
            p_provider: provider,
            p_provider_ref: providerRef,
            p_amount: amount,
            p_method: method,
            p_status: status,
            p_idempotency_key: idempotencyKey,
          }),
        },
      );
    } catch {
      return response(502, "payment_processing_unavailable");
    }

    if (!rpcResponse.ok) {
      return response(422, "payment_event_rejected");
    }
    return new Response(JSON.stringify({ accepted: true }), {
      status: 200,
      headers: { "content-type": "application/json; charset=utf-8" },
    });
  };
}

if (import.meta.main) Deno.serve(createHandler());
