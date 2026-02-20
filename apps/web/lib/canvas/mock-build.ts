import type {
  CanvasState,
  CanvasNodeStatus,
  CanvasAgentStatus,
} from "./types";

// ── Event types ───────────────────────────────────────────────────────

type BuildEvent =
  | { type: "build.started" }
  | {
      type: "agent.status";
      agentId: string;
      status: CanvasAgentStatus;
      message?: string;
      nodeId?: string;
    }
  | { type: "node.status"; nodeId: string; status: CanvasNodeStatus }
  | {
      type: "node.progress";
      nodeId: string;
      current: number;
      total: number;
    }
  | { type: "build.percent"; percent: number }
  | { type: "build.completed" };

// ── Apply event to state ──────────────────────────────────────────────

export function applyBuildEvent(
  state: CanvasState,
  event: BuildEvent,
): CanvasState {
  const now = new Date().toISOString();

  switch (event.type) {
    case "build.started":
      return {
        ...state,
        build: { ...state.build, phase: "running", startedAt: now },
      };

    case "agent.status": {
      const agent = state.agents[event.agentId];
      if (!agent) return state;
      return {
        ...state,
        agents: {
          ...state.agents,
          [event.agentId]: {
            ...agent,
            status: event.status,
            message: event.message ?? agent.message,
            currentNodeId: event.nodeId ?? agent.currentNodeId,
            updatedAt: now,
          },
        },
      };
    }

    case "node.status": {
      const node = state.nodesById[event.nodeId];
      if (!node) return state;
      return {
        ...state,
        nodesById: {
          ...state.nodesById,
          [event.nodeId]: { ...node, status: event.status },
        },
      };
    }

    case "node.progress": {
      const node = state.nodesById[event.nodeId];
      if (!node) return state;
      return {
        ...state,
        nodesById: {
          ...state.nodesById,
          [event.nodeId]: {
            ...node,
            progress: { current: event.current, total: event.total },
          },
        },
      };
    }

    case "build.percent":
      return {
        ...state,
        build: { ...state.build, percent: event.percent },
      };

    case "build.completed":
      return {
        ...state,
        build: {
          ...state.build,
          phase: "complete",
          percent: 100,
          finishedAt: now,
        },
      };
  }
}

// ── Mock build simulation ─────────────────────────────────────────────

let activeRunId = 0;

function delay(min = 600, max = 1200): Promise<void> {
  const ms = Math.floor(Math.random() * (max - min + 1)) + min;
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function startMockBuild(
  state: CanvasState,
  onEvent: (event: BuildEvent) => void,
): { stop: () => void } {
  const runId = ++activeRunId;
  const nodeIds = Object.keys(state.nodesById);
  const agentIds = Object.keys(state.agents);
  let stopped = false;

  function isStale() {
    return stopped || runId !== activeRunId;
  }

  async function run() {
    // Start build
    onEvent({ type: "build.started" });
    await delay(400, 800);
    if (isStale()) return;

    // Planner phase
    onEvent({
      type: "agent.status",
      agentId: "planner",
      status: "thinking",
      message: "Analyzing project structure…",
    });
    await delay(1000, 1500);
    if (isStale()) return;

    // Queue all nodes
    for (const nodeId of nodeIds) {
      onEvent({ type: "node.status", nodeId, status: "queued" });
    }
    await delay(400, 600);
    if (isStale()) return;

    onEvent({
      type: "agent.status",
      agentId: "planner",
      status: "done",
      message: "Plan ready",
    });
    onEvent({ type: "build.percent", percent: 5 });

    // Build each node sequentially with agent assignments
    const totalNodes = nodeIds.length;

    for (let i = 0; i < totalNodes; i++) {
      if (isStale()) return;
      const nodeId = nodeIds[i];
      const node = state.nodesById[nodeId];
      const agentId = agentIds[i % agentIds.length];

      // Agent starts working on node
      onEvent({
        type: "agent.status",
        agentId,
        status: "working",
        message: `Building ${node.title}…`,
        nodeId,
      });
      onEvent({ type: "node.status", nodeId, status: "building" });
      await delay(500, 800);
      if (isStale()) return;

      // Simulate progress steps
      const totalSteps = node.progress.total;
      for (let step = 1; step <= totalSteps; step++) {
        if (isStale()) return;
        onEvent({
          type: "node.progress",
          nodeId,
          current: step,
          total: totalSteps,
        });
        await delay(300, 700);
      }
      if (isStale()) return;

      // Node complete
      onEvent({ type: "node.status", nodeId, status: "ready" });
      onEvent({
        type: "agent.status",
        agentId,
        status: "idle",
        message: `Finished ${node.title}`,
      });

      const percent = Math.round(5 + ((i + 1) / totalNodes) * 90);
      onEvent({ type: "build.percent", percent });
      await delay(300, 500);
    }

    if (isStale()) return;

    // Review phase
    onEvent({
      type: "agent.status",
      agentId: "reviewer",
      status: "working",
      message: "Running final checks…",
    });
    onEvent({ type: "build.percent", percent: 97 });
    await delay(1000, 1500);
    if (isStale()) return;

    onEvent({
      type: "agent.status",
      agentId: "reviewer",
      status: "done",
      message: "All checks passed",
    });
    onEvent({ type: "build.completed" });
  }

  run();

  return {
    stop() {
      stopped = true;
    },
  };
}
