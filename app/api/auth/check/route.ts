import { NextResponse } from "next/server";
import prisma from "@/prisma/prisma";

export async function POST(req: Request) {
  try {
    const { user_id } = await req.json();

    if (!user_id) {
      return NextResponse.json({ error: "user_id is required" }, { status: 400 });
    }

    const user = await prisma.users.findUnique({
      where: { user_id: BigInt(user_id) },
    });

    if (!user) {
      return NextResponse.json({ exists: false });
    }

    // Convert BigInt for JSON
    const safeUser = { ...user, user_id: user.user_id.toString() };

    return NextResponse.json({ exists: true, user: safeUser });
  } catch (err: any) {
    console.error("Check User Error:", err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
