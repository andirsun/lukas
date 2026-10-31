import {
  type ConsentProblem,
  consentProblemFrom,
  type PublicClient,
  publicClientFrom,
} from "./consent-model.ts";

/** Better Auth lives at /api/auth (auth/auth-client.ts). */
const AUTH_BASE = "/api/auth";

/** A refusal, already read into what the consent screen says about it. */
export class ConsentError extends Error {
  readonly problem: ConsentProblem;
  constructor(problem: ConsentProblem) {
    super(problem);
    this.name = "ConsentError";
    this.problem = problem;
  }
}

/** What the consent screen asks of Better Auth, as a prop so stories can stand in for it. */
export interface ConsentApi {
  /** The assistant's name, logo and domain; throws a `ConsentError`. */
  client(clientId: string): Promise<PublicClient>;
  /**
   * Answers the request: `oauthQuery` is the page's signed query (without `?`). Resolves to where
   * the browser goes next (the assistant's redirect_uri, with a code or `access_denied`); throws
   * a `ConsentError`.
   */
  decide(accept: boolean, oauthQuery: string): Promise<string>;
}

async function bodyOf(response: Response): Promise<unknown> {
  try {
    return await response.json();
  } catch {
    return undefined;
  }
}

/** Better Auth's oauth-provider endpoints, through `fetchImpl` (the browser's by default). */
export function createConsentApi(
  fetchImpl: typeof fetch = (...args) => fetch(...args),
): ConsentApi {
  const call = async (input: string, init?: RequestInit): Promise<unknown> => {
    let response: Response;
    try {
      response = await fetchImpl(input, { credentials: "include", ...init });
    } catch {
      throw new ConsentError("network");
    }
    const body = await bodyOf(response);
    if (!response.ok) throw new ConsentError(consentProblemFrom(response.status, body));
    return body;
  };

  return {
    client: async (clientId) => {
      const query = new URLSearchParams({ client_id: clientId });
      return publicClientFrom(clientId, await call(`${AUTH_BASE}/oauth2/public-client?${query}`));
    },
    decide: async (accept, oauthQuery) => {
      const body = await call(`${AUTH_BASE}/oauth2/consent`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ accept, oauth_query: oauthQuery }),
      });
      const url = (body as { url?: unknown } | undefined)?.url;
      if (typeof url !== "string" || !url) throw new ConsentError("generic");
      return url;
    },
  };
}

export const liveConsentApi = createConsentApi();
