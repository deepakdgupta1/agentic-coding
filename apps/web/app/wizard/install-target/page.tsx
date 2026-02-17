"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Monitor, Server, ShieldCheck, HardDrive } from "lucide-react";
import { Button } from "@/components/ui/button";
import { markStepComplete, getCompletedSteps, setCompletedSteps } from "@/lib/wizardSteps";
import { useWizardAnalytics } from "@/lib/hooks/useWizardAnalytics";
import { withCurrentSearch } from "@/lib/utils";
import { cn } from "@/lib/utils";
import {
  useUserOS,
  useInstallTarget,
  type InstallTarget,
} from "@/lib/userPreferences";
import {
  SimplerGuide,
  GuideSection,
  GuideExplain,
  GuideTip,
} from "@/components/simpler-guide";

interface TargetCardProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  selected: boolean;
  onClick: () => void;
}

function TargetCard({ icon, title, description, selected, onClick }: TargetCardProps) {
  return (
    <button
      type="button"
      className={cn(
        "group relative flex w-full flex-col items-center gap-4 rounded-2xl border p-8 text-center transition-all duration-300",
        selected
          ? "border-primary bg-primary/10 shadow-lg shadow-primary/10"
          : "border-border/50 bg-card/50 hover:border-primary/30 hover:bg-card/80 hover:shadow-md"
      )}
      onClick={onClick}
      role="radio"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          onClick();
        }
      }}
      aria-checked={selected}
    >
      {selected && (
        <>
          <div className="absolute inset-0 rounded-2xl bg-gradient-to-b from-primary/20 to-transparent opacity-50" />
          <div className="absolute -inset-px rounded-2xl bg-gradient-to-b from-primary/50 to-primary/0 opacity-0 transition-opacity group-hover:opacity-100" />
        </>
      )}

      <div
        className={cn(
          "relative flex h-20 w-20 items-center justify-center rounded-2xl transition-all duration-300",
          selected
            ? "bg-primary text-primary-foreground shadow-lg shadow-primary/30"
            : "bg-muted text-muted-foreground group-hover:bg-muted/80 group-hover:text-foreground"
        )}
      >
        {icon}
      </div>

      <div className="relative">
        <h3 className="text-xl font-bold tracking-tight text-foreground">{title}</h3>
        <p className="mt-1 text-sm text-muted-foreground">{description}</p>
      </div>
    </button>
  );
}

export default function InstallTargetPage() {
  const router = useRouter();
  const [userOS, , osLoaded] = useUserOS();
  const [installTarget, setInstallTarget, targetLoaded] = useInstallTarget();
  const [selectedTargetOverride, setSelectedTargetOverride] =
    useState<InstallTarget | null>(null);
  const selectedTarget =
    selectedTargetOverride ?? (targetLoaded ? installTarget : null);
  const [isNavigating, setIsNavigating] = useState(false);
  const [showError, setShowError] = useState(false);

  // Analytics tracking for this wizard step
  const { markComplete } = useWizardAnalytics({
    step: "install_target",
    stepNumber: 2,
    stepTitle: "Choose Install Target",
  });

  useEffect(() => {
    if (!osLoaded) return;
    if (!userOS) {
      router.replace(withCurrentSearch("/wizard/os-selection"));
      return;
    }
    if (userOS !== "linux") {
      setInstallTarget("vps");
      markStepComplete(2);
      router.replace(withCurrentSearch("/wizard/install-terminal"));
    }
  }, [osLoaded, userOS, router, setInstallTarget]);

  const handleContinue = useCallback(() => {
    if (!selectedTarget) {
      setShowError(true);
      return;
    }

    setInstallTarget(selectedTarget);
    markComplete({ install_target: selectedTarget });
    markStepComplete(2);
    setIsNavigating(true);

    if (selectedTarget === "local") {
      const completed = getCompletedSteps();
      const skipSteps = [3, 4, 5, 6, 7];
      const nextSteps = Array.from(new Set([...completed, 2, ...skipSteps])).sort(
        (a, b) => a - b
      );
      setCompletedSteps(nextSteps);
      router.push(withCurrentSearch("/wizard/accounts"));
      return;
    }

    // VPS path on Linux: skip terminal install (already have one)
    markStepComplete(3);
    router.push(withCurrentSearch("/wizard/generate-ssh-key"));
  }, [selectedTarget, setInstallTarget, markComplete, router]);

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="space-y-2">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/20">
            <ShieldCheck className="h-5 w-5 text-primary" />
          </div>
          <div>
            <h1 className="bg-gradient-to-r from-foreground via-foreground to-muted-foreground bg-clip-text text-2xl font-bold tracking-tight text-transparent sm:text-3xl">
              Where should ACFS run?
            </h1>
            <p className="text-sm text-muted-foreground">
              ~30 sec
            </p>
          </div>
        </div>
        <p className="text-muted-foreground">
          Linux can run ACFS either on a remote VPS or locally in a sandboxed container.
        </p>
      </div>

      {showError && (
        <div className="rounded-xl border border-destructive/40 bg-destructive/10 p-4 text-sm text-destructive">
          Select an install target to continue.
        </div>
      )}

      {/* Target options */}
      <div className="grid gap-6 sm:grid-cols-2" role="radiogroup" aria-label="Select install target">
        <TargetCard
          icon={<Server className="h-10 w-10" />}
          title="Remote VPS"
          description="Recommended for long-running agent workloads and collaboration"
          selected={selectedTarget === "vps"}
          onClick={() => {
            setSelectedTargetOverride("vps");
            setShowError(false);
          }}
        />
        <TargetCard
          icon={<Monitor className="h-10 w-10" />}
          title="Local Desktop (Sandboxed)"
          description="Runs in an LXD container on your Ubuntu machine"
          selected={selectedTarget === "local"}
          onClick={() => {
            setSelectedTargetOverride("local");
            setShowError(false);
          }}
        />
      </div>

      <div className="rounded-xl border border-border/30 bg-muted/30 p-4">
        <p className="text-sm text-muted-foreground">
          <span className="font-medium text-foreground">Tip:</span>{" "}
          Local desktop mode is great for experimenting safely. VPS mode is best for always-on agents and team setups.
        </p>
      </div>

      <SimplerGuide>
        <GuideSection title="What is Local Desktop mode?">
          <p>
            ACFS runs inside an <strong>isolated LXD container</strong>. Your host OS stays clean while the container
            gets the full ACFS setup.
          </p>
        </GuideSection>
        <GuideExplain term="LXD container">
          A system container that looks like a full Ubuntu machine. It&apos;s lighter than a VM, but still isolated from
          your host system.
        </GuideExplain>
        <GuideTip>
          <div className="flex items-start gap-2">
            <HardDrive className="mt-0.5 h-4 w-4" />
            <span>Local mode needs ~10GB disk space and Ubuntu 22.04+.</span>
          </div>
        </GuideTip>
      </SimplerGuide>

      <div className="flex justify-end">
        <Button onClick={handleContinue} disabled={isNavigating}>
          {isNavigating ? "Loading..." : "Continue"}
        </Button>
      </div>
    </div>
  );
}
