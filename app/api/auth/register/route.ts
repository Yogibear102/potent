import { NextResponse } from "next/server";
import prisma from "@/prisma/prisma";

export async function POST(req: Request) {
  try {
    const data = await req.json();

    console.log("📥 Received data:", data);

    const user = await prisma.users.create({
      data: {
        user_id: BigInt(data.user_id),
        name: data.name,
        email: data.email,
        calorie_target: data.calorie_target, // ✅ match frontend field name
        latitude: data.latitude,
        longitude: data.longitude,
      },
    });

    const safeUser = {
      ...user,
      user_id: user.user_id.toString(),
    };

    console.log("✅ User created:", safeUser);

    return NextResponse.json({ success: true, data: safeUser });
  } catch (err: any) {
    console.error("❌ Register Error:", err);
    return NextResponse.json(
      { error: err.message || "Failed to create user" },
      { status: 500 }
    );
  }
}
