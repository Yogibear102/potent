import { NextResponse } from "next/server";
import prisma from "@/prisma/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/app/api/auth/[...nextauth]/auth-options";

export async function POST(req: Request) {
  try {
    // ✅ Verify session
    const session = await getServerSession(authOptions);
    if (!session?.user?.email) {
      return NextResponse.json(
        { success: false, error: "Not authenticated" },
        { status: 401 }
      );
    }

    // ✅ Parse body
    const body = await req.json();
    const { user_id, dish_id, quantity } = body;

    if (!user_id || !dish_id) {
      return NextResponse.json(
        { success: false, error: "user_id and dish_id are required" },
        { status: 400 }
      );
    }

    const today = new Date();

    // ✅ Call stored procedure to log dish
    await prisma.$executeRaw`CALL sp_log_dish(${user_id}, ${dish_id}, ${quantity ?? 1}, ${today})`;

    return NextResponse.json({
      success: true,
      message: "Dish logged successfully!",
    });
  } catch (error: any) {
    console.error("log-dish error:", error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
