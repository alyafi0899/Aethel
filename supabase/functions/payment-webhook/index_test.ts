import { createHandler } from "./index.ts";

const secret = "test-webhook-secret";
const environment: Record<string, string> = {
  SUPABASE_URL: "https://example.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY: "server-only-test-key",
  PAYMENT_WEBHOOK_SECRET: secret,
};

const payload = {
  invoice_id: "123e4567-e89b-42d3-a456-426614174000",
  provider: "midtrans",
  provider_ref: "provider-ref-1",
  amount: 125000,
  method: "qris",
  status: "succeeded",
  idempotency_key: "event-1",
};

async function signatureFor(body: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body)),
  );
  return Array.from(signature, (byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function createRequest(body: string, signature: string): Request {
  return new Request("https://function.example/payment-webhook", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-prometheon-signature": signature,
    },
    body,
  });
}

Deno.test("rejects invalid signatures without calling the payment RPC", async () => {
  let fetchCount = 0;
  const handler = createHandler(
    (name) => environment[name],
    async () => {
      fetchCount += 1;
      return new Response(null, { status: 200 });
    },
  );
  const response = await handler(
    createRequest(JSON.stringify(payload), "0".repeat(64)),
  );

  if (response.status !== 401) {
    throw new Error("Expected an unauthorized response");
  }
  if (fetchCount !== 0) throw new Error("Invalid signature reached the RPC");
});

Deno.test("valid signatures forward the normalized event and idempotency key", async () => {
  const body = JSON.stringify(payload);
  let rpcUrl = "";
  const rpcBodies: Record<string, unknown>[] = [];
  const handler = createHandler(
    (name) => environment[name],
    async (input, init) => {
      rpcUrl = String(input);
      rpcBodies.push(JSON.parse(String(init?.body)) as Record<string, unknown>);
      return new Response(null, { status: 200 });
    },
  );
  const response = await handler(createRequest(body, await signatureFor(body)));

  if (response.status !== 200) throw new Error("Expected an accepted response");
  if (!rpcUrl.endsWith("/rpc/apply_payment_event")) {
    throw new Error("Expected the server-only payment RPC");
  }
  const rpcBody = rpcBodies[0];
  if (rpcBody?.p_idempotency_key !== payload.idempotency_key) {
    throw new Error("The idempotency key was not forwarded");
  }
  if (rpcBody?.p_amount !== payload.amount) {
    throw new Error("The amount was not forwarded");
  }
});

Deno.test("rejects signed payloads that do not match the RPC contract", async () => {
  const body = JSON.stringify({ ...payload, amount: 12.5 });
  let fetchCount = 0;
  const handler = createHandler(
    (name) => environment[name],
    async () => {
      fetchCount += 1;
      return new Response(null, { status: 200 });
    },
  );
  const response = await handler(createRequest(body, await signatureFor(body)));

  if (response.status !== 400) {
    throw new Error("Expected an invalid payload response");
  }
  if (fetchCount !== 0) throw new Error("Invalid payload reached the RPC");
});

Deno.test("rejects unsupported HTTP methods", async () => {
  const handler = createHandler((name) => environment[name]);
  const response = await handler(
    new Request("https://function.example/payment-webhook", { method: "GET" }),
  );

  if (response.status !== 405) {
    throw new Error("Expected a method-not-allowed response");
  }
});
