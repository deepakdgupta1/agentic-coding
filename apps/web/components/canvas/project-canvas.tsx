"use client";

import { useState, useCallback, useEffect, useRef } from "react";
import { m, AnimatePresence } from "framer-motion";
import {
  Monitor,
  Server,
  Database,
  KeyRound,
  Plug,
  Settings,
  Bot,
  ArrowLeft,
  type LucideIcon,
} from "lucide-react";
import { useCanvasProject } from "@/lib/canvas/use-canvas-project";
import { startMockBuild, applyBuildEvent } from "@/lib/canvas/mock-build";
import { getCanvasBounds, NODE_W, NODE_H } from "@/lib/canvas/canvas-graph";
import type {
  CanvasComponentKind,
  CanvasComponentNode,
  CanvasNodeStatus,
  CanvasState,
  CanvasEdge,
} from "@/lib/canvas/types";
import { fadeUp, springs } from "@/components/motion";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { CanvasDetailPanel } from "./canvas-detail-panel";

// ── Icon + color mapping ──────────────────────────────────────────────

const KIND_ICONS: Record<CanvasComponentKind, LucideIcon> = {
  frontend: Monitor,
  backend: Server,
  database: Database,
  auth: KeyRound,
  integration: Plug,
  config: Settings,
};

const KIND_COLORS: Record<CanvasComponentKind, { fill: string; stroke: string; text: string }> = {
  frontend: { fill: "oklch(0.3 0.1 240)", stroke: "oklch(0.6 0.18 240)", text: "oklch(0.85 0.1 240)" },
  backend: { fill: "oklch(0.25 0.1 145)", stroke: "oklch(0.55 0.19 145)", text: "oklch(0.85 0.1 145)" },
  database: { fill: "oklch(0.28 0.1 290)", stroke: "oklch(0.6 0.18 290)", text: "oklch(0.85 0.1 290)" },
  auth: { fill: "oklch(0.3 0.1 60)", stroke: "oklch(0.65 0.16 60)", text: "oklch(0.88 0.1 60)" },
  integration: { fill: "oklch(0.28 0.1 195)", stroke: "oklch(0.6 0.18 195)", text: "oklch(0.85 0.1 195)" },
  config: { fill: "oklch(0.22 0.02 260)", stroke: "oklch(0.45 0.02 260)", text: "oklch(0.75 0.02 260)" },
};

const STATUS_RING: Record<CanvasNodeStatus, string> = {
  idle: "oklch(0.35 0.02 260)",
  queued: "oklch(0.55 0.12 195)",
  building: "oklch(0.75 0.18 195)",
  ready: "oklch(0.72 0.19 145)",
  error: "oklch(0.65 0.22 25)",
};

// ── Edge rendering ────────────────────────────────────────────────────

function EdgePath({
  edge,
  nodesById,
}: {
  edge: CanvasEdge;
  nodesById: Record<string, CanvasComponentNode>;
}) {
  const from = nodesById[edge.from];
  const to = nodesById[edge.to];
  if (!from || !to) return null;

  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const cpx = from.x + dx * 0.5;
  const cpy1 = from.y + dy * 0.15;
  const cpy2 = to.y - dy * 0.15;

  const path = `M ${from.x} ${from.y} C ${cpx} ${cpy1}, ${cpx} ${cpy2}, ${to.x} ${to.y}`;

  return (
    <g>
      <path
        d={path}
        fill="none"
        stroke="oklch(0.3 0.02 260)"
        strokeWidth={2}
        strokeLinecap="round"
        opacity={0.6}
      />
      <path
        d={path}
        fill="none"
        stroke="oklch(0.45 0.06 195)"
        strokeWidth={1.5}
        strokeLinecap="round"
        strokeDasharray="6 8"
        opacity={0.4}
      />
    </g>
  );
}

// ── SVG Node component ────────────────────────────────────────────────

function CanvasNode({
  node,
  isSelected,
  onClick,
}: {
  node: CanvasComponentNode;
  isSelected: boolean;
  onClick: () => void;
}) {
  const colors = KIND_COLORS[node.kind];
  const Icon = KIND_ICONS[node.kind];
  const ringColor = STATUS_RING[node.status];
  const w = NODE_W;
  const h = NODE_H;
  const rx = 16;

  const progressPct =
    node.progress.total > 0
      ? (node.progress.current / node.progress.total) * 100
      : 0;

  return (
    <m.g
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={springs.smooth}
      style={{ cursor: "pointer" }}
      onClick={onClick}
      role="button"
      tabIndex={0}
      aria-label={`${node.title}: ${node.status}`}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          onClick();
        }
      }}
    >
      {/* Glow ring for active states */}
      {(node.status === "building" || isSelected) && (
        <rect
          x={node.x - w / 2 - 4}
          y={node.y - h / 2 - 4}
          width={w + 8}
          height={h + 8}
          rx={rx + 2}
          fill="none"
          stroke={ringColor}
          strokeWidth={2}
          opacity={0.5}
        >
          {node.status === "building" && (
            <animate
              attributeName="opacity"
              values="0.3;0.7;0.3"
              dur="1.5s"
              repeatCount="indefinite"
            />
          )}
        </rect>
      )}

      {/* Background */}
      <rect
        x={node.x - w / 2}
        y={node.y - h / 2}
        width={w}
        height={h}
        rx={rx}
        fill={colors.fill}
        stroke={isSelected ? ringColor : colors.stroke}
        strokeWidth={isSelected ? 2 : 1}
      />

      {/* Progress bar at bottom */}
      {progressPct > 0 && (
        <>
          <rect
            x={node.x - w / 2 + 8}
            y={node.y + h / 2 - 12}
            width={w - 16}
            height={4}
            rx={2}
            fill="oklch(0.2 0.01 260)"
          />
          <rect
            x={node.x - w / 2 + 8}
            y={node.y + h / 2 - 12}
            width={Math.max(0, (w - 16) * (progressPct / 100))}
            height={4}
            rx={2}
            fill={STATUS_RING[node.status]}
          />
        </>
      )}

      {/* Icon */}
      <foreignObject
        x={node.x - 12}
        y={node.y - h / 2 + 12}
        width={24}
        height={24}
      >
        <Icon
          className="h-6 w-6"
          style={{ color: colors.text }}
        />
      </foreignObject>

      {/* Title */}
      <text
        x={node.x}
        y={node.y + 6}
        textAnchor="middle"
        fill={colors.text}
        fontSize={13}
        fontWeight={700}
        fontFamily="var(--font-jetbrains), monospace"
      >
        {node.title}
      </text>

      {/* Subtitle */}
      {node.subtitle && (
        <text
          x={node.x}
          y={node.y + 22}
          textAnchor="middle"
          fill={colors.text}
          fontSize={10}
          opacity={0.7}
        >
          {node.subtitle}
        </text>
      )}

      {/* Status indicator */}
      <circle
        cx={node.x + w / 2 - 12}
        cy={node.y - h / 2 + 12}
        r={5}
        fill={STATUS_RING[node.status]}
      >
        {node.status === "building" && (
          <animate
            attributeName="r"
            values="4;6;4"
            dur="1s"
            repeatCount="indefinite"
          />
        )}
      </circle>

      {/* Error shake */}
      {node.status === "error" && (
        <animateTransform
          attributeName="transform"
          type="translate"
          values="0,0; -3,0; 3,0; -2,0; 2,0; 0,0"
          dur="0.5s"
          repeatCount="1"
        />
      )}
    </m.g>
  );
}

// ── Progress header ───────────────────────────────────────────────────

function BuildHeader({
  canvas,
  onBack,
}: {
  canvas: CanvasState;
  onBack: () => void;
}) {
  const agentList = Object.values(canvas.agents);
  const activeAgents = agentList.filter(
    (a) => a.status === "working" || a.status === "thinking",
  );

  return (
    <header className="sticky top-0 z-40 border-b bg-background/80 backdrop-blur-lg">
      <div className="mx-auto flex max-w-7xl items-center gap-4 px-4 py-3">
        <Button variant="ghost" size="icon-sm" onClick={onBack} aria-label="Back to wizard">
          <ArrowLeft className="h-4 w-4" />
        </Button>

        <span className="font-mono text-sm font-bold tracking-tight text-foreground">
          ACFS Canvas
        </span>

        {/* Build progress bar */}
        <div className="flex flex-1 items-center gap-3">
          <div className="h-2 flex-1 rounded-full bg-muted">
            <m.div
              className="h-full rounded-full bg-primary"
              initial={{ width: 0 }}
              animate={{ width: `${canvas.build.percent}%` }}
              transition={{ duration: 0.3 }}
            />
          </div>
          <span className="text-xs font-mono text-muted-foreground tabular-nums">
            {canvas.build.percent}%
          </span>
        </div>

        {/* Agent avatars */}
        <div className="flex items-center gap-1.5">
          {agentList.map((agent) => (
            <div
              key={agent.id}
              className={cn(
                "flex h-7 w-7 items-center justify-center rounded-full border text-xs font-bold transition-colors",
                agent.status === "working" || agent.status === "thinking"
                  ? "border-primary/50 bg-primary/20 text-primary"
                  : agent.status === "done"
                    ? "border-green-500/50 bg-green-500/10 text-green-400"
                    : "border-border bg-muted text-muted-foreground",
              )}
              title={`${agent.label}: ${agent.message ?? agent.status}`}
            >
              <Bot className="h-3.5 w-3.5" />
            </div>
          ))}
          {activeAgents.length > 0 && (
            <span className="ml-1 text-xs text-muted-foreground">
              {activeAgents.length} active
            </span>
          )}
        </div>
      </div>
    </header>
  );
}

// ── Main canvas component ─────────────────────────────────────────────

export function ProjectCanvas({ projectId }: { projectId: string }) {
  const { project, updateProject } = useCanvasProject(projectId);
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
  const buildRef = useRef<{ stop: () => void } | null>(null);

  const canvas = project?.canvas;

  // Start mock build on mount if not yet started
  useEffect(() => {
    if (!canvas || canvas.build.phase !== "not_started") return;

    buildRef.current = startMockBuild(canvas, (event) => {
      updateProject((p) => {
        if (!p.canvas) return p;
        return { ...p, canvas: applyBuildEvent(p.canvas, event) };
      });
    });

    return () => {
      buildRef.current?.stop();
    };
  }, [canvas?.build.phase]); // eslint-disable-line react-hooks/exhaustive-deps

  if (!project || !canvas) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p className="text-muted-foreground">No canvas data available.</p>
      </div>
    );
  }

  const bounds = getCanvasBounds(canvas);
  const nodes = Object.values(canvas.nodesById);
  const selectedNode = selectedNodeId
    ? canvas.nodesById[selectedNodeId]
    : null;
  const selectedAgent = selectedNode
    ? Object.values(canvas.agents).find(
        (a) => a.currentNodeId === selectedNode.id,
      )
    : null;

  const handleBack = () => {
    buildRef.current?.stop();
    updateProject((p) => ({ ...p, step: "review" }));
  };

  return (
    <m.div
      variants={fadeUp}
      initial="hidden"
      animate="visible"
      exit="exit"
      className="min-h-screen bg-background"
    >
      <BuildHeader canvas={canvas} onBack={handleBack} />

      <div className="flex">
        {/* SVG canvas area */}
        <main
          className={cn(
            "flex-1 overflow-auto p-4 transition-all",
            selectedNode && "mr-[380px]",
          )}
        >
          <svg
            viewBox={`0 0 ${bounds.width} ${bounds.height}`}
            className="mx-auto w-full max-w-5xl"
            style={{ minHeight: 400 }}
            role="img"
            aria-label="Project component canvas"
          >
            {/* Edges */}
            {canvas.edges.map((edge) => (
              <EdgePath
                key={edge.id}
                edge={edge}
                nodesById={canvas.nodesById}
              />
            ))}

            {/* Nodes */}
            {nodes.map((node) => (
              <CanvasNode
                key={node.id}
                node={node}
                isSelected={node.id === selectedNodeId}
                onClick={() =>
                  setSelectedNodeId((prev) =>
                    prev === node.id ? null : node.id,
                  )
                }
              />
            ))}
          </svg>
        </main>

        {/* Detail panel (E2-S2) */}
        <AnimatePresence>
          {selectedNode && (
            <CanvasDetailPanel
              key={selectedNode.id}
              node={selectedNode}
              agent={selectedAgent ?? undefined}
              onClose={() => setSelectedNodeId(null)}
            />
          )}
        </AnimatePresence>
      </div>
    </m.div>
  );
}
