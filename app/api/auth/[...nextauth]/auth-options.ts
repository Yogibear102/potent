// lib/auth-options.ts
import { NextAuthOptions } from "next-auth";
import GoogleProvider from "next-auth/providers/google";

export const authOptions: NextAuthOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],

  callbacks: {
    async signIn({ user }) {
      try {
        // Check if user exists in DB
        const res = await fetch(`${process.env.NEXTAUTH_URL}/api/auth/login`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: user.email }),
        });

        const data = await res.json();

        // User exists -> continue login
        if (data.exists) return true;

        // New user -> go to register page
        return `/register?email=${encodeURIComponent(user.email || "")}`;
      } catch (error) {
        console.error("signIn callback failed:", error);
        return false;
      }
    },

    async jwt({ token, user }) {
      if (user) {
        const res = await fetch(`${process.env.NEXTAUTH_URL}/api/auth/login`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: user.email }),
        });
        const data = await res.json();
        if (data.exists) token.user_id = data.user_id;
      }
      return token;
    },

    async session({ session, token }) {
      if (token.user_id) session.user.id = token.user_id as string;
      return session;
    },
  },

  pages: {
    signIn: "/auth/signin",
    newUser: "/register", // ✅ correct key
  },

  session: {
    strategy: "jwt",
  },
};
