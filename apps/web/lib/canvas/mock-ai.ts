import type {
  CanvasAnswer,
  CanvasQuestion,
  CanvasSpecification,
  ProjectType,
} from "./types";

function delay(min = 600, max = 1200): Promise<void> {
  const ms = Math.floor(Math.random() * (max - min + 1)) + min;
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function toPascalCase(str: string): string {
  return str
    .split(/[\s_-]+/)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join("");
}

function generateProjectName(description: string): string {
  const words = description
    .replace(/[^a-zA-Z\s]/g, "")
    .split(/\s+/)
    .filter((w) => w.length > 3)
    .slice(0, 2);
  if (words.length === 0) return "MyProject";
  return toPascalCase(words.join(" "));
}

export async function mockGenerateQuestions(
  description: string,
): Promise<CanvasQuestion[]> {
  await delay();

  const questions: CanvasQuestion[] = [
    {
      id: "q-users",
      prompt: "Who will use this application?",
      type: "single_select",
      options: [
        {
          id: "internal",
          label: "Internal team",
          helper: "Your company's employees",
        },
        {
          id: "customers",
          label: "Customers",
          helper: "External users or clients",
        },
        {
          id: "both",
          label: "Both",
          helper: "Internal team and external users",
        },
        { id: "other", label: "Other" },
      ],
    },
    {
      id: "q-important-feature",
      prompt: "What's the most important feature?",
      type: "free_text",
      options: [
        { id: "realtime", label: "Real-time updates" },
        { id: "dashboard", label: "Dashboard & analytics" },
        { id: "auth", label: "User accounts & login" },
        { id: "data-management", label: "Data management" },
      ],
    },
    {
      id: "q-auth",
      prompt: "Do you need user authentication?",
      type: "single_select",
      options: [
        { id: "email", label: "Yes, email/password" },
        { id: "social", label: "Yes, social login" },
        { id: "no", label: "No" },
        { id: "unsure", label: "Not sure" },
      ],
    },
    {
      id: "q-platform",
      prompt: "Where should this be deployed?",
      type: "single_select",
      options: [
        { id: "web", label: "Web only" },
        { id: "web-mobile", label: "Web + Mobile" },
        { id: "internal", label: "Internal tool" },
      ],
    },
  ];

  const hasIntegrationKeywords =
    /api|integrat|stripe|slack|google|webhook|third.?party/i.test(description);
  if (hasIntegrationKeywords) {
    questions.push({
      id: "q-integrations",
      prompt: "Any specific integrations needed?",
      type: "multi_select",
      options: [
        { id: "stripe", label: "Stripe (payments)" },
        { id: "google", label: "Google (auth/calendar)" },
        { id: "slack", label: "Slack" },
        { id: "email-service", label: "Email service" },
        { id: "other", label: "Other" },
      ],
    });
  }

  return questions;
}

export async function mockRecommendType(
  description: string,
  answers: CanvasAnswer[],
): Promise<{ type: ProjectType; rationale: string }> {
  await delay(400, 800);

  const text = description.toLowerCase();
  const platformAnswer = answers.find((a) => a.questionId === "q-platform");
  const authAnswer = answers.find((a) => a.questionId === "q-auth");

  if (platformAnswer?.value === "internal") {
    return {
      type: "internal_tool",
      rationale:
        "Based on your target deployment as an internal tool, this project type provides the right foundation for admin-focused functionality.",
    };
  }

  if (
    /landing|blog|portfolio|docs|documentation|static/i.test(text) &&
    authAnswer?.value === "no"
  ) {
    return {
      type: "static_site",
      rationale:
        "Your project description suggests a content-focused site with minimal interactivity, making a static site the ideal choice.",
    };
  }

  if (
    /api|backend|service|endpoint|microservice/i.test(text) &&
    !/ui|frontend|page|dashboard/i.test(text)
  ) {
    return {
      type: "rest_api",
      rationale:
        "Your project focuses on backend services and API endpoints without a frontend component.",
    };
  }

  if (
    /dashboard|app|platform|saas|tool/i.test(text) &&
    authAnswer?.value !== "no"
  ) {
    return {
      type: "full_stack",
      rationale:
        "Your project requires both a frontend interface and backend logic with data persistence, making a full-stack approach the best fit.",
    };
  }

  return {
    type: "web_app",
    rationale:
      "Based on your description, a web application provides the right balance of interactivity and deployment simplicity.",
  };
}

export async function mockGenerateSpec(
  description: string,
  answers: CanvasAnswer[],
  selectedType: ProjectType,
): Promise<CanvasSpecification> {
  await delay(800, 1500);

  const name = generateProjectName(description);

  const userAnswer = answers.find((a) => a.questionId === "q-users");
  const featureAnswer = answers.find(
    (a) => a.questionId === "q-important-feature",
  );
  const authAnswer = answers.find((a) => a.questionId === "q-auth");
  const integrationAnswer = answers.find(
    (a) => a.questionId === "q-integrations",
  );

  const primaryUsers =
    userAnswer?.value === "internal"
      ? "Internal team members"
      : userAnswer?.value === "customers"
        ? "End users and customers"
        : userAnswer?.value === "both"
          ? "Internal team and external customers"
          : "General users";

  const coreFeatures: string[] = [];

  if (authAnswer?.value === "email" || authAnswer?.value === "social") {
    coreFeatures.push("User authentication and account management");
  }

  if (featureAnswer) {
    const val =
      typeof featureAnswer.value === "string"
        ? featureAnswer.value
        : featureAnswer.value[0];
    if (val) coreFeatures.push(val);
  }

  if (coreFeatures.length === 0) {
    coreFeatures.push("Core application functionality");
  }
  coreFeatures.push("Responsive user interface");
  coreFeatures.push("Data persistence and management");

  const niceToHave: string[] = ["Email notifications", "Activity logging"];
  if (integrationAnswer && Array.isArray(integrationAnswer.value)) {
    for (const v of integrationAnswer.value) {
      niceToHave.push(`${v} integration`);
    }
  }

  const techStack: CanvasSpecification["technical"] = {};
  if (selectedType !== "rest_api") {
    techStack.frontend = "React with TypeScript";
  }
  if (selectedType !== "static_site") {
    techStack.backend = "Node.js API";
    techStack.database = "PostgreSQL";
  }
  techStack.deployment =
    selectedType === "static_site" ? "Vercel" : "Vercel + Railway";

  return {
    project: {
      name,
      description: description.slice(0, 200),
      type: selectedType,
    },
    users: {
      primary: primaryUsers,
    },
    features: {
      core: coreFeatures,
      niceToHave,
    },
    technical: techStack,
  };
}
