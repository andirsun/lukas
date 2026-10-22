import { passkeyClient } from "@better-auth/passkey/client";
import { emailOTPClient } from "better-auth/client/plugins";
import { createAuthClient } from "better-auth/react";

/** Better Auth lives at /api/auth, next to the rest of the API (see api/client.ts). */
export const authClient = createAuthClient({
  basePath: "/api/auth",
  plugins: [emailOTPClient(), passkeyClient()],
});
