import NextAuth, { DefaultSession } from "next-auth";

declare module "next-auth" {
  interface Session extends DefaultSession {
    user: {
      id?: string | null;
      name?: string | null;
      email?: string | null;
      image?: string | null;
    };
  }

  interface User {
    id?: string | null;
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    user_id?: string | null;
  }
}
