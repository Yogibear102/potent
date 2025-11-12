"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import SpotlightCard from "./SpotlightCard";
import { motion, AnimatePresence } from "framer-motion";
import { Utensils, BarChart3 } from "lucide-react";
import { useSession, signOut } from "next-auth/react";
import axios from "axios";
import { Pie } from "react-chartjs-2";
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend
} from 'chart.js';

ChartJS.register(ArcElement, Tooltip, Legend);

type RecommendationResult =
  | {
      alternative_dish: string;
      alt_restaurant: string;
      alt_calories: number;
      calorie_diff: number;
    }
  | string
  | null;

type DailySummary = {
  date: string;
  total_calories: number;
  total_protein: number;
  total_carbs: number;
  total_fats: number;
  dishes?: Array<{
    name: string;
    calories: number;
    protein: number;
    carbs: number;
    fats: number;
  }>;
};

export default function DashboardPage() {
  const [activeModal, setActiveModal] = useState<string | null>(null);
  const [dish, setDish] = useState("");
  const [result, setResult] = useState<RecommendationResult>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [user, setUser] = useState<{ name?: string; email?: string; userId?: string } | null>(null);
  const [dailySummary, setDailySummary] = useState<DailySummary | null>(null);
  const [summaryLoading, setSummaryLoading] = useState(false);
  const [loggedDishId, setLoggedDishId] = useState<number | null>(null);
  const [isLogging, setIsLogging] = useState(false);
  const [hasLogged, setHasLogged] = useState(false);

  const { data: session, status } = useSession();
  const router = useRouter();

  // 🔐 Auth check
  useEffect(() => {
    const checkAuth = async () => {
      try {
        if (status === "loading") return;
        if (!session?.user?.email) {
          router.push("/");
          return;
        }

        const userResponse = await axios.post("/api/auth/getUserId", {
          email: session.user.email,
        });

        if (!userResponse.data?.userId) throw new Error("No user ID returned");

        setUser({
          name: session.user.name || "",
          email: session.user.email,
          userId: userResponse.data.userId,
        });
      } catch (error) {
        console.error("Dashboard error:", error);
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, [session, router, status]);

  // 🍔 Find Cheatmeal
  const handleFindCheatmeal = async () => {
    if (!user) {
      setResult("Please log in first.");
      return;
    }
    if (!dish.trim()) {
      setResult("Please enter a dish you're craving!");
      return;
    }

    setResult("Loading...");
    setHasLogged(false); // reset log state
    setLoggedDishId(null);

    try {
      const dishRes = await axios.post("/api/get-dish-id", { dish_name: dish.trim() });
      if (!dishRes.data?.success || !dishRes.data?.dish_id) {
        setResult(`Dish "${dish}" not found in our database.`);
        return;
      }

      const originalDishId = dishRes.data.dish_id;
      setLoggedDishId(originalDishId);

      const recRes = await axios.post("/api/recommendations/get", {
        dishId: originalDishId,
        userId: user.userId,
      });

      if (recRes.data?.success && recRes.data?.data) {
        const rec = recRes.data.data;
        setResult({
          alternative_dish: rec.alternative_dish,
          alt_restaurant: rec.alt_restaurant,
          alt_calories: rec.alt_calories,
          calorie_diff: rec.calorie_diff,
        });
      } else {
        setResult("No suitable alternative found nearby 🍂");
      }
    } catch (error) {
      console.error("Cheatmeal error:", error);
      setResult("Something went wrong while fetching recommendations.");
    }
  };

  // 🍽️ Log Dish
  const handleLogDish = async () => {
    if (!user?.userId) {
      alert("Please log in first!");
      return;
    }
    if (!loggedDishId) {
      alert("No dish to log!");
      return;
    }

    try {
      setIsLogging(true);
      const today = new Date();

      const res = await axios.post("/api/user/log-dish", {
        user_id: user.userId,
        dish_id: loggedDishId,
        quantity: 1.0,
      });

      if (res.data?.success) {
        setHasLogged(true);
      } else {
        console.error("API response error:", res.data);
        alert("❌ Failed to log dish. Please try again later.");
      }
    } catch (error: any) {
      console.error("Log dish error:", error);
      if (error.response) {
        console.error("Server responded with:", error.response.data);
        alert(`Error logging dish: ${error.response.data.message || "Unknown server error"}`);
      } else if (error.request) {
        console.error("No response received:", error.request);
        alert("Error logging dish: No response from server. Please check your connection.");
      } else {
        console.error("Unexpected error:", error.message);
        alert(`Error logging dish: ${error.message}`);
      }
    } finally {
      setIsLogging(false);
    }
  };

  // 📊 Fetch Daily Summary
  const handleFetchDailySummary = async () => {
    if (!user?.userId) return;
    setSummaryLoading(true);
    setDailySummary(null);

    try {
      const res = await axios.post("/api/user/daily-summary", {
        user_id: user.userId,
      });

      if (res.data?.success) {
        setDailySummary(res.data.data);
      } else {
        setDailySummary(null);
      }
    } catch (error) {
      console.error("Daily summary fetch error:", error);
    } finally {
      setSummaryLoading(false);
    }
  };

  useEffect(() => {
    if (activeModal === "summary") handleFetchDailySummary();
  }, [activeModal]);

  // 🚪 Logout
  const handleLogout = async () => {
    try {
      await signOut({ redirect: false });
      router.push("/");
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  const fadeVariants = {
    hidden: { opacity: 0, scale: 0.95 },
    visible: { opacity: 1, scale: 1 },
    exit: { opacity: 0, scale: 0.95 },
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-orange-100 via-amber-200 to-peach-200 flex items-center justify-center font-['Roboto_Mono']">
        <div className="text-amber-700 text-xl">Loading...</div>
      </div>
    );
  }

  // 🌟 UI 
  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-100 via-amber-200 to-peach-200 flex flex-col items-center justify-center text-amber-900 p-8 relative font-['Roboto_Mono']">
      {/* Updated Welcome Message */}
      {user && (
        <div className="absolute top-6 right-6 bg-amber-500/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-amber-400">
          <p className="text-amber-800 font-medium">Welcome, {user.name}!</p>
        </div>
      )}

      <h1 className="text-8xl font-bold mb-12 text-amber-700 drop-shadow-md">Potent</h1>

      <div className="flex gap-12 w-full max-w-6xl justify-center">
        <SpotlightCard
          spotlightColor="rgba(255, 200, 100, 0.3)"
          className="relative w-[420px] h-[280px] hover:scale-105 transition-transform duration-300 cursor-pointer"
          onClick={() => setActiveModal("cheatmeal")}
        >
          <Utensils className="absolute top-4 left-4 text-amber-600 opacity-80" size={32} />
          <h2 className="text-3xl font-semibold text-amber-800 mb-3 mt-8">Find Your Cheatmeal</h2>
          <p className="text-amber-700 text-base opacity-80 leading-relaxed">
            Craving something delicious? Let's find a healthier alternative near you 🍩
          </p>
        </SpotlightCard>

        <SpotlightCard
          spotlightColor="rgba(255, 180, 100, 0.25)"
          className="relative w-[420px] h-[280px] hover:scale-105 transition-transform duration-300 cursor-pointer"
          onClick={() => setActiveModal("summary")}
        >
          <BarChart3 className="absolute top-4 left-4 text-amber-600 opacity-80" size={32} />
          <h2 className="text-3xl font-semibold text-amber-800 mb-3 mt-8">Daily Summary</h2>
          <p className="text-amber-700 text-base opacity-80 leading-relaxed">
            View your calories and macro breakdown for today 📊
          </p>
        </SpotlightCard>
      </div>

      <button
        onClick={handleLogout}
        className="mt-8 px-6 py-2 bg-amber-500/30 hover:bg-amber-500/50 text-amber-900 border border-amber-400 rounded-lg transition-all shadow-md backdrop-blur-sm"
      >
        Logout
      </button>

      {/* ============= MODALS ============= */}
      <AnimatePresence>
        {activeModal && (
          <motion.div
            key="modal"
            className="absolute inset-0 bg-gradient-to-br from-amber-100/90 via-orange-100/90 to-peach-100/90 flex items-center justify-center z-50 backdrop-blur-md"
            initial="hidden"
            animate="visible"
            exit="exit"
            variants={fadeVariants}
            transition={{ duration: 0.3 }}
          >
            <motion.div
              className="bg-gradient-to-br from-orange-100 via-amber-200 to-peach-200 border border-amber-400 rounded-3xl p-8 w-[420px] shadow-lg shadow-amber-400/30"
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: 20, opacity: 0 }}
              transition={{ duration: 0.3 }}
            >
              {/* 🍩 Cheatmeal Modal */}
              {activeModal === "cheatmeal" && (
                <>
                  <h2 className="text-2xl font-semibold mb-4 text-amber-800">🍂 Find Your Cheatmeal</h2>

                  <input
                    type="text"
                    placeholder="What are you craving?"
                    value={dish}
                    onChange={(e) => setDish(e.target.value)}
                    className="w-full p-3 rounded-lg bg-amber-100 border border-amber-400 text-amber-900 placeholder:text-amber-600 focus:outline-none focus:ring-2 focus:ring-amber-500"
                  />

                  <button
                    onClick={handleFindCheatmeal}
                    className="mt-4 w-full bg-amber-500 hover:bg-amber-400 text-white font-semibold py-2 rounded-lg transition-all shadow-md"
                  >
                    Find Alternative
                  </button>

                  {result && (
                    <div className="mt-6 text-amber-900 bg-amber-100/70 border border-amber-400 p-4 rounded-lg shadow-inner">
                      {typeof result === "string" ? (
                        result
                      ) : (
                        <>
                          <div>
                            <span className="font-semibold">Dish:</span> {result.alternative_dish}
                          </div>
                          <div>
                            <span className="font-semibold">Restaurant:</span> {result.alt_restaurant}
                          </div>
                          <div>
                            <span className="font-semibold">Calories:</span> {result.alt_calories} kcal
                          </div>
                          <div>
                            <span className="font-semibold">Calorie Difference:</span>{" "}
                            {result.calorie_diff} kcal
                          </div>

                          <button
                            onClick={handleLogDish}
                            disabled={isLogging || hasLogged}
                            className={`mt-4 w-full font-semibold py-2 rounded-lg transition-all shadow-md ${
                              hasLogged
                                ? "bg-gray-400 cursor-not-allowed text-white"
                                : "bg-amber-600 hover:bg-amber-500 text-white"
                            }`}
                          >
                            {hasLogged ? "Logged ✅" : isLogging ? "Logging..." : "Log Dish"}
                          </button>
                        </>
                      )}
                    </div>
                  )}
                </>
              )}

              {/* 📊 Daily Summary Modal */}
              {activeModal === "summary" && (
                <>
                  <h2 className="text-2xl font-semibold mb-4 text-amber-800">📅 Daily Summary</h2>

                  {summaryLoading ? (
                    <p className="text-amber-700">Loading summary...</p>
                  ) : dailySummary ? (
                    <div className="space-y-3">
                      <p className="font-semibold text-amber-900">Date: {dailySummary.date}</p>
                      <p className="font-medium">
                        🧮 Total Calories:{" "}
                        <span className="font-bold">{dailySummary.total_calories}</span> kcal
                      </p>
                      <div className="flex justify-center items-center gap-8">
                        <div className="w-2/3">
                          <Pie data={generateMacroChartData(dailySummary)} options={{ maintainAspectRatio: false }} />
                        </div>
                        <div className="flex flex-col space-y-2">
                          <div className="flex items-center">
                            <div className="w-4 h-4 bg-[#F59E0B] mr-2"></div>
                            <span className="text-amber-900 font-medium">Protein</span>
                          </div>
                          <div className="flex items-center">
                            <div className="w-4 h-4 bg-[#F97316] mr-2"></div>
                            <span className="text-amber-900 font-medium">Carbs</span>
                          </div>
                          <div className="flex items-center">
                            <div className="w-4 h-4 bg-[#E11D48] mr-2"></div>
                            <span className="text-amber-900 font-medium">Fats</span>
                          </div>
                        </div>
                      </div>
                      <p>
                        🥩 Protein:{" "}
                        <span className="font-bold">{dailySummary.total_protein}</span> g
                      </p>
                      <p>
                        🍞 Carbs:{" "}
                        <span className="font-bold">{dailySummary.total_carbs}</span> g
                      </p>
                      <p>
                        🧈 Fats:{" "}
                        <span className="font-bold">{dailySummary.total_fats}</span> g
                      </p>

                      {/* Dishes List */}
                      {Array.isArray(dailySummary?.dishes) && dailySummary.dishes.length > 0 && (
                        <div className="space-y-3">
                          <h3 className="text-xl font-semibold text-amber-800">Dishes Logged:</h3>
                          <ul className="list-disc pl-5">
                            {dailySummary.dishes?.map((dish, index) => (
                              <li key={index} className="text-amber-900">
                                <span className="font-medium">{dish.name}</span> - 
                                <span> {dish.calories} kcal, </span>
                                <span>{dish.protein}g protein, </span>
                                <span>{dish.carbs}g carbs, </span>
                                <span>{dish.fats}g fats</span>
                              </li>
                            ))}
                          </ul>
                        </div>
                      )}
                    </div>
                  ) : (
                    <p className="text-amber-700">No summary found for today.</p>
                  )}
                </>
              )}

              <button
                onClick={() => setActiveModal(null)}
                className="mt-6 text-sm text-amber-700 hover:text-amber-900 underline"
              >
                Close
              </button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

const generateMacroChartData = (dailySummary: DailySummary) => {
  return {
    labels: ['Protein', 'Carbs', 'Fats'],
    datasets: [
      {
        data: [dailySummary.total_protein, dailySummary.total_carbs, dailySummary.total_fats],
        backgroundColor: ['#F59E0B', '#F97316', '#E11D48'], // Updated to match page color scheme
        hoverBackgroundColor: ['#F59E0B', '#F97316', '#E11D48'],
      },
    ],
  };
};
