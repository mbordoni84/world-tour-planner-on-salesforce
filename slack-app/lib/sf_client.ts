import type { SlackAPIClient } from "deno-slack-api/types.ts";

const DEFAULT_INSTANCE_URL = "https://storm-973b1cdf0acdf3.my.salesforce.com";

async function getAccessToken(
  client: SlackAPIClient,
  externalTokenId: string,
  forceRefresh = false,
): Promise<string | null> {
  const resp = await client.apps.auth.external.get({
    external_token_id: externalTokenId,
    force_refresh: forceRefresh,
  });

  if (!resp.ok || !resp.external_token) {
    return null;
  }

  return resp.external_token;
}

export async function sfFetch(
  client: SlackAPIClient,
  externalTokenId: string,
  path: string,
  options: RequestInit = {},
): Promise<{
  ok: boolean;
  status: number;
  data: Record<string, unknown> | Record<string, unknown>[];
}> {
  const accessToken = await getAccessToken(client, externalTokenId);
  if (!accessToken) {
    return {
      ok: false,
      status: 401,
      data: { error: "Not authenticated with Salesforce" },
    };
  }

  const instanceUrl = DEFAULT_INSTANCE_URL;

  let resp = await fetch(
    `${instanceUrl}/services/apexrest${path}`,
    {
      ...options,
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        ...options.headers,
      },
    },
  );

  if (resp.status === 401) {
    const refreshed = await getAccessToken(client, externalTokenId, true);
    if (!refreshed) {
      return {
        ok: false,
        status: 401,
        data: { error: "Token refresh failed" },
      };
    }

    resp = await fetch(
      `${instanceUrl}/services/apexrest${path}`,
      {
        ...options,
        headers: {
          "Authorization": `Bearer ${refreshed}`,
          "Content-Type": "application/json",
          ...options.headers,
        },
      },
    );
  }

  const data = await resp.json();
  return { ok: resp.ok, status: resp.status, data };
}
