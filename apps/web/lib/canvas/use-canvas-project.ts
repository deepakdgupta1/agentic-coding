"use client";

import { useCallback } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import type { CanvasProject } from "./types";
import { getProject, upsertProject, createProject } from "./storage";

function canvasProjectKey(projectId: string) {
  return ["canvasProject", projectId] as const;
}

export function useCanvasProject(projectId: string) {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: canvasProjectKey(projectId),
    queryFn: () => {
      const existing = getProject(projectId);
      if (existing) return existing;
      return createProject(projectId);
    },
    staleTime: Infinity,
  });

  const updateProject = useCallback(
    (updater: (prev: CanvasProject) => CanvasProject) => {
      const key = canvasProjectKey(projectId);
      const current = queryClient.getQueryData<CanvasProject>(key);
      if (!current) return;

      const updated = updater(current);
      const withTimestamp = { ...updated, updatedAt: new Date().toISOString() };
      upsertProject(withTimestamp);
      queryClient.setQueryData(key, withTimestamp);
    },
    [projectId, queryClient],
  );

  return {
    project: query.data ?? null,
    isLoading: query.isLoading,
    updateProject,
  };
}
