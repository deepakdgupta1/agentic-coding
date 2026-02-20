"use client";

import { useState, useCallback } from "react";
import { AnimatePresence } from "framer-motion";
import { useCanvasProject } from "@/lib/canvas/use-canvas-project";
import { resetToStep } from "@/lib/canvas/storage";
import {
  mockGenerateQuestions,
  mockRecommendType,
  mockGenerateSpec,
} from "@/lib/canvas/mock-ai";
import { deriveCanvasState } from "@/lib/canvas/canvas-graph";
import type {
  CanvasWizardStep,
  ProjectType,
  CanvasSpecification,
} from "@/lib/canvas/types";
import { DescriptionStep } from "./steps/description-step";
import { QuestionsStep } from "./steps/questions-step";
import { TypeStep } from "./steps/type-step";
import { ReviewStep } from "./steps/review-step";
import { ProjectCanvas } from "./project-canvas";

// Step metadata for the progress indicator
const STEPS: { key: CanvasWizardStep; label: string }[] = [
  { key: "description", label: "Describe" },
  { key: "questions", label: "Clarify" },
  { key: "type", label: "Type" },
  { key: "review", label: "Review" },
];

export function CanvasWizard({ projectId }: { projectId: string }) {
  const { project, isLoading, updateProject } = useCanvasProject(projectId);
  const [isProcessing, setIsProcessing] = useState(false);

  // ── Step navigation ──────────────────────────────────────────────
  const goToStep = useCallback(
    (step: CanvasWizardStep) => {
      updateProject((p) => ({ ...p, step }));
    },
    [updateProject],
  );

  // ── E1-S1: Description → Questions ──────────────────────────────
  const handleDescriptionContinue = useCallback(async () => {
    if (!project) return;
    setIsProcessing(true);
    try {
      const questions = await mockGenerateQuestions(project.vision.description);
      updateProject((p) => ({
        ...p,
        step: "questions",
        clarification: {
          questions,
          answers: [],
          activeQuestionIndex: 0,
        },
      }));
    } finally {
      setIsProcessing(false);
    }
  }, [project, updateProject]);

  // ── E1-S2: Questions → Type ─────────────────────────────────────
  const handleQuestionsContinue = useCallback(async () => {
    if (!project) return;
    setIsProcessing(true);
    try {
      const { type, rationale } = await mockRecommendType(
        project.vision.description,
        project.clarification.answers,
      );
      updateProject((p) => ({
        ...p,
        step: "type",
        typeSelection: {
          recommendedType: type,
          recommendationRationale: rationale,
          selectedType: type,
        },
      }));
    } finally {
      setIsProcessing(false);
    }
  }, [project, updateProject]);

  // ── E1-S3: Type → Review ────────────────────────────────────────
  const handleTypeContinue = useCallback(async () => {
    if (!project || !project.typeSelection.selectedType) return;
    setIsProcessing(true);
    try {
      const spec = await mockGenerateSpec(
        project.vision.description,
        project.clarification.answers,
        project.typeSelection.selectedType,
      );
      updateProject((p) => ({
        ...p,
        step: "review",
        spec: { draft: spec },
      }));
    } finally {
      setIsProcessing(false);
    }
  }, [project, updateProject]);

  // ── E1-S4: Start Building → transition to canvas ────────────────
  const handleStartBuilding = useCallback(() => {
    if (!project?.spec.draft) return;
    const canvasState = deriveCanvasState(project.spec.draft);
    updateProject((p) => ({ ...p, step: "canvas", canvas: canvasState }));
  }, [project, updateProject]);

  // ── Start Over ──────────────────────────────────────────────────
  const handleStartOver = useCallback(() => {
    if (!project) return;
    const reset = resetToStep(project, "description");
    updateProject(() => reset);
  }, [project, updateProject]);

  // ── Loading state ───────────────────────────────────────────────
  if (isLoading || !project) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          <p className="text-sm text-muted-foreground">Loading project…</p>
        </div>
      </div>
    );
  }

  // Canvas step takes over the full page
  if (project.step === "canvas") {
    return <ProjectCanvas projectId={projectId} />;
  }

  const currentStepIndex = STEPS.findIndex((s) => s.key === project.step);

  return (
    <div className="min-h-screen bg-background">
      {/* Top bar with step indicator */}
      <header className="sticky top-0 z-40 border-b bg-background/80 backdrop-blur-lg">
        <div className="mx-auto flex max-w-3xl items-center justify-between px-4 py-3">
          <span className="font-mono text-sm font-bold tracking-tight text-foreground">
            ACFS Canvas
          </span>

          {/* Step dots */}
          <nav
            className="flex items-center gap-2"
            aria-label="Wizard progress"
          >
            {STEPS.map((s, i) => (
              <div key={s.key} className="flex items-center gap-2">
                {i > 0 && (
                  <div
                    className={`h-px w-4 transition-colors ${
                      i <= currentStepIndex
                        ? "bg-primary"
                        : "bg-border"
                    }`}
                  />
                )}
                <div
                  className={`flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-bold transition-colors ${
                    i === currentStepIndex
                      ? "bg-primary text-primary-foreground"
                      : i < currentStepIndex
                        ? "bg-primary/20 text-primary"
                        : "bg-muted text-muted-foreground"
                  }`}
                  aria-current={i === currentStepIndex ? "step" : undefined}
                >
                  {i + 1}
                </div>
              </div>
            ))}
          </nav>
        </div>
      </header>

      {/* Step content */}
      <main className="mx-auto max-w-3xl px-4 py-10 md:py-16">
        <AnimatePresence mode="wait">
          {project.step === "description" && (
            <DescriptionStep
              key="description"
              description={project.vision.description}
              moreDetailsEnabled={project.vision.moreDetailsEnabled}
              targetUsers={project.vision.targetUsers}
              keyFeatures={project.vision.keyFeatures}
              examples={project.vision.examples}
              onUpdate={(data) => {
                updateProject((p) => ({
                  ...p,
                  vision: { ...p.vision, ...data },
                }));
              }}
              onContinue={handleDescriptionContinue}
              isProcessing={isProcessing}
            />
          )}

          {project.step === "questions" && (
            <QuestionsStep
              key="questions"
              questions={project.clarification.questions}
              answers={project.clarification.answers}
              activeQuestionIndex={project.clarification.activeQuestionIndex}
              onAnswer={(questionId, value, context) => {
                updateProject((p) => {
                  const existing = p.clarification.answers.filter(
                    (a) => a.questionId !== questionId,
                  );
                  return {
                    ...p,
                    clarification: {
                      ...p.clarification,
                      answers: [
                        ...existing,
                        { questionId, value, context },
                      ],
                    },
                  };
                });
              }}
              onSetActiveIndex={(index) => {
                updateProject((p) => ({
                  ...p,
                  clarification: {
                    ...p.clarification,
                    activeQuestionIndex: index,
                  },
                }));
              }}
              onContinue={handleQuestionsContinue}
              onBack={() => goToStep("description")}
              isProcessing={isProcessing}
            />
          )}

          {project.step === "type" && (
            <TypeStep
              key="type"
              recommendedType={project.typeSelection.recommendedType}
              recommendationRationale={
                project.typeSelection.recommendationRationale
              }
              selectedType={project.typeSelection.selectedType}
              overrideReason={project.typeSelection.overrideReason}
              onSelect={(type: ProjectType) => {
                updateProject((p) => ({
                  ...p,
                  typeSelection: { ...p.typeSelection, selectedType: type },
                }));
              }}
              onOverrideReason={(reason: string) => {
                updateProject((p) => ({
                  ...p,
                  typeSelection: { ...p.typeSelection, overrideReason: reason },
                }));
              }}
              onContinue={handleTypeContinue}
              onBack={() => goToStep("questions")}
              isProcessing={isProcessing}
            />
          )}

          {project.step === "review" && project.spec.draft && (
            <ReviewStep
              key="review"
              spec={project.spec.draft}
              onUpdateSpec={(spec: CanvasSpecification) => {
                updateProject((p) => ({
                  ...p,
                  spec: { draft: spec },
                }));
              }}
              onStartBuilding={handleStartBuilding}
              onStartOver={handleStartOver}
              onBack={() => goToStep("type")}
              isProcessing={isProcessing}
            />
          )}
        </AnimatePresence>
      </main>
    </div>
  );
}
