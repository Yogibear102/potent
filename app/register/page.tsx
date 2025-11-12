"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";

export default function SignupPage() {
  const router = useRouter();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [weight, setWeight] = useState<number | null>(null);
  const [goal, setGoal] = useState<number | null>(null);
  const [height, setHeight] = useState<number | null>(null);
  const [age, setAge] = useState<number | null>(null);
  const [gender, setGender] = useState<"male" | "female">("male");
  const [timePeriod, setTimePeriod] = useState<number | null>(null);
  const [latitude, setLatitude] = useState<number | null>(null);
  const [longitude, setLongitude] = useState<number | null>(null);
  const [activityLevel, setActivityLevel] = useState<number>(1.2);

  const handleGetLocation = () => {
    if (!navigator.geolocation) {
      alert("Geolocation not supported.");
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLatitude(pos.coords.latitude);
        setLongitude(pos.coords.longitude);
        alert(
          `Location acquired!\nLatitude: ${pos.coords.latitude}\nLongitude: ${pos.coords.longitude}`
        );
      },
      (err) => alert("Failed to get location: " + err.message)
    );
  };

  const calculateCalorieTarget = (): number => {
    if (
      weight === null ||
      goal === null ||
      height === null ||
      age === null ||
      timePeriod === null
    )
      return 0;

    const bmr =
      gender === "male"
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;

    const maintenance = bmr * activityLevel;
    const totalDeficit = (weight - goal) * 7700;
    const dailyDeficit = totalDeficit / (timePeriod * 7);

    return Math.round(maintenance - dailyDeficit);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (
      !name.trim() ||
      !email.trim() ||
      weight === null ||
      goal === null ||
      height === null ||
      age === null ||
      timePeriod === null
    ) {
      alert("Please fill all fields.");
      return;
    }

    if (latitude === null || longitude === null) {
      alert("Please allow location access.");
      return;
    }

    const calorie_target = calculateCalorieTarget();
    console.log("🔥 Calculated calorie target:", calorie_target);

    const user_id = Date.now();

    const payload = {
      user_id,
      name,
      email,
      calorie_target,
      latitude,
      longitude,
    };

    try {
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const data = await res.json();
      if (!res.ok) {
        alert(data.error || "Failed to register.");
        return;
      }

      alert("Profile created successfully!");
      console.log("Registered user:", data.data);

      // 🚀 Redirect to dashboard
      router.push("/dashboard");
    } catch (err) {
      console.error(err);
      alert("Error registering user.");
    }
  };

  const getActivityLabel = (value: number) => {
    if (value <= 1.3) return "Sedentary";
    if (value <= 1.5) return "Lightly Active";
    if (value <= 1.7) return "Moderately Active";
    if (value <= 1.8) return "Very Active";
    return "Extremely Active";
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-amber-200 via-orange-300 to-yellow-500 flex flex-col items-center justify-center font-['Roboto_Mono'] p-8">
      <div className="bg-white/20 backdrop-blur-lg rounded-3xl shadow-2xl p-10 w-full max-w-3xl border border-white/30">
        <h1 className="text-4xl font-bold text-orange-900 text-center mb-8">
          Create Your Profile
        </h1>

        <form
          onSubmit={handleSubmit}
          className="flex flex-col space-y-5 text-orange-950"
        >
          <input
            type="text"
            placeholder="Full Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="p-3 rounded-xl border border-orange-400 bg-white/70 focus:bg-white focus:ring-2 focus:ring-orange-500 outline-none"
          />

          <input
            type="email"
            placeholder="Email Address"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="p-3 rounded-xl border border-orange-400 bg-white/70 focus:bg-white focus:ring-2 focus:ring-orange-500 outline-none"
          />

          <div className="flex gap-3">
            <input
              type="number"
              placeholder="Current Weight (kg)"
              value={weight ?? ""}
              onChange={(e) => setWeight(parseFloat(e.target.value))}
              className="w-1/2 p-3 rounded-xl border border-orange-400 bg-white/70 focus:bg-white focus:ring-2 focus:ring-orange-500 outline-none"
            />
            <input
              type="number"
              placeholder="Goal Weight (kg)"
              value={goal ?? ""}
              onChange={(e) => setGoal(parseFloat(e.target.value))}
              className="w-1/2 p-3 rounded-xl border border-orange-400 bg-white/70 focus:bg-white focus:ring-2 focus:ring-orange-500 outline-none"
            />
          </div>

          <div className="flex gap-3">
            <input
              type="number"
              placeholder="Height (cm)"
              value={height ?? ""}
              onChange={(e) => setHeight(parseFloat(e.target.value))}
              className="w-1/2 p-3 rounded-xl border border-orange-400 bg-white/70 focus:bg-white focus:ring-2 focus:ring-orange-500 outline-none"
            />
            <input
              type="number"
              placeholder="Age"
              value={age ?? ""}
              onChange={(e) => setAge(parseFloat(e.target.value))}
              className="w-1/2 p-3 rounded-xl border border-orange-400 bg-white/70 focus:bg-white focus:ring-2 focus:ring-orange-500 outline-none"
            />
          </div>

          <div>
            <label className="block text-orange-900 font-semibold mb-1">
              Gender
            </label>
            <select
              value={gender}
              onChange={(e) =>
                setGender(e.target.value as "male" | "female")
              }
              className="w-full p-3 rounded-xl border border-orange-400 bg-white/70 focus:bg-white focus:ring-2 focus:ring-orange-500 outline-none"
            >
              <option value="male">Male</option>
              <option value="female">Female</option>
            </select>
          </div>

          <div>
            <input
              type="number"
              placeholder="Time Period (weeks)"
              value={timePeriod ?? ""}
              onChange={(e) =>
                setTimePeriod(parseFloat(e.target.value))
              }
              className="w-full p-3 rounded-xl border border-orange-400 bg-white/70 focus:bg-white focus:ring-2 focus:ring-orange-500 outline-none"
            />
          </div>

          <div className="flex flex-col gap-2">
            <p className="text-orange-900 font-semibold">Your Location:</p>
            <button
              type="button"
              onClick={handleGetLocation}
              className="w-full mt-2 py-3 rounded-xl bg-amber-500 hover:bg-amber-400 text-white font-medium transition-all duration-300"
            >
              Allow Location Access
            </button>
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-orange-900 font-semibold">
              Activity Level: {getActivityLabel(activityLevel)}
            </label>
            <input
              type="range"
              min={1.2}
              max={1.9}
              step={0.01}
              value={activityLevel}
              onChange={(e) =>
                setActivityLevel(parseFloat(e.target.value))
              }
              className="w-full h-2 rounded-lg appearance-none bg-amber-300 accent-amber-500"
            />
            <div className="flex justify-between text-sm text-orange-800">
              <span>Sedentary</span>
              <span>Extremely Active</span>
            </div>
          </div>

          <button
            type="submit"
            className="mt-4 py-3 rounded-xl bg-orange-700 hover:bg-orange-800 text-white font-semibold transition-all duration-300 shadow-md"
          >
            Register
          </button>
        </form>
      </div>
    </main>
  );
}
