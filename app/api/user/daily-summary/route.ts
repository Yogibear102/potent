import { NextResponse } from "next/server";
import prisma from "@/prisma/prisma";

export async function POST(req: Request) {
  try {
    const { user_id, date } = await req.json();

    if (!user_id) {
      return NextResponse.json(
        { success: false, error: "user_id is required" },
        { status: 400 }
      );
    }

    const targetDate = date || new Date().toISOString().split("T")[0];

    // Call the stored procedure and fetch OUT variables
    await prisma.$executeRawUnsafe(`
      CALL sp_get_daily_macros(${user_id}, '${targetDate}', 
        @o_total_calories, @o_total_protein, @o_total_carbs, @o_total_fats
      );
    `);

    // Retrieve OUT parameter values
    const [rows]: any = await prisma.$queryRawUnsafe(`
      SELECT 
        @o_total_calories AS total_calories,
        @o_total_protein AS total_protein,
        @o_total_carbs AS total_carbs,
        @o_total_fats AS total_fats;
    `);

    const dishes = await prisma.$queryRawUnsafe(`
      SELECT dish_name, calories, protein_g AS protein, carbs_g AS carbs, fats_g AS fats
      FROM user_log ul
      JOIN dishes d ON ul.dish_id = d.dish_id
      WHERE ul.user_id = ${user_id} AND DATE(ul.log_date) = '${targetDate}';
    `);

    return NextResponse.json({
      success: true,
      data: {
        date: targetDate,
        total_calories: rows.total_calories,
        total_protein: rows.total_protein,
        total_carbs: rows.total_carbs,
        total_fats: rows.total_fats,
        dishes: dishes.map((dish: any) => ({
          name: dish.dish_name,
          calories: dish.calories,
          protein: dish.protein,
          carbs: dish.carbs,
          fats: dish.fats,
        })),
      },
    });
  } catch (error: any) {
    console.error("sp_get_daily_macros failed:", error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
