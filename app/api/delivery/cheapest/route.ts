import { NextResponse } from "next/server";
import prisma from "@/prisma/prisma";

export async function POST(req: Request) {
  try {
    const { dish_id } = await req.json();

    if (!dish_id) {
      console.error("❌ Missing dish_id in request");
      return NextResponse.json(
        { success: false, error: "dish_id is required" },
        { status: 400 }
      );
    }

    console.log("🚀 Calling sp_get_cheapest_delivery with dish_id =", dish_id);

    // Run the stored procedure safely
    const result: any = await prisma.$queryRawUnsafe(`
      CALL sp_get_cheapest_delivery(${dish_id});
    `);

    console.log("✅ Procedure raw result:", result);

    // MySQL CALL returns nested arrays in Prisma
    const platform = result?.[0]?.[0]?.platform_name || "Not available";

    console.log("✅ Extracted platform:", platform);

    return NextResponse.json({ success: true, platform });
  } catch (error: any) {
    console.error("🔥 sp_get_cheapest_delivery failed:", error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
