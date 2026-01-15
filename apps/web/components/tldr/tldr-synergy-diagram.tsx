"use client";

import { useRef, useMemo } from "react";
import { motion, useReducedMotion, useInView } from "framer-motion";
import { cn } from "@/lib/utils";
import { getColorDefinition } from "@/lib/colors";
import type { TldrFlywheelTool } from "@/lib/tldr-content";

// =============================================================================
// TYPES
// =============================================================================

interface TldrSynergyDiagramProps {
  tools: TldrFlywheelTool[];
  className?: string;
}

interface NodePosition {
  x: number;
  y: number;
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export function TldrSynergyDiagram({
  tools,
  className,
}: TldrSynergyDiagramProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const isInView = useInView(containerRef, { once: true, margin: "-50px" });
  const prefersReducedMotion = useReducedMotion();
  const reducedMotion = prefersReducedMotion ?? false;

  // Filter to core tools only for the diagram
  const coreTools = useMemo(
    () => tools.filter((t) => t.category === "core"),
    [tools]
  );

  // Calculate node positions in a circle - adjust radius based on tool count
  const nodePositions = useMemo(() => {
    const positions: Record<string, NodePosition> = {};
    const centerX = 200;
    const centerY = 200;
    // Scale radius based on number of tools to prevent overlap
    const radius = coreTools.length > 8 ? 155 : 140;

    coreTools.forEach((tool, index) => {
      // Start from top and go clockwise
      const angle = (index / coreTools.length) * 2 * Math.PI - Math.PI / 2;
      positions[tool.id] = {
        x: centerX + radius * Math.cos(angle),
        y: centerY + radius * Math.sin(angle),
      };
    });

    return positions;
  }, [coreTools]);

  // Generate connection lines with colors from connected tools
  const connections = useMemo(() => {
    const lines: Array<{
      from: string;
      to: string;
      fromPos: NodePosition;
      toPos: NodePosition;
      fromColor: { from: string; to: string };
      toColor: { from: string; to: string };
    }> = [];

    coreTools.forEach((tool) => {
      tool.synergies.forEach((synergy) => {
        const targetTool = coreTools.find((t) => t.id === synergy.toolId);
        if (targetTool && nodePositions[tool.id] && nodePositions[synergy.toolId]) {
          // Avoid duplicate lines (A->B and B->A)
          const existingLine = lines.find(
            (l) =>
              (l.from === synergy.toolId && l.to === tool.id) ||
              (l.from === tool.id && l.to === synergy.toolId)
          );
          if (!existingLine) {
            lines.push({
              from: tool.id,
              to: synergy.toolId,
              fromPos: nodePositions[tool.id],
              toPos: nodePositions[synergy.toolId],
              fromColor: getColorDefinition(tool.color),
              toColor: getColorDefinition(targetTool.color),
            });
          }
        }
      });
    });

    return lines;
  }, [coreTools, nodePositions]);

  return (
    <div ref={containerRef} className={cn("relative", className)}>
      <motion.div
        initial={reducedMotion ? {} : { opacity: 0, scale: 0.95 }}
        animate={isInView ? { opacity: 1, scale: 1 } : {}}
        transition={{ duration: reducedMotion ? 0 : 0.6 }}
        className="mx-auto max-w-md"
      >
        <svg
          viewBox="0 0 400 400"
          className="h-auto w-full"
          aria-label="Flywheel tool synergy diagram showing connections between core tools"
        >
          {/* All gradient definitions */}
          <defs>
            {/* Background glow */}
            <radialGradient id="centerGlow" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="#a855f7" stopOpacity="0.15" />
              <stop offset="50%" stopColor="#22d3ee" stopOpacity="0.08" />
              <stop offset="100%" stopColor="#22d3ee" stopOpacity="0" />
            </radialGradient>

            {/* Glow filter for lines */}
            <filter id="lineGlow" x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation="2" result="blur" />
              <feMerge>
                <feMergeNode in="blur" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>

            {/* Node shadow */}
            <filter id="nodeShadow" x="-50%" y="-50%" width="200%" height="200%">
              <feDropShadow dx="0" dy="2" stdDeviation="3" floodOpacity="0.3" />
            </filter>

            {/* Tool-specific gradients */}
            {coreTools.map((tool) => {
              const colors = getColorDefinition(tool.color);
              return (
                <linearGradient
                  key={`gradient-${tool.id}`}
                  id={`gradient-${tool.id}`}
                  x1="0%"
                  y1="0%"
                  x2="100%"
                  y2="100%"
                >
                  <stop offset="0%" stopColor={colors.from} />
                  <stop offset="100%" stopColor={colors.to} />
                </linearGradient>
              );
            })}

            {/* Connection-specific gradients - coordinates match line positions */}
            {connections.map((conn) => (
              <linearGradient
                key={`line-gradient-${conn.from}-${conn.to}`}
                id={`line-gradient-${conn.from}-${conn.to}`}
                x1={conn.fromPos.x}
                y1={conn.fromPos.y}
                x2={conn.toPos.x}
                y2={conn.toPos.y}
                gradientUnits="userSpaceOnUse"
              >
                <stop offset="0%" stopColor={conn.fromColor.from} stopOpacity="0.7" />
                <stop offset="50%" stopColor={conn.toColor.from} stopOpacity="0.9" />
                <stop offset="100%" stopColor={conn.toColor.to} stopOpacity="0.7" />
              </linearGradient>
            ))}
          </defs>

          {/* Background glow */}
          <circle cx="200" cy="200" r="190" fill="url(#centerGlow)" />

          {/* Outer ring decoration */}
          <circle
            cx="200"
            cy="200"
            r="175"
            fill="none"
            stroke="url(#centerGlow)"
            strokeWidth="1"
            opacity="0.3"
            strokeDasharray="4 4"
          />

          {/* Connection lines - rendered first so they're behind nodes */}
          <g className="connections">
            {connections.map((conn, index) => (
              <motion.g key={`${conn.from}-${conn.to}`}>
                {/* Glow line (behind) */}
                <motion.line
                  x1={conn.fromPos.x}
                  y1={conn.fromPos.y}
                  x2={conn.toPos.x}
                  y2={conn.toPos.y}
                  stroke={`url(#line-gradient-${conn.from}-${conn.to})`}
                  strokeWidth="4"
                  strokeLinecap="round"
                  filter="url(#lineGlow)"
                  initial={reducedMotion ? { opacity: 0.3 } : { opacity: 0 }}
                  animate={isInView ? { opacity: 0.3 } : {}}
                  transition={{
                    duration: reducedMotion ? 0 : 0.8,
                    delay: reducedMotion ? 0 : 0.3 + index * 0.03,
                  }}
                />
                {/* Main line */}
                <motion.line
                  x1={conn.fromPos.x}
                  y1={conn.fromPos.y}
                  x2={conn.toPos.x}
                  y2={conn.toPos.y}
                  stroke={`url(#line-gradient-${conn.from}-${conn.to})`}
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  initial={reducedMotion ? {} : { opacity: 0, pathLength: 0 }}
                  animate={isInView ? { opacity: 1, pathLength: 1 } : {}}
                  transition={{
                    duration: reducedMotion ? 0 : 0.6,
                    delay: reducedMotion ? 0 : 0.3 + index * 0.03,
                  }}
                />
              </motion.g>
            ))}
          </g>

          {/* Center "Flywheel" hub */}
          <motion.g
            initial={reducedMotion ? {} : { opacity: 0, scale: 0.8 }}
            animate={isInView ? { opacity: 1, scale: 1 } : {}}
            transition={{ duration: reducedMotion ? 0 : 0.5, delay: reducedMotion ? 0 : 0.2 }}
            style={{ transformOrigin: "200px 200px" }}
          >
            {/* Center glow effect */}
            <circle
              cx="200"
              cy="200"
              r="45"
              fill="none"
              stroke="url(#centerGlow)"
              strokeWidth="10"
              opacity="0.5"
            />
            {/* Main circle */}
            <circle
              cx="200"
              cy="200"
              r="38"
              fill="#0d1117"
              stroke="#a855f7"
              strokeWidth="2"
              strokeOpacity="0.5"
              filter="url(#nodeShadow)"
            />
            {/* Inner ring */}
            <circle
              cx="200"
              cy="200"
              r="32"
              fill="none"
              stroke="#22d3ee"
              strokeWidth="1"
              strokeOpacity="0.3"
            />
            <text
              x="200"
              y="196"
              textAnchor="middle"
              fill="#a855f7"
              fontSize="11"
              fontWeight="bold"
              letterSpacing="0.1em"
            >
              FLYWHEEL
            </text>
            <text
              x="200"
              y="212"
              textAnchor="middle"
              fill="#94a3b8"
              fontSize="9"
            >
              {coreTools.length} Core Tools
            </text>
          </motion.g>

          {/* Tool nodes */}
          {coreTools.map((tool, index) => {
            const pos = nodePositions[tool.id];
            if (!pos) return null;
            const colors = getColorDefinition(tool.color);
            // Smaller nodes when we have more tools
            const nodeRadius = coreTools.length > 8 ? 22 : 26;
            const ringRadius = coreTools.length > 8 ? 20 : 24;
            const fontSize = coreTools.length > 8 ? "8px" : "10px";

            return (
              <motion.g
                key={tool.id}
                initial={reducedMotion ? {} : { opacity: 0, scale: 0 }}
                animate={isInView ? { opacity: 1, scale: 1 } : {}}
                transition={{
                  duration: reducedMotion ? 0 : 0.4,
                  delay: reducedMotion ? 0 : 0.4 + index * 0.04,
                  type: "spring",
                  stiffness: 200,
                }}
                style={{ transformOrigin: `${pos.x}px ${pos.y}px` }}
              >
                {/* Outer glow */}
                <circle
                  cx={pos.x}
                  cy={pos.y}
                  r={nodeRadius + 8}
                  fill={colors.from}
                  opacity="0.1"
                />

                {/* Node background */}
                <circle
                  cx={pos.x}
                  cy={pos.y}
                  r={nodeRadius}
                  fill="#0d1117"
                  filter="url(#nodeShadow)"
                />

                {/* Gradient ring */}
                <circle
                  cx={pos.x}
                  cy={pos.y}
                  r={ringRadius}
                  fill="none"
                  stroke={`url(#gradient-${tool.id})`}
                  strokeWidth="2.5"
                />

                {/* Inner accent */}
                <circle
                  cx={pos.x}
                  cy={pos.y}
                  r={ringRadius - 4}
                  fill="none"
                  stroke={colors.from}
                  strokeWidth="0.5"
                  strokeOpacity="0.3"
                />

                {/* Tool label */}
                <text
                  x={pos.x}
                  y={pos.y + 3}
                  textAnchor="middle"
                  fill="#ffffff"
                  fontWeight="bold"
                  fontSize={fontSize}
                >
                  {tool.shortName}
                </text>
              </motion.g>
            );
          })}
        </svg>

        {/* Legend */}
        <motion.div
          initial={reducedMotion ? {} : { opacity: 0, y: 10 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: reducedMotion ? 0 : 0.5, delay: reducedMotion ? 0 : 0.8 }}
          className="mt-6 text-center"
        >
          <p className="text-xs text-muted-foreground">
            Lines show data flow and integration between tools
          </p>
        </motion.div>
      </motion.div>
    </div>
  );
}

export default TldrSynergyDiagram;
