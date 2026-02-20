"use client";

import { useState, useCallback } from "react";
import { m } from "framer-motion";
import {
  ChevronLeft,
  RotateCcw,
  Copy,
  Check,
  Plus,
  X,
  Rocket,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { fadeUp } from "@/components/motion";
import type { CanvasSpecification } from "@/lib/canvas/types";
import { PROJECT_TYPES } from "@/lib/canvas/types";

export interface ReviewStepProps {
  spec: CanvasSpecification;
  onUpdateSpec: (spec: CanvasSpecification) => void;
  onStartBuilding: () => void;
  onStartOver: () => void;
  onBack: () => void;
  isProcessing: boolean;
}

function specToMarkdown(spec: CanvasSpecification): string {
  const typeInfo = PROJECT_TYPES.find((t) => t.type === spec.project.type);
  let md = `# ${spec.project.name}\n\n`;
  md += `${spec.project.description}\n\n`;
  md += `**Type:** ${typeInfo?.label ?? spec.project.type}\n\n`;
  md += `## Users\n\n`;
  md += `- **Primary:** ${spec.users.primary}\n`;
  if (spec.users.secondary) md += `- **Secondary:** ${spec.users.secondary}\n`;
  md += `\n## Core Features\n\n`;
  for (const f of spec.features.core) md += `- ${f}\n`;
  if (spec.features.niceToHave.length > 0) {
    md += `\n## Nice to Have\n\n`;
    for (const f of spec.features.niceToHave) md += `- ${f}\n`;
  }
  md += `\n## Technical Stack\n\n`;
  if (spec.technical.frontend)
    md += `- **Frontend:** ${spec.technical.frontend}\n`;
  if (spec.technical.backend)
    md += `- **Backend:** ${spec.technical.backend}\n`;
  if (spec.technical.database)
    md += `- **Database:** ${spec.technical.database}\n`;
  if (spec.technical.deployment)
    md += `- **Deployment:** ${spec.technical.deployment}\n`;
  return md;
}

export function ReviewStep({
  spec,
  onUpdateSpec,
  onStartBuilding,
  onStartOver,
  onBack,
  isProcessing,
}: ReviewStepProps) {
  const [copied, setCopied] = useState(false);

  const updateProject = useCallback(
    (patch: Partial<CanvasSpecification["project"]>) => {
      onUpdateSpec({ ...spec, project: { ...spec.project, ...patch } });
    },
    [spec, onUpdateSpec],
  );

  const updateUsers = useCallback(
    (patch: Partial<CanvasSpecification["users"]>) => {
      onUpdateSpec({ ...spec, users: { ...spec.users, ...patch } });
    },
    [spec, onUpdateSpec],
  );

  const updateTechnical = useCallback(
    (patch: Partial<CanvasSpecification["technical"]>) => {
      onUpdateSpec({ ...spec, technical: { ...spec.technical, ...patch } });
    },
    [spec, onUpdateSpec],
  );

  const updateFeature = useCallback(
    (
      list: "core" | "niceToHave",
      index: number,
      value: string,
    ) => {
      const updated = [...spec.features[list]];
      updated[index] = value;
      onUpdateSpec({
        ...spec,
        features: { ...spec.features, [list]: updated },
      });
    },
    [spec, onUpdateSpec],
  );

  const addFeature = useCallback(
    (list: "core" | "niceToHave") => {
      onUpdateSpec({
        ...spec,
        features: {
          ...spec.features,
          [list]: [...spec.features[list], ""],
        },
      });
    },
    [spec, onUpdateSpec],
  );

  const removeFeature = useCallback(
    (list: "core" | "niceToHave", index: number) => {
      const updated = spec.features[list].filter((_, i) => i !== index);
      onUpdateSpec({
        ...spec,
        features: { ...spec.features, [list]: updated },
      });
    },
    [spec, onUpdateSpec],
  );

  const handleCopy = useCallback(async () => {
    await navigator.clipboard.writeText(specToMarkdown(spec));
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }, [spec]);

  const typeInfo = PROJECT_TYPES.find((t) => t.type === spec.project.type);

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
          <Rocket className="h-5 w-5 text-primary" />
          <span className="text-xs font-bold uppercase tracking-widest text-primary">
            Review
          </span>
        </div>
        <h1 className="mb-2 font-mono text-2xl font-bold tracking-tight md:text-3xl">
          Review Your Project Specification
        </h1>
        <p className="text-sm text-muted-foreground">
          Edit any field below, then start building.
        </p>
      </div>

      <div
        className={cn(
          "space-y-6",
          isProcessing && "pointer-events-none opacity-60",
        )}
      >
        {/* ── Project ── */}
        <section className="rounded-xl border bg-card p-4">
          <h2 className="mb-3 text-xs font-bold uppercase tracking-wider text-muted-foreground">
            Project
          </h2>
          <div className="space-y-3">
            <div>
              <label
                htmlFor="project-name"
                className="mb-1 block text-xs text-muted-foreground"
              >
                Name
              </label>
              <input
                id="project-name"
                type="text"
                value={spec.project.name}
                onChange={(e) => updateProject({ name: e.target.value })}
                className="w-full rounded-lg border bg-background px-3 py-2 text-sm focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
            <div>
              <label
                htmlFor="project-description"
                className="mb-1 block text-xs text-muted-foreground"
              >
                Description
              </label>
              <textarea
                id="project-description"
                value={spec.project.description}
                onChange={(e) =>
                  updateProject({ description: e.target.value })
                }
                rows={3}
                className="w-full resize-none rounded-lg border bg-background px-3 py-2 text-sm focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span className="text-lg">{typeInfo?.icon}</span>
              <span>{typeInfo?.label ?? spec.project.type}</span>
            </div>
          </div>
        </section>

        {/* ── Users ── */}
        <section className="rounded-xl border bg-card p-4">
          <h2 className="mb-3 text-xs font-bold uppercase tracking-wider text-muted-foreground">
            Users
          </h2>
          <div className="space-y-3">
            <div>
              <label
                htmlFor="user-primary"
                className="mb-1 block text-xs text-muted-foreground"
              >
                Primary
              </label>
              <input
                id="user-primary"
                type="text"
                value={spec.users.primary}
                onChange={(e) => updateUsers({ primary: e.target.value })}
                className="w-full rounded-lg border bg-background px-3 py-2 text-sm focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
            <div>
              <label
                htmlFor="user-secondary"
                className="mb-1 block text-xs text-muted-foreground"
              >
                Secondary (optional)
              </label>
              <input
                id="user-secondary"
                type="text"
                value={spec.users.secondary ?? ""}
                onChange={(e) =>
                  updateUsers({
                    secondary: e.target.value || undefined,
                  })
                }
                placeholder="e.g., Admins, managers"
                className="w-full rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
          </div>
        </section>

        {/* ── Features ── */}
        <section className="rounded-xl border bg-card p-4">
          <h2 className="mb-3 text-xs font-bold uppercase tracking-wider text-muted-foreground">
            Features
          </h2>

          {/* Core features */}
          <div className="mb-4">
            <h3 className="mb-2 text-xs font-medium text-foreground">
              Core Features
            </h3>
            <div className="space-y-2">
              {spec.features.core.map((feature, i) => (
                <div key={i} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={feature}
                    onChange={(e) =>
                      updateFeature("core", i, e.target.value)
                    }
                    placeholder="Describe a feature…"
                    className="min-w-0 flex-1 rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                  <button
                    type="button"
                    onClick={() => removeFeature("core", i)}
                    className="shrink-0 rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive"
                    aria-label="Remove feature"
                  >
                    <X className="h-3.5 w-3.5" />
                  </button>
                </div>
              ))}
            </div>
            <button
              type="button"
              onClick={() => addFeature("core")}
              className="mt-2 flex items-center gap-1.5 text-xs text-muted-foreground transition-colors hover:text-foreground"
            >
              <Plus className="h-3.5 w-3.5" />
              Add Feature
            </button>
          </div>

          {/* Nice-to-have features */}
          <div>
            <h3 className="mb-2 text-xs font-medium text-foreground">
              Nice to Have
            </h3>
            <div className="space-y-2">
              {spec.features.niceToHave.map((feature, i) => (
                <div key={i} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={feature}
                    onChange={(e) =>
                      updateFeature("niceToHave", i, e.target.value)
                    }
                    placeholder="Describe a feature…"
                    className="min-w-0 flex-1 rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                  <button
                    type="button"
                    onClick={() => removeFeature("niceToHave", i)}
                    className="shrink-0 rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive"
                    aria-label="Remove feature"
                  >
                    <X className="h-3.5 w-3.5" />
                  </button>
                </div>
              ))}
            </div>
            <button
              type="button"
              onClick={() => addFeature("niceToHave")}
              className="mt-2 flex items-center gap-1.5 text-xs text-muted-foreground transition-colors hover:text-foreground"
            >
              <Plus className="h-3.5 w-3.5" />
              Add Feature
            </button>
          </div>
        </section>

        {/* ── Technical ── */}
        <section className="rounded-xl border bg-card p-4">
          <h2 className="mb-3 text-xs font-bold uppercase tracking-wider text-muted-foreground">
            Technical
          </h2>
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <div>
              <label
                htmlFor="tech-frontend"
                className="mb-1 block text-xs text-muted-foreground"
              >
                Frontend
              </label>
              <input
                id="tech-frontend"
                type="text"
                value={spec.technical.frontend ?? ""}
                onChange={(e) =>
                  updateTechnical({
                    frontend: e.target.value || undefined,
                  })
                }
                placeholder="e.g., Next.js, React"
                className="w-full rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
            <div>
              <label
                htmlFor="tech-backend"
                className="mb-1 block text-xs text-muted-foreground"
              >
                Backend
              </label>
              <input
                id="tech-backend"
                type="text"
                value={spec.technical.backend ?? ""}
                onChange={(e) =>
                  updateTechnical({
                    backend: e.target.value || undefined,
                  })
                }
                placeholder="e.g., Node.js, Python"
                className="w-full rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
            <div>
              <label
                htmlFor="tech-database"
                className="mb-1 block text-xs text-muted-foreground"
              >
                Database
              </label>
              <input
                id="tech-database"
                type="text"
                value={spec.technical.database ?? ""}
                onChange={(e) =>
                  updateTechnical({
                    database: e.target.value || undefined,
                  })
                }
                placeholder="e.g., PostgreSQL, SQLite"
                className="w-full rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
            <div>
              <label
                htmlFor="tech-deployment"
                className="mb-1 block text-xs text-muted-foreground"
              >
                Deployment
              </label>
              <input
                id="tech-deployment"
                type="text"
                value={spec.technical.deployment ?? ""}
                onChange={(e) =>
                  updateTechnical({
                    deployment: e.target.value || undefined,
                  })
                }
                placeholder="e.g., Vercel, Docker"
                className="w-full rounded-lg border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground/50 focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
          </div>
        </section>
      </div>

      {/* Actions */}
      <div className="mt-8 flex flex-col gap-3">
        {/* Top row: Copy + Back */}
        <div className="flex items-center justify-between">
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
            variant="secondary"
            size="sm"
            onClick={handleCopy}
            disabled={isProcessing}
          >
            {copied ? (
              <Check className="h-4 w-4" />
            ) : (
              <Copy className="h-4 w-4" />
            )}
            {copied ? "Copied!" : "Copy as Markdown"}
          </Button>
        </div>

        {/* Bottom row: Start Over + Start Building */}
        <div className="flex items-center justify-between">
          <Button
            variant="ghost"
            onClick={onStartOver}
            disabled={isProcessing}
          >
            <RotateCcw className="h-4 w-4" />
            Start Over
          </Button>
          <Button
            onClick={onStartBuilding}
            disabled={isProcessing}
            loading={isProcessing}
            loadingText="Preparing…"
            size="lg"
            variant="gradient"
          >
            Start Building
            <Rocket className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </m.div>
  );
}
