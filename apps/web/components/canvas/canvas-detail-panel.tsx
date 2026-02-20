"use client";

import { useEffect, useCallback } from "react";
import { m } from "framer-motion";
import {
  X,
  Monitor,
  Server,
  Database,
  KeyRound,
  Plug,
  Settings,
  Bot,
  CheckCircle2,
  Circle,
  Loader2,
  AlertCircle,
  Clock,
  type LucideIcon,
} from "lucide-react";
import { springs } from "@/components/motion";
import { cn } from "@/lib/utils";
import type {
  CanvasComponentNode,
  CanvasComponentKind,
  CanvasNodeStatus,
  CanvasAgent,
} from "@/lib/canvas/types";

// ── Icon mapping ──────────────────────────────────────────────────────

const KIND_ICONS: Record<CanvasComponentKind, LucideIcon> = {
  frontend: Monitor,
  backend: Server,
  database: Database,
  auth: KeyRound,
  integration: Plug,
  config: Settings,
};

const STATUS_CONFIG: Record<
  CanvasNodeStatus,
  { label: string; icon: LucideIcon; className: string }
> = {
  idle: {
    label: "Idle",
    icon: Circle,
    className: "text-muted-foreground",
  },
  queued: {
    label: "Queued",
    icon: Clock,
    className: "text-primary",
  },
  building: {
    label: "Building",
    icon: Loader2,
    className: "text-primary animate-spin",
  },
  ready: {
    label: "Complete",
    icon: CheckCircle2,
    className: "text-green-400",
  },
  error: {
    label: "Error",
    icon: AlertCircle,
    className: "text-destructive",
  },
};

// ── Detail panel ──────────────────────────────────────────────────────

export function CanvasDetailPanel({
  node,
  agent,
  onClose,
}: {
  node: CanvasComponentNode;
  agent?: CanvasAgent;
  onClose: () => void;
}) {
  const KindIcon = KIND_ICONS[node.kind];
  const statusCfg = STATUS_CONFIG[node.status];
  const StatusIcon = statusCfg.icon;

  const progressPct =
    node.progress.total > 0
      ? Math.round((node.progress.current / node.progress.total) * 100)
      : 0;

  // Close on Escape
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    },
    [onClose],
  );

  useEffect(() => {
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [handleKeyDown]);

  return (
    <m.aside
      initial={{ x: 380, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      exit={{ x: 380, opacity: 0 }}
      transition={springs.smooth}
      className="fixed right-0 top-0 z-50 flex h-full w-[380px] flex-col border-l bg-card/95 backdrop-blur-xl"
      role="complementary"
      aria-label={`${node.title} details`}
    >
      {/* Header */}
      <div className="flex items-center justify-between border-b px-5 py-4">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl border bg-background">
            <KindIcon className="h-5 w-5 text-primary" />
          </div>
          <div>
            <h2 className="font-mono text-sm font-bold">{node.title}</h2>
            {node.subtitle && (
              <p className="text-xs text-muted-foreground">{node.subtitle}</p>
            )}
          </div>
        </div>
        <button
          onClick={onClose}
          className="flex h-8 w-8 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
          aria-label="Close panel"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-5">
        <div className="space-y-6">
          {/* Status */}
          <section>
            <h3 className="mb-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
              Status
            </h3>
            <div className="flex items-center gap-2 rounded-lg border bg-background px-3 py-2.5">
              <StatusIcon className={cn("h-4 w-4", statusCfg.className)} />
              <span className="text-sm font-medium">{statusCfg.label}</span>
            </div>
          </section>

          {/* Description */}
          {node.description && (
            <section>
              <h3 className="mb-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
                Description
              </h3>
              <p className="text-sm text-muted-foreground leading-relaxed">
                {node.description}
              </p>
            </section>
          )}

          {/* Progress */}
          <section>
            <h3 className="mb-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
              Progress
            </h3>
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">
                  {node.progress.current} / {node.progress.total} tasks
                </span>
                <span className="font-mono text-xs tabular-nums">
                  {progressPct}%
                </span>
              </div>
              <div className="h-2 rounded-full bg-muted">
                <m.div
                  className={cn(
                    "h-full rounded-full",
                    node.status === "ready"
                      ? "bg-green-500"
                      : node.status === "error"
                        ? "bg-destructive"
                        : "bg-primary",
                  )}
                  initial={{ width: 0 }}
                  animate={{ width: `${progressPct}%` }}
                  transition={{ duration: 0.3 }}
                />
              </div>
            </div>
          </section>

          {/* Agent Activity */}
          <section>
            <h3 className="mb-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
              Agent Activity
            </h3>
            {agent ? (
              <div className="rounded-lg border bg-background p-3">
                <div className="flex items-center gap-2">
                  <div
                    className={cn(
                      "flex h-7 w-7 items-center justify-center rounded-full border",
                      agent.status === "working" || agent.status === "thinking"
                        ? "border-primary/50 bg-primary/20"
                        : "border-border bg-muted",
                    )}
                  >
                    <Bot className="h-3.5 w-3.5 text-primary" />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium">{agent.label}</p>
                    <p className="text-xs text-muted-foreground">
                      {agent.message ?? agent.status}
                    </p>
                  </div>
                  {(agent.status === "working" ||
                    agent.status === "thinking") && (
                    <Loader2 className="h-3.5 w-3.5 animate-spin text-primary" />
                  )}
                </div>
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">
                No agent currently assigned
              </p>
            )}
          </section>

          {/* Component type */}
          <section>
            <h3 className="mb-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
              Type
            </h3>
            <span className="inline-flex items-center gap-1.5 rounded-md border bg-background px-2.5 py-1 text-xs font-medium capitalize">
              <KindIcon className="h-3 w-3" />
              {node.kind}
            </span>
          </section>
        </div>
      </div>
    </m.aside>
  );
}
