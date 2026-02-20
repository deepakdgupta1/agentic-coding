"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { createProject } from "@/lib/canvas/storage";

export function CanvasNewProject() {
  const router = useRouter();

  useEffect(() => {
    const id = crypto.randomUUID();
    createProject(id);
    router.replace(`/canvas/${id}`);
  }, [router]);

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        <p className="text-sm text-muted-foreground">Setting up your project…</p>
      </div>
    </div>
  );
}
