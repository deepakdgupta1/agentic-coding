"use client";

import { useRef, useEffect } from "react";
import { m, AnimatePresence } from "framer-motion";
import { ChevronRight, Plus, Minus, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { fadeUp, springs } from "@/components/motion";

const PLACEHOLDER_EXAMPLES = [
  "A task management app where teams can create projects, assign tasks, and track progress with a kanban board view",
  "An expense tracker that lets users log spending, categorize transactions, and view monthly reports with charts",
  "A recipe sharing platform where users can post recipes, leave reviews, and save favorites to a personal cookbook",
];

export interface DescriptionStepProps {
  description: string;
  moreDetailsEnabled: boolean;
  targetUsers?: string;
  keyFeatures?: string;
  examples?: string;
  onUpdate: (data: {
    description?: string;
    moreDetailsEnabled?: boolean;
    targetUsers?: string;
    keyFeatures?: string;
    examples?: string;
  }) => void;
  onContinue: () => void;
  isProcessing: boolean;
}

export function DescriptionStep({
  description,
  moreDetailsEnabled,
  targetUsers,
  keyFeatures,
  examples,
  onUpdate,
  onContinue,
  isProcessing,
}: DescriptionStepProps) {
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const charCount = description.length;
  const isValid = charCount >= 20;

  useEffect(() => {
    textareaRef.current?.focus();
  }, []);

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
          <Sparkles className="h-5 w-5 text-primary" />
          <span className="text-xs font-bold uppercase tracking-widest text-primary">
            New Project
          </span>
        </div>
        <h1 className="mb-2 font-mono text-2xl font-bold tracking-tight md:text-3xl">
          What do you want to build?
        </h1>
        <p className="text-sm text-muted-foreground">
          Describe your idea in plain language — no technical knowledge required.
        </p>
      </div>

      {/* Main textarea */}
      <div className="relative">
        <textarea
          ref={textareaRef}
          value={description}
          onChange={(e) => onUpdate({ description: e.target.value })}
          placeholder={PLACEHOLDER_EXAMPLES[0]}
          rows={5}
          className={cn(
            "w-full resize-none rounded-xl border bg-card p-4 text-base leading-relaxed text-foreground placeholder:text-muted-foreground/50",
            "transition-colors duration-200",
            "focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20",
            isProcessing && "pointer-events-none opacity-60",
          )}
          disabled={isProcessing}
          aria-label="Project description"
        />
        <div className="mt-2 flex items-center justify-between px-1">
          <span
            className={cn(
              "text-xs transition-colors",
              charCount === 0
                ? "text-muted-foreground/50"
                : charCount < 20
                  ? "text-amber-400"
                  : "text-muted-foreground",
            )}
          >
            {charCount} character{charCount !== 1 ? "s" : ""}
            {charCount > 0 && charCount < 20 && (
              <span className="ml-1">· {20 - charCount} more needed</span>
            )}
          </span>
        </div>
      </div>

      {/* Add more details toggle */}
      <button
        type="button"
        onClick={() => onUpdate({ moreDetailsEnabled: !moreDetailsEnabled })}
        disabled={isProcessing}
        className="mt-4 flex items-center gap-2 text-sm text-muted-foreground transition-colors hover:text-foreground disabled:opacity-50"
      >
        {moreDetailsEnabled ? (
          <Minus className="h-4 w-4" />
        ) : (
          <Plus className="h-4 w-4" />
        )}
        {moreDetailsEnabled ? "Hide details" : "Add more details"}
      </button>

      {/* Expandable details */}
      <AnimatePresence>
        {moreDetailsEnabled && (
          <m.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={springs.smooth}
            className="overflow-hidden"
          >
            <div className="mt-4 space-y-4 rounded-xl border bg-card/50 p-4">
              <div>
                <label
                  htmlFor="target-users"
                  className="mb-1.5 block text-xs font-medium uppercase tracking-wider text-muted-foreground"
                >
                  Target Users
                </label>
                <input
                  id="target-users"
                  type="text"
                  value={targetUsers ?? ""}
                  onChange={(e) => onUpdate({ targetUsers: e.target.value })}
                  placeholder="e.g., Small teams of 5-20 people"
                  className="w-full rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  disabled={isProcessing}
                />
              </div>
              <div>
                <label
                  htmlFor="key-features"
                  className="mb-1.5 block text-xs font-medium uppercase tracking-wider text-muted-foreground"
                >
                  Key Features
                </label>
                <input
                  id="key-features"
                  type="text"
                  value={keyFeatures ?? ""}
                  onChange={(e) => onUpdate({ keyFeatures: e.target.value })}
                  placeholder="e.g., Kanban board, user authentication, notifications"
                  className="w-full rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  disabled={isProcessing}
                />
              </div>
              <div>
                <label
                  htmlFor="examples"
                  className="mb-1.5 block text-xs font-medium uppercase tracking-wider text-muted-foreground"
                >
                  Similar Products / Examples
                </label>
                <input
                  id="examples"
                  type="text"
                  value={examples ?? ""}
                  onChange={(e) => onUpdate({ examples: e.target.value })}
                  placeholder="e.g., Like Trello but simpler, or like Notion for recipes"
                  className="w-full rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  disabled={isProcessing}
                />
              </div>
            </div>
          </m.div>
        )}
      </AnimatePresence>

      {/* Continue button */}
      <div className="mt-8 flex justify-end">
        <Button
          onClick={onContinue}
          disabled={!isValid || isProcessing}
          loading={isProcessing}
          loadingText="Analyzing your idea…"
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
