"use client";

import { m, AnimatePresence } from "framer-motion";
import { ChevronLeft, ChevronRight, Layers } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { fadeUp, staggerContainer, springs } from "@/components/motion";
import type { ProjectType } from "@/lib/canvas/types";
import { PROJECT_TYPES } from "@/lib/canvas/types";

export interface TypeStepProps {
  recommendedType?: ProjectType;
  recommendationRationale?: string;
  selectedType?: ProjectType;
  overrideReason?: string;
  onSelect: (type: ProjectType) => void;
  onOverrideReason: (reason: string) => void;
  onContinue: () => void;
  onBack: () => void;
  isProcessing: boolean;
}

export function TypeStep({
  recommendedType,
  recommendationRationale,
  selectedType,
  overrideReason,
  onSelect,
  onOverrideReason,
  onContinue,
  onBack,
  isProcessing,
}: TypeStepProps) {
  const isOverride = selectedType && selectedType !== recommendedType;

  return (
    <m.div
      variants={fadeUp}
      initial="hidden"
      animate="visible"
      exit="exit"
      className="mx-auto w-full max-w-2xl"
    >
      {/* Header */}
      <div className="mb-8 text-center">
        <div className="mb-3 flex items-center justify-center gap-2">
          <Layers className="h-5 w-5 text-primary" />
          <span className="text-xs font-bold uppercase tracking-widest text-primary">
            Project Type
          </span>
        </div>
        <h1 className="mb-2 font-mono text-2xl font-bold tracking-tight md:text-3xl">
          What type of project is this?
        </h1>
        <p className="text-sm text-muted-foreground">
          Select the category that best describes what you&apos;re building.
        </p>
      </div>

      {/* Card grid */}
      <m.div
        variants={staggerContainer}
        initial="hidden"
        animate="visible"
        className="grid grid-cols-1 gap-3 md:grid-cols-2"
      >
        {PROJECT_TYPES.map((pt) => {
          const isRecommended = pt.type === recommendedType;
          const isSelected = pt.type === selectedType;

          return (
            <m.button
              key={pt.type}
              type="button"
              variants={fadeUp}
              onClick={() => onSelect(pt.type)}
              disabled={isProcessing}
              className={cn(
                "relative rounded-xl border p-4 text-left transition-colors",
                "focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background",
                isSelected
                  ? "border-primary bg-primary/10"
                  : isRecommended
                    ? "border-primary/40 bg-card hover:border-primary/60 hover:bg-primary/5"
                    : "border-border bg-card hover:border-primary/40 hover:bg-primary/5",
                isProcessing && "pointer-events-none opacity-60",
              )}
            >
              {/* Recommended badge */}
              {isRecommended && (
                <span className="absolute -top-2.5 right-3 rounded-full bg-primary px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-primary-foreground">
                  ✨ Recommended
                </span>
              )}

              <div className="mb-1 text-2xl">{pt.icon}</div>
              <h3 className="text-sm font-semibold text-foreground">
                {pt.label}
              </h3>
              <p className="mt-0.5 text-xs text-muted-foreground">
                {pt.description}
              </p>
              <p className="mt-1 text-xs italic text-muted-foreground/70">
                e.g. {pt.example}
              </p>
            </m.button>
          );
        })}
      </m.div>

      {/* Recommendation rationale */}
      {recommendedType && recommendationRationale && (
        <p className="mt-4 text-center text-xs text-muted-foreground">
          <span className="font-medium text-primary">Why recommended:</span>{" "}
          {recommendationRationale}
        </p>
      )}

      {/* Override reason (when selecting non-recommended type) */}
      <AnimatePresence>
        {isOverride && (
          <m.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={springs.smooth}
            className="overflow-hidden"
          >
            <div className="mt-4">
              <label
                htmlFor="override-reason"
                className="mb-1.5 block text-xs font-medium uppercase tracking-wider text-muted-foreground"
              >
                Why does this fit better? (optional)
              </label>
              <textarea
                id="override-reason"
                value={overrideReason ?? ""}
                onChange={(e) => onOverrideReason(e.target.value)}
                placeholder="e.g., I only need a backend service without any UI…"
                rows={2}
                className="w-full resize-none rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
                disabled={isProcessing}
              />
            </div>
          </m.div>
        )}
      </AnimatePresence>

      {/* Navigation */}
      <div className="mt-8 flex items-center justify-between">
        <Button
          variant="ghost"
          size="sm"
          onClick={onBack}
          disabled={isProcessing}
        >
          <ChevronLeft className="h-4 w-4" />
          Back
        </Button>
        <Button
          onClick={onContinue}
          disabled={!selectedType || isProcessing}
          loading={isProcessing}
          loadingText="Generating specification…"
          size="lg"
          variant="gradient"
        >
          Continue
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </m.div>
  );
}
