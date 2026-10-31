export interface SessionUser {
  id: string;
  email: string;
  timezone: string;
  locale: string;
}

/**
 * How the request was let in: the person's own session (the app or the web), or an assistant's
 * OAuth access token, which carries the client and the scopes the person granted it.
 */
export type Grant = { kind: "session" } | { kind: "oauth"; clientId: string; scopes: string[] };

export interface AppEnv {
  Variables: {
    userId: string;
    user: SessionUser;
    grant: Grant;
  };
}
