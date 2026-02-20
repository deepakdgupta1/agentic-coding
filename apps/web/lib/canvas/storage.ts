import { safeGetJSON, safeSetJSON } from "@/lib/utils";
import type { CanvasProject, CanvasWizardStep } from "./types";

const STORAGE_PREFIX = "acfs-canvas:project:";

function storageKey(projectId: string): string {
  return `${STORAGE_PREFIX}${projectId}`;
}

export function getProject(projectId: string): CanvasProject | null {
  return safeGetJSON<CanvasProject>(storageKey(projectId));
}

export function upsertProject(project: CanvasProject): void {
  safeSetJSON(storageKey(project.id), {
    ...project,
    updatedAt: new Date().toISOString(),
  });
}

export function createProject(projectId: string): CanvasProject {
  const now = new Date().toISOString();
  const project: CanvasProject = {
    version: 1,
    id: projectId,
    createdAt: now,
    updatedAt: now,
    step: "description",
    vision: {
      description: "",
      moreDetailsEnabled: false,
    },
    clarification: {
      questions: [],
      answers: [],
      activeQuestionIndex: 0,
    },
    typeSelection: {},
    spec: {},
  };
  upsertProject(project);
  return project;
}

export function resetToStep(
  project: CanvasProject,
  step: CanvasWizardStep,
): CanvasProject {
  const reset: CanvasProject = { ...project, step };
  if (step === "description") {
    reset.clarification = {
      questions: [],
      answers: [],
      activeQuestionIndex: 0,
    };
    reset.typeSelection = {};
    reset.spec = {};
  } else if (step === "questions") {
    reset.typeSelection = {};
    reset.spec = {};
  } else if (step === "type") {
    reset.spec = {};
  }
  upsertProject(reset);
  return reset;
}
