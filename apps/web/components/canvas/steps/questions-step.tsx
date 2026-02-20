"use client";

import { useState } from "react";
import { m, AnimatePresence } from "framer-motion";
import {
  ChevronRight,
  ChevronLeft,
  MessageSquare,
  Check,
  Plus,
  Minus,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { fadeScale, fadeUp, springs } from "@/components/motion";
import type { CanvasQuestion, CanvasAnswer } from "@/lib/canvas/types";

interface QuestionsStepProps {
  questions: CanvasQuestion[];
  answers: CanvasAnswer[];
  activeQuestionIndex: number;
  onAnswer: (
    questionId: string,
    value: string | string[],
    context?: string
  ) => void;
  onSetActiveIndex: (index: number) => void;
  onContinue: () => void;
  onBack: () => void;
  isProcessing: boolean;
}

export function QuestionsStep({
  questions,
  answers,
  activeQuestionIndex,
  onAnswer,
  onSetActiveIndex,
  onContinue,
  onBack,
  isProcessing,
}: QuestionsStepProps) {
  const allAnswered = questions.every((q) =>
    answers.some((a) => a.questionId === q.id)
  );
  const activeQuestion = questions[activeQuestionIndex];
  const activeAnswer = answers.find((a) => a.questionId === activeQuestion?.id);
  const progress = answers.length / questions.length;

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
          <MessageSquare className="h-5 w-5 text-primary" />
          <span className="text-xs font-bold uppercase tracking-widest text-primary">
            Clarification
          </span>
        </div>
        <h1 className="mb-2 font-mono text-2xl font-bold tracking-tight md:text-3xl">
          Let me understand your idea better…
        </h1>
      </div>

      {/* Progress bar */}
      <div className="mb-6">
        <div className="mb-2 flex items-center justify-between text-xs text-muted-foreground">
          <span>
            Question {Math.min(activeQuestionIndex + 1, questions.length)} of{" "}
            {questions.length}
          </span>
          <span>{Math.round(progress * 100)}% complete</span>
        </div>
        <div className="h-1 overflow-hidden rounded-full bg-border">
          <m.div
            className="h-full rounded-full bg-primary"
            initial={{ width: 0 }}
            animate={{ width: `${progress * 100}%` }}
            transition={springs.smooth}
          />
        </div>
      </div>

      {/* Previously answered questions */}
      {activeQuestionIndex > 0 && (
        <div className="mb-4 space-y-2">
          {questions.slice(0, activeQuestionIndex).map((q, i) => {
            const answer = answers.find((a) => a.questionId === q.id);
            return (
              <button
                key={q.id}
                type="button"
                onClick={() => onSetActiveIndex(i)}
                className="flex w-full items-start gap-3 rounded-lg border bg-card/50 p-3 text-left transition-colors hover:bg-card"
              >
                <Check className="mt-0.5 h-4 w-4 shrink-0 text-green-400" />
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium text-foreground">
                    {q.prompt}
                  </p>
                  <p className="truncate text-xs text-muted-foreground">
                    {answer
                      ? Array.isArray(answer.value)
                        ? answer.value.join(", ")
                        : answer.value
                      : "—"}
                  </p>
                </div>
              </button>
            );
          })}
        </div>
      )}

      {/* Active question */}
      <AnimatePresence mode="wait">
        {activeQuestion && (
          <ActiveQuestionCard
            key={activeQuestion.id}
            question={activeQuestion}
            answer={activeAnswer}
            onAnswer={onAnswer}
            onNext={() => {
              if (activeQuestionIndex < questions.length - 1) {
                onSetActiveIndex(activeQuestionIndex + 1);
              }
            }}
            isLast={activeQuestionIndex === questions.length - 1}
          />
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
          disabled={!allAnswered || isProcessing}
          loading={isProcessing}
          loadingText="Analyzing answers…"
          size="lg"
          variant="gradient"
        >
          Review Specification
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </m.div>
  );
}

// ---------------------------------------------------------------------------
// Internal: Active question card
// ---------------------------------------------------------------------------

function ActiveQuestionCard({
  question,
  answer,
  onAnswer,
  onNext,
  isLast,
}: {
  question: CanvasQuestion;
  answer?: CanvasAnswer;
  onAnswer: (
    questionId: string,
    value: string | string[],
    context?: string
  ) => void;
  onNext: () => void;
  isLast: boolean;
}) {
  const [localValue, setLocalValue] = useState<string | string[]>(
    answer?.value ?? (question.type === "multi_select" ? [] : "")
  );
  const [showContext, setShowContext] = useState(!!answer?.context);
  const [contextText, setContextText] = useState(answer?.context ?? "");

  const handleSelectOption = (optionId: string) => {
    if (question.type === "single_select") {
      onAnswer(question.id, optionId, contextText || undefined);
      if (!isLast) {
        setTimeout(onNext, 300);
      }
    } else if (question.type === "multi_select") {
      const current = Array.isArray(localValue) ? localValue : [];
      const updated = current.includes(optionId)
        ? current.filter((v) => v !== optionId)
        : [...current, optionId];
      setLocalValue(updated);
    }
  };

  const handleSubmitFreeText = () => {
    if (typeof localValue === "string" && localValue.trim()) {
      onAnswer(question.id, localValue.trim(), contextText || undefined);
      if (!isLast) {
        setTimeout(onNext, 300);
      }
    }
  };

  const handleSubmitMultiSelect = () => {
    if (Array.isArray(localValue) && localValue.length > 0) {
      onAnswer(question.id, localValue, contextText || undefined);
      if (!isLast) {
        setTimeout(onNext, 300);
      }
    }
  };

  const selectedValue = answer?.value ?? localValue;

  return (
    <m.div
      variants={fadeScale}
      initial="hidden"
      animate="visible"
      exit="exit"
      className="rounded-xl border bg-card p-6"
    >
      <h2 className="mb-4 text-lg font-semibold">{question.prompt}</h2>

      {/* Options for single_select / multi_select */}
      {question.options && question.type !== "free_text" && (
        <div className="mb-4 flex flex-wrap gap-2">
          {question.options.map((opt) => {
            const isSelected =
              question.type === "single_select"
                ? selectedValue === opt.id
                : Array.isArray(localValue) && localValue.includes(opt.id);

            return (
              <button
                key={opt.id}
                type="button"
                onClick={() => handleSelectOption(opt.id)}
                className={cn(
                  "rounded-lg border px-4 py-2.5 text-sm font-medium transition-all",
                  isSelected
                    ? "border-primary bg-primary/10 text-primary"
                    : "border-border bg-background text-foreground hover:border-primary/40 hover:bg-primary/5"
                )}
              >
                {opt.label}
              </button>
            );
          })}
        </div>
      )}

      {/* Free text input */}
      {question.type === "free_text" && (
        <div className="mb-4">
          <input
            type="text"
            value={typeof localValue === "string" ? localValue : ""}
            onChange={(e) => setLocalValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") handleSubmitFreeText();
            }}
            placeholder="Type your answer…"
            className="w-full rounded-lg border bg-background px-4 py-3 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
            autoFocus
          />
          {/* Suggestion chips */}
          {question.options && question.options.length > 0 && (
            <div className="mt-3 flex flex-wrap gap-2">
              <span className="text-xs text-muted-foreground">
                Suggestions:
              </span>
              {question.options.map((opt) => (
                <button
                  key={opt.id}
                  type="button"
                  onClick={() => setLocalValue(opt.label)}
                  className="rounded-md border border-border/50 bg-muted px-2.5 py-1 text-xs text-muted-foreground transition-colors hover:text-foreground"
                >
                  {opt.label}
                </button>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Add context toggle */}
      <button
        type="button"
        onClick={() => setShowContext(!showContext)}
        className="mb-3 flex items-center gap-1.5 text-xs text-muted-foreground transition-colors hover:text-foreground"
      >
        {showContext ? (
          <Minus className="h-3 w-3" />
        ) : (
          <Plus className="h-3 w-3" />
        )}
        Add context (optional)
      </button>
      <AnimatePresence>
        {showContext && (
          <m.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={springs.smooth}
            className="overflow-hidden"
          >
            <textarea
              value={contextText}
              onChange={(e) => setContextText(e.target.value)}
              placeholder="Any additional context…"
              rows={2}
              className="mb-4 w-full resize-none rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
            />
          </m.div>
        )}
      </AnimatePresence>

      {/* Next button for free_text and multi_select */}
      {(question.type === "free_text" ||
        question.type === "multi_select") && (
        <div className="flex justify-end">
          <Button
            size="sm"
            onClick={
              question.type === "free_text"
                ? handleSubmitFreeText
                : handleSubmitMultiSelect
            }
            disabled={
              question.type === "free_text"
                ? typeof localValue !== "string" || !localValue.trim()
                : !Array.isArray(localValue) || localValue.length === 0
            }
          >
            {isLast ? "Done" : "Next"}
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      )}
    </m.div>
  );
}
