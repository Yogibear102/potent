"use client";

import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";

export default function Home() {
  const router = useRouter();

  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-orange-200 via-amber-300 to-amber-500 font-['Roboto_Mono']">
      {/* Overlay Card */}
      <div className="bg-white/20 backdrop-blur-lg rounded-3xl shadow-2xl p-10 text-center max-w-2xl mx-4 border border-white/30">
        <h1 className="text-5xl font-bold mb-6 text-orange-900 drop-shadow-sm">
          Welcome to <span className="text-yellow-800">Calorie Tracker</span>
        </h1>

        <p className="text-lg text-orange-950/80 mb-8">
          Track your meals effortlessly and get smart calorie insights.
        </p>

        {/* Google Auth Button */}
        <button
          onClick={() => signIn("google", { callbackUrl: "/dashboard" })}
          className="w-full bg-white/70 text-orange-900 py-3 rounded-xl border border-orange-400 hover:bg-orange-100 transition-all duration-300 shadow-sm hover:shadow-md flex items-center justify-center gap-2 font-medium mb-4"
        >
          <img
            src="https://www.svgrepo.com/show/355037/google.svg"
            alt="Google"
            className="w-5 h-5"
          />
          Continue with Google
        </button>

        {/* Register Button */}
        <button
          onClick={() => router.push("/register")}
          className="w-full bg-orange-800 text-white py-3 rounded-xl border border-orange-900 hover:bg-orange-700 transition-all duration-300 shadow-sm hover:shadow-md font-medium"
        >
          New here? Create an account
        </button>
      </div>

      {/* Footer */}
      <footer className="mt-12 text-center text-orange-900/80 text-sm">
        <div className="w-32 h-[1px] bg-orange-900/30 mx-auto mb-3"></div>
        <div className="space-x-4">
          <a
            href="/about"
            className="hover:underline hover:text-orange-800 transition-colors"
          >
            About Us
          </a>
          <span>•</span>
          <span className="text-orange-950/70">@Potent Ltd</span>
        </div>
      </footer>
    </main>
  );
}
