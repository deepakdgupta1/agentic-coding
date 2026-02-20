import { CanvasWizard } from "@/components/canvas/canvas-wizard";

export const metadata = {
  title: "Canvas - Build Your Project",
  description: "Guide your AI agents to build your software project.",
};

export default async function CanvasProjectPage({
  params,
}: {
  params: Promise<{ projectId: string }>;
}) {
  const { projectId } = await params;
  return <CanvasWizard projectId={projectId} />;
}
