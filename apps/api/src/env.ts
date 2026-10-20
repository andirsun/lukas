export interface SessionUser {
  id: string;
  email: string;
  timezone: string;
  locale: string;
}

export interface AppEnv {
  Variables: {
    userId: string;
    user: SessionUser;
  };
}
