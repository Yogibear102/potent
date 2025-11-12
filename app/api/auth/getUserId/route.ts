import { NextResponse } from 'next/server';
import mysql from 'mysql2/promise';
import { RowDataPacket } from 'mysql2';

interface UserRow extends RowDataPacket {
  user_id: number;
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const email = body.email;

    if (!email) {
      return NextResponse.json({ error: 'Email is required' }, { status: 400 });
    }

    const connection = await mysql.createConnection(process.env.DATABASE_URL!);
    
    // Use direct query instead of stored procedure for debugging
    const [rows] = await connection.execute<UserRow[]>(
      'SELECT user_id FROM users WHERE email = ?',
      [email]
    );

    await connection.end();

    if (Array.isArray(rows) && rows.length > 0) {
      return NextResponse.json({ userId: rows[0].user_id });
    }
    
    return NextResponse.json({ error: 'User not found' }, { status: 404 });

  } catch (error: any) {
    console.error('Database error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}