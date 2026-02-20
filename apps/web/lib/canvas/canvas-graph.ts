import type {
  CanvasSpecification,
  CanvasComponentNode,
  CanvasEdge,
  CanvasAgent,
  CanvasState,
  CanvasComponentKind,
  ProjectType,
} from "./types";

// ── Node metadata ─────────────────────────────────────────────────────

type NodeTemplate = {
  id: string;
  kind: CanvasComponentKind;
  title: string;
  description: string;
  taskCount: number;
};

const NODE_TEMPLATES: Record<string, NodeTemplate> = {
  frontend: {
    id: "frontend",
    kind: "frontend",
    title: "Frontend",
    description: "User interface and client-side application",
    taskCount: 5,
  },
  backend: {
    id: "backend",
    kind: "backend",
    title: "Backend",
    description: "API routes, services, and business logic",
    taskCount: 6,
  },
  database: {
    id: "database",
    kind: "database",
    title: "Database",
    description: "Data models, schemas, and migrations",
    taskCount: 4,
  },
  auth: {
    id: "auth",
    kind: "auth",
    title: "Auth",
    description: "Authentication, sessions, and permissions",
    taskCount: 4,
  },
  config: {
    id: "config",
    kind: "config",
    title: "Config",
    description: "Environment variables, settings, and tooling",
    taskCount: 2,
  },
};

const TYPE_TEMPLATES: Record<ProjectType, string[]> = {
  static_site: ["frontend", "config"],
  rest_api: ["backend", "database", "config"],
  web_app: ["frontend", "backend", "database", "config"],
  full_stack: ["frontend", "backend", "database", "config"],
  internal_tool: ["frontend", "backend", "database", "config"],
};

// ── Layout constants ──────────────────────────────────────────────────

const NODE_W = 160;
const NODE_H = 100;
const COL_GAP = 220;
const ROW_GAP = 140;
const PADDING_X = 80;
const PADDING_Y = 60;

type ColumnSlot = { col: number; row: number };

const KIND_COLUMNS: Record<CanvasComponentKind, number> = {
  frontend: 0,
  auth: 1,
  backend: 1,
  integration: 2,
  database: 2,
  config: 3,
};

function layoutNodes(
  nodes: Omit<CanvasComponentNode, "x" | "y">[],
): CanvasComponentNode[] {
  const columnCounts: Record<number, number> = {};
  const slots: ColumnSlot[] = [];

  for (const node of nodes) {
    const col = KIND_COLUMNS[node.kind];
    const row = columnCounts[col] ?? 0;
    columnCounts[col] = row + 1;
    slots.push({ col, row });
  }

  return nodes.map((node, i) => ({
    ...node,
    x: PADDING_X + slots[i].col * COL_GAP + NODE_W / 2,
    y: PADDING_Y + slots[i].row * ROW_GAP + NODE_H / 2,
  }));
}

// ── Derive graph from spec ────────────────────────────────────────────

function needsAuth(spec: CanvasSpecification): boolean {
  const features = [
    ...spec.features.core,
    ...spec.features.niceToHave,
  ].join(" ").toLowerCase();
  return /auth|login|sign.?in|account|session|permission/i.test(features);
}

function getIntegrations(spec: CanvasSpecification): string[] {
  return spec.technical.integrations ?? [];
}

export function deriveCanvasState(spec: CanvasSpecification): CanvasState {
  const baseIds = TYPE_TEMPLATES[spec.project.type] ?? TYPE_TEMPLATES.web_app;
  const nodeIds = [...baseIds];

  if (needsAuth(spec) && !nodeIds.includes("auth")) {
    const backendIdx = nodeIds.indexOf("backend");
    if (backendIdx >= 0) {
      nodeIds.splice(backendIdx + 1, 0, "auth");
    } else {
      nodeIds.push("auth");
    }
  }

  const integrations = getIntegrations(spec);

  // Build nodes
  const rawNodes: Omit<CanvasComponentNode, "x" | "y">[] = nodeIds.map(
    (id) => {
      const tpl = NODE_TEMPLATES[id];
      if (!tpl) {
        return {
          id,
          kind: "config" as CanvasComponentKind,
          title: id,
          description: "",
          status: "idle" as const,
          progress: { current: 0, total: 2 },
        };
      }
      const subtitle = getSubtitle(id, spec);
      return {
        id: tpl.id,
        kind: tpl.kind,
        title: tpl.title,
        subtitle,
        description: tpl.description,
        status: "idle" as const,
        progress: { current: 0, total: tpl.taskCount },
      };
    },
  );

  // Add integration nodes
  for (const name of integrations) {
    const slug = `integration:${name.toLowerCase().replace(/\s+/g, "-")}`;
    rawNodes.push({
      id: slug,
      kind: "integration",
      title: name,
      subtitle: "External API",
      description: `Integration with ${name}`,
      status: "idle",
      progress: { current: 0, total: 3 },
    });
  }

  const nodes = layoutNodes(rawNodes);

  // Build edges
  const edges: CanvasEdge[] = [];
  const nodeSet = new Set(nodes.map((n) => n.id));

  function addEdge(from: string, to: string, label?: string) {
    if (nodeSet.has(from) && nodeSet.has(to)) {
      edges.push({ id: `${from}->${to}`, from, to, label });
    }
  }

  addEdge("frontend", "backend", "API calls");
  addEdge("backend", "database", "Reads/writes");
  addEdge("backend", "auth", "Validates");
  addEdge("frontend", "auth", "Login flow");

  for (const name of integrations) {
    const slug = `integration:${name.toLowerCase().replace(/\s+/g, "-")}`;
    addEdge("backend", slug, "Connects");
  }

  // Build nodesById
  const nodesById: Record<string, CanvasComponentNode> = {};
  for (const node of nodes) {
    nodesById[node.id] = node;
  }

  const now = new Date().toISOString();
  const agents: Record<string, CanvasAgent> = {
    planner: {
      id: "planner",
      label: "Planner",
      type: "claude",
      status: "idle",
      message: "Ready to plan",
      updatedAt: now,
    },
    builder: {
      id: "builder",
      label: "Builder",
      type: "codex",
      status: "idle",
      message: "Ready to build",
      updatedAt: now,
    },
    reviewer: {
      id: "reviewer",
      label: "Reviewer",
      type: "gemini",
      status: "idle",
      message: "Ready to review",
      updatedAt: now,
    },
  };

  return {
    nodesById,
    edges,
    agents,
    build: { phase: "not_started", percent: 0 },
  };
}

function getSubtitle(
  nodeId: string,
  spec: CanvasSpecification,
): string | undefined {
  switch (nodeId) {
    case "frontend":
      return spec.technical.frontend ?? "React + TypeScript";
    case "backend":
      return spec.technical.backend ?? "Node.js API";
    case "database":
      return spec.technical.database ?? "PostgreSQL";
    case "config":
      return spec.technical.deployment ?? "Vercel";
    default:
      return undefined;
  }
}

// ── Canvas dimensions helper ──────────────────────────────────────────

export function getCanvasBounds(state: CanvasState): {
  width: number;
  height: number;
} {
  let maxX = 0;
  let maxY = 0;
  for (const node of Object.values(state.nodesById)) {
    if (node.x + NODE_W / 2 > maxX) maxX = node.x + NODE_W / 2;
    if (node.y + NODE_H / 2 > maxY) maxY = node.y + NODE_H / 2;
  }
  return {
    width: maxX + PADDING_X,
    height: maxY + PADDING_Y,
  };
}

export { NODE_W, NODE_H };
