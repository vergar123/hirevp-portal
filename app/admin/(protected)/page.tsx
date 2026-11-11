import { createClient } from "@/lib/supabase/server";

export default async function AdminHomePage() {
  const supabase = await createClient();

  const [clients, vps, open] = await Promise.all([
    supabase
      .from("clients")
      .select("*", { count: "exact", head: true })
      .eq("status", "active"),
    supabase
      .from("vps")
      .select("*", { count: "exact", head: true })
      .eq("status", "active"),
    supabase
      .from("attendance_records")
      .select("*", { count: "exact", head: true })
      .is("clock_out_at", null),
  ]);

  const failed = clients.error || vps.error || open.error;
  if (failed) {
    console.error("dashboard stats failed:", failed.message);
  }

  const stats = [
    { label: "Active clients", value: clients.count },
    { label: "Active VPs", value: vps.count },
    { label: "Clocked in now", value: open.count },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-semibold">Dashboard</h1>
      {failed && (
        <p role="alert" className="text-sm text-red-600">
          Could not load some numbers. Try refreshing.
        </p>
      )}
      <div className="grid gap-4 sm:grid-cols-3">
        {stats.map((s) => (
          <div key={s.label} className="rounded border p-4">
            <div className="text-sm text-gray-600">{s.label}</div>
            <div className="text-3xl font-semibold">{s.value ?? "-"}</div>
          </div>
        ))}
      </div>
    </div>
  );
}