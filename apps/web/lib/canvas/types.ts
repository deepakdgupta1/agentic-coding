export type CanvasWizardStep =
  | "description"
  | "questions"
  | "type"
  | "review"
  | "canvas";

// ── Canvas (Epic 2) types ─────────────────────────────────────────────

export type CanvasComponentKind =
  | "frontend"
  | "backend"
  | "database"
  | "auth"
  | "integration"
  | "config";

export type CanvasNodeStatus =
  | "idle"
  | "queued"
  | "building"
  | "ready"
  | "error";

export type CanvasAgentStatus =
  | "idle"
  | "thinking"
  | "working"
  | "blocked"
  | "done";

export type CanvasEdge = {
  id: string;
  from: string;
  to: string;
  label?: string;
};

export type CanvasComponentNode = {
  id: string;
  kind: CanvasComponentKind;
  title: string;
  subtitle?: string;
  description?: string;
  x: number;
  y: number;
  status: CanvasNodeStatus;
  progress: { current: number; total: number };
};

export type CanvasAgent = {
  id: string;
  label: string;
  type: "claude" | "codex" | "gemini";
  status: CanvasAgentStatus;
  currentNodeId?: string;
  message?: string;
  updatedAt: string;
};

export type CanvasBuildPhase =
  | "not_started"
  | "running"
  | "complete"
  | "failed";

export type CanvasBuild = {
  phase: CanvasBuildPhase;
  percent: number;
  startedAt?: string;
  finishedAt?: string;
};

export type CanvasState = {
  nodesById: Record<string, CanvasComponentNode>;
  edges: CanvasEdge[];
  agents: Record<string, CanvasAgent>;
  build: CanvasBuild;
  selectedNodeId?: string;
};

export type ProjectType =
  | "web_app"
  | "rest_api"
  | "full_stack"
  | "static_site"
  | "internal_tool";

export const PROJECT_TYPES: {
  type: ProjectType;
  label: string;
  description: string;
  example: string;
  icon: string;
}[] = [
  {
    type: "web_app",
    label: "Web Application",
    description: "Browser-based app with UI",
    example: "Dashboard, SaaS product",
    icon: "🖥️",
  },
  {
    type: "rest_api",
    label: "REST API",
    description: "Backend service with endpoints",
    example: "Data service, integration layer",
    icon: "⚙️",
  },
  {
    type: "full_stack",
    label: "Full-Stack",
    description: "Frontend + Backend + Database",
    example: "Complete product",
    icon: "🏗️",
  },
  {
    type: "static_site",
    label: "Static Site",
    description: "Content-focused, minimal interactivity",
    example: "Landing page, docs site",
    icon: "📄",
  },
  {
    type: "internal_tool",
    label: "Internal Tool",
    description: "Admin/ops focused functionality",
    example: "Data viewer, config manager",
    icon: "🔧",
  },
];

export type CanvasQuestionType = "single_select" | "multi_select" | "free_text";

export type CanvasQuestionOption = {
  id: string;
  label: string;
  helper?: string;
};

export type CanvasQuestion = {
  id: string;
  prompt: string;
  type: CanvasQuestionType;
  options?: CanvasQuestionOption[];
};

export type CanvasAnswer = {
  questionId: string;
  value: string | string[];
  context?: string;
};

export type CanvasSpecification = {
  project: {
    name: string;
    description: string;
    type: ProjectType;
  };
  users: {
    primary: string;
    secondary?: string;
  };
  features: {
    core: string[];
    niceToHave: string[];
  };
  technical: {
    frontend?: string;
    backend?: string;
    database?: string;
    deployment?: string;
    integrations?: string[];
  };
};

export type CanvasProject = {
  version: 1;
  id: string;
  createdAt: string;
  updatedAt: string;
  step: CanvasWizardStep;

  vision: {
    description: string;
    moreDetailsEnabled: boolean;
    targetUsers?: string;
    keyFeatures?: string;
    examples?: string;
  };

  clarification: {
    questions: CanvasQuestion[];
    answers: CanvasAnswer[];
    activeQuestionIndex: number;
  };

  typeSelection: {
    recommendedType?: ProjectType;
    recommendationRationale?: string;
    selectedType?: ProjectType;
    overrideReason?: string;
  };

  spec: {
    draft?: CanvasSpecification;
  };

  canvas?: CanvasState;
};
