import { NextResponse } from 'next/server';
import mysql, { RowDataPacket } from 'mysql2/promise';

interface DishRow extends RowDataPacket {
  dish_id: number;
}

export async function POST(request: Request) {
  let connection = null;
  try {
    const body = await request.json();
    const dishName = body.dish_name;

    if (!dishName) {
      return NextResponse.json({ 
        success: false,
        error: 'Dish name is required' 
      }, { status: 400 });
    }

    connection = await mysql.createConnection(process.env.DATABASE_URL!);

    // First try exact match
    const [rows] = await connection.execute<DishRow[]>(
      'SELECT dish_id FROM dishes WHERE dish_name = ?',
      [dishName]
    );

    console.log('Dish search:', {
      searchedName: dishName,
      exactMatch: rows.length > 0,
      foundId: rows.length > 0 ? rows[0].dish_id : null
    });

    // If no exact match, try LIKE search
    if (rows.length === 0) {
      const [likeRows] = await connection.execute<DishRow[]>(
        'SELECT dish_id FROM dishes WHERE dish_name LIKE ?',
        [`%${dishName}%`]
      );

      console.log('Fuzzy dish search:', {
        searchedName: dishName,
        pattern: `%${dishName}%`,
        found: likeRows.length > 0,
        foundId: likeRows.length > 0 ? likeRows[0].dish_id : null
      });

      if (likeRows.length === 0) {
        return NextResponse.json({
          success: false,
          error: 'Dish not found'
        }, { status: 404 });
      }

      return NextResponse.json({
        success: true,
        dish_id: likeRows[0].dish_id
      });
    }

    return NextResponse.json({
      success: true,
      dish_id: rows[0].dish_id
    });

  } catch (error) {
    console.error('Get dish ID error:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}