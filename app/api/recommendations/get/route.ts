import { NextResponse } from "next/server";
import mysql, { RowDataPacket, Connection } from "mysql2/promise";

interface RecommendationRequest {
  userId: number;
  dishId: number;
}

interface RecommendationResult extends RowDataPacket {
  dish_name: string | null;
  restaurant: string | null;
  calories: number | null;
  calorie_diff: number | null;
}

export async function POST(request: Request) {
  let connection: Connection | null = null;

  try {
    const body = await request.json() as RecommendationRequest;
    const { userId, dishId } = body;

    console.log("Received request:", { userId, dishId });

    if (!userId || !dishId) {
      return NextResponse.json(
        {
          success: false,
          error: "Both userId and dishId are required",
        },
        { status: 400 }
      );
    }

    // Use DATABASE_URL from .env
    connection = await mysql.createConnection(process.env.DATABASE_URL!);

    // Initialize OUT parameters
    await connection.execute(
      "SET @alt_dish_name = NULL, @alt_restaurant = NULL, @alt_calories = NULL, @calorie_diff = NULL"
    );

    // Call the stored procedure with max_distance_km
    const [procResult] = await connection.execute(
      "CALL sp_get_or_generate_recommendations(?, ?, ?, @alt_dish_name, @alt_restaurant, @alt_calories, @calorie_diff)",
      [dishId, userId, 10.0]
    );

    // Fetch OUT parameters
    const [rows] = await connection.execute<RecommendationResult[]>(
      "SELECT @alt_dish_name AS dish_name, @alt_restaurant AS restaurant, @alt_calories AS calories, @calorie_diff AS calorie_diff"
    );

    const result = rows[0];
    console.log("Procedure results:", result);

    if (!result?.dish_name) {
      return NextResponse.json({
        success: false,
        message: "No suitable alternative found",
      });
    }

    return NextResponse.json({
      success: true,
      data: {
        alternative_dish: result.dish_name,
        alt_restaurant: result.restaurant,
        alt_calories: result.calories,
        calorie_diff: result.calorie_diff,
      },
    });
  } catch (error) {
    console.error("Recommendations error:", error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 }
    );
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}
