import { NextResponse } from "next/server";
import prisma from "@/prisma/prisma";

export async function POST(req: Request) {
  try {
    const { email } = await req.json();

    if (!email) {
      return NextResponse.json({ error: "Email required" }, { status: 400 });
    }

    // Use parameterized query to prevent SQL injection
    const result: any = await prisma.$queryRawUnsafe(`
      CALL sp_get_user_id_by_email(?, @uid);
      SELECT @uid AS user_id;
    `, email);

    // MySQL procedure returns nested arrays, get final SELECT
    const userResult = Array.isArray(result) ? result[result.length - 1] : null;
    const user_id = userResult?.[0]?.user_id;

    if (!user_id) {
      // User not found
      return NextResponse.json({ exists: false });
    }

    // Return user_id - let NextAuth handle the session
    return NextResponse.json({ 
      exists: true, 
      user_id: user_id.toString() 
    });
  } catch (err: any) {
    console.error("Login Check Error:", err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}