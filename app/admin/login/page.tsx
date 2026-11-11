"use client";

import { useActionState } from "react";
import { login } from "../actions";

export default function AdminLoginPage() {
  const [state, formAction, pending] = useActionState(login, { error: null });

  return (
    <main className="flex min-h-screen items-center justify-center p-6">
      <form action={formAction} className="w-full max-w-sm space-y-4">
        <h1 className="text-2xl font-semibold">HireVP Admin</h1>

        <label className="block text-sm">
          Email
          <input
            name="email"
            type="email"
            autoComplete="email"
            required
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>

        <label className="block text-sm">
          Password
          <input
            name="password"
            type="password"
            autoComplete="current-password"
            required
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>

        {state.error && (
          <p role="alert" className="text-sm text-red-600">
            {state.error}
          </p>
        )}

        <button
          type="submit"
          disabled={pending}
          className="w-full rounded bg-black px-3 py-2 text-white disabled:opacity-50"
        >
          {pending ? "Signing in..." : "Sign in"}
        </button>
      </form>
    </main>
  );
}