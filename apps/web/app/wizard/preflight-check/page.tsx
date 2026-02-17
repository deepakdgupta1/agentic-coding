"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { ShieldCheck, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { CommandCard } from "@/components/command-card";
import { AlertCard, OutputPreview, DetailsSection } from "@/components/alert-card";
import { ConnectionCheck } from "@/components/connection-check";
import { markStepComplete } from "@/lib/wizardSteps";
import { useWizardAnalytics } from "@/lib/hooks/useWizardAnalytics";
import { useInstallTarget, useVPSIP } from "@/lib/userPreferences";
import { withCurrentSearch } from "@/lib/utils";
import {
  SimplerGuide,
  GuideSection,
  GuideStep,
  GuideExplain,
  GuideCaution,
} from "@/components/simpler-guide";
import { Jargon } from "@/components/jargon";

const VPS_PREFLIGHT_COMMAND =
  "curl -fsSL \"https://raw.githubusercontent.com/deepakdgupta1/agentic-coding/main/scripts/preflight.sh?$(date +%s)\" | bash";
const LOCAL_PREFLIGHT_COMMAND =
  "./scripts/local/lxd_bootstrap.sh --check";

const VPS_TROUBLESHOOTING = [
  {
    title: "'bash' is not recognized / Get-Date error (Windows)",
    fixes: [
      "You're running this on your Windows computer, not on the VPS!",
      "First, connect to your VPS with: ssh root@YOUR_VPS_IP",
      "Wait until you see 'root@vps:~#' or similar",
      "THEN paste the preflight command",
      "The preflight command only works on the Linux VPS, not on Windows",
    ],
  },
  {
    title: "APT is locked by another process",
    fixes: [
      "Wait 1-2 minutes (auto updates often finish quickly)",
      "If it keeps failing: sudo killall apt apt-get",
      "Optional: sudo systemctl stop unattended-upgrades",
    ],
  },
  {
    title: "Cannot reach github.com (network/firewall)",
    fixes: [
      "Check that your VPS has outbound internet access",
      "Retry in a minute (provider networking sometimes lags)",
      "If on a corporate network, check firewall rules",
    ],
  },
  {
    title: "Insufficient disk space",
    fixes: [
      "Upgrade your VPS storage plan (recommended 20GB+ free)",
      "If you just created the VPS, choose a larger disk size",
    ],
  },
  {
    title: "Unsupported architecture",
    fixes: [
      "Use x86_64 or aarch64 VPS images",
      "Most providers default to x86_64 if not specified",
    ],
  },
];

const LOCAL_TROUBLESHOOTING = [
  {
    title: "LXD not installed or not initialized",
    fixes: [
      "Run: ./scripts/local/lxd_bootstrap.sh",
      "This installs LXD (via snap) and initializes it for you",
    ],
  },
  {
    title: "You are not in the lxd group",
    fixes: [
      "Log out and back in, or run: newgrp lxd",
      "Then re-run the preflight check",
    ],
  },
  {
    title: "snap not installed",
    fixes: [
      "Install snapd: sudo apt install snapd",
      "Then re-run ./scripts/local/lxd_bootstrap.sh",
    ],
  },
  {
    title: "Insufficient disk space",
    fixes: [
      "Ensure ~10GB free on your Ubuntu machine",
      "The container lives under your home directory by default",
    ],
  },
  {
    title: "Low memory",
    fixes: [
      "4GB+ RAM recommended for a smooth local experience",
      "Close heavy apps before running the installer",
    ],
  },
];

export default function PreflightCheckPage() {
  const router = useRouter();
  const [installTarget] = useInstallTarget();
  const [vpsIP] = useVPSIP();
  const [ackPassed, setAckPassed] = useState(false);
  const [ackFailed, setAckFailed] = useState(false);
  const [isNavigating, setIsNavigating] = useState(false);
  const isLocal = installTarget === "local";

  // Analytics tracking for this wizard step
  const { markComplete } = useWizardAnalytics({
    step: "preflight_check",
    stepNumber: 9,
    stepTitle: "Pre-Flight Check",
  });

  const displayIP = vpsIP || "YOUR_VPS_IP";
  const preflightCommand = isLocal ? LOCAL_PREFLIGHT_COMMAND : VPS_PREFLIGHT_COMMAND;
  const troubleshooting = isLocal ? LOCAL_TROUBLESHOOTING : VPS_TROUBLESHOOTING;

  const canContinue = ackPassed || ackFailed;

  const goNext = useCallback(() => {
    markComplete();
    markStepComplete(9);
    setIsNavigating(true);
    router.push(withCurrentSearch("/wizard/run-installer"));
  }, [router, markComplete]);

  const handleContinue = useCallback(() => {
    if (!canContinue) return;
    goNext();
  }, [canContinue, goNext]);

  const handleSkip = useCallback(() => {
    goNext();
  }, [goNext]);

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
              {isLocal ? "Pre-flight check your local sandbox" : "Pre-flight check your VPS"}
            </h1>
            <p className="text-sm text-muted-foreground">
              ~1 min
            </p>
          </div>
        </div>
        <p className="text-muted-foreground">
          {isLocal
            ? "Before installing, let's confirm your Ubuntu machine can run the ACFS sandbox."
            : <>Before installing, let&apos;s confirm your <Jargon term="vps">VPS</Jargon> is ready.</>}
        </p>
      </div>

      {/* CRITICAL: Connection check */}
      {!isLocal && <ConnectionCheck vpsIP={displayIP} showExplainer showWhereAmI />}

      {/* Why this matters */}
      <AlertCard variant="info" icon={ShieldCheck} title="Fast safety check">
        This quick scan validates OS, disk space, network access, and APT locks.
        Warnings are okay — you can still continue.
      </AlertCard>

      {/* Windows-specific warning - CRITICAL for confused users */}
      {!isLocal && (
        <AlertCard variant="error" icon={AlertTriangle} title="Windows users: Common mistake!">
          <div className="space-y-2">
            <p>
              If you paste this command and see errors like <code className="rounded bg-muted px-1 py-0.5 font-mono text-xs">&apos;bash&apos; is not recognized</code> or
              <code className="rounded bg-muted px-1 py-0.5 font-mono text-xs">Get-Date : Cannot bind parameter</code>:
            </p>
            <p className="font-semibold">
              You&apos;re running this on your Windows computer, NOT on the VPS!
            </p>
            <p>
              Go back to your terminal, type <code className="rounded bg-muted px-1.5 py-0.5 font-mono text-xs">ssh root@{displayIP}</code>,
              enter your VPS password, and THEN paste the preflight command.
            </p>
          </div>
        </AlertCard>
      )}

      {/* Command */}
      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Run this command</h2>
        {isLocal && (
          <AlertCard variant="info" title="Local mode requires the repo on your machine">
            <p className="text-sm text-muted-foreground">
              Run the check from the ACFS repo root. If you haven&apos;t cloned it yet, do that first.
            </p>
          </AlertCard>
        )}
        {isLocal && (
          <CommandCard
            command="git clone https://github.com/deepakdgupta1/agentic-coding.git"
            description="Clone the ACFS repo (one-time)"
            runLocation="local"
            showCheckbox
            persistKey="local-clone-repo"
          />
        )}
        <CommandCard
          command={preflightCommand}
          description={isLocal ? "Local pre-flight check (run from repo root)" : "ACFS pre-flight validation"}
          runLocation={isLocal ? "local" : "vps"}
          showCheckbox
          persistKey="preflight-check"
        />
      </div>

      {/* Expected output */}
      {isLocal ? (
        <OutputPreview title="Expected output (example)">
          <div className="space-y-1 font-mono text-xs">
            <p className="text-muted-foreground">ACFS Local Prerequisites Check</p>
            <p className="text-muted-foreground">==============================</p>
            <p className="text-[oklch(0.72_0.19_145)]">✓ Ubuntu 22.04+ detected</p>
            <p className="text-[oklch(0.72_0.19_145)]">✓ snap available</p>
            <p className="text-[oklch(0.72_0.19_145)]">✓ LXD installed and initialized</p>
            <p className="text-[oklch(0.72_0.19_145)]">✓ Disk space: 20GB free</p>
            <p className="text-muted-foreground">All prerequisites met!</p>
          </div>
        </OutputPreview>
      ) : (
        <OutputPreview title="Expected output (example)">
          <div className="space-y-1 font-mono text-xs">
            <p className="text-muted-foreground">ACFS Pre-Flight Check</p>
            <p className="text-muted-foreground">=====================</p>
            <p className="text-[oklch(0.72_0.19_145)]">[✓] Operating System: Ubuntu 25.10 (or 24.04 before upgrade)</p>
            <p className="text-[oklch(0.72_0.19_145)]">[✓] Architecture: x86_64</p>
            <p className="text-[oklch(0.72_0.19_145)]">[✓] Disk Space: 45GB free</p>
            <p className="text-[oklch(0.78_0.16_75)]">[!] Warning: Cannot reach https://claude.ai</p>
            <p className="text-muted-foreground">Result: 0 errors, 1 warning</p>
          </div>
        </OutputPreview>
      )}

      {/* Proceed acknowledgement */}
      <div className="rounded-xl border border-border/50 bg-card/50 p-4">
        <h3 className="mb-3 font-semibold">Before you continue</h3>
        <div className="space-y-3 text-sm">
          <label className="flex cursor-pointer items-start gap-3">
            <Checkbox
              checked={ackPassed}
              onCheckedChange={(checked) => {
                const isChecked = checked === true;
                setAckPassed(isChecked);
                if (isChecked) setAckFailed(false);
              }}
            />
            <span className="text-foreground">
              Pre-flight passed (all green, or only warnings)
            </span>
          </label>
          <label className="flex cursor-pointer items-start gap-3">
            <Checkbox
              checked={ackFailed}
              onCheckedChange={(checked) => {
                const isChecked = checked === true;
                setAckFailed(isChecked);
                if (isChecked) setAckPassed(false);
              }}
            />
            <span className="text-foreground">
              I understand some checks failed and I&apos;m choosing to continue
            </span>
          </label>
        </div>
      </div>

      {/* Troubleshooting */}
      <div className="space-y-3">
        <h2 className="text-xl font-semibold">Troubleshooting common failures</h2>
        <div className="space-y-3">
          {troubleshooting.map((item) => (
            <DetailsSection key={item.title} summary={item.title}>
              <ul className="list-disc space-y-1 pl-5 text-sm text-muted-foreground">
                {item.fixes.map((fix, i) => (
                  <li key={i}>{fix}</li>
                ))}
              </ul>
            </DetailsSection>
          ))}
        </div>
      </div>

      {/* Help */}
      <AlertCard variant="warning" icon={AlertTriangle} title="Seeing red errors?">
        Fix the red errors before installing. The installer will likely fail otherwise.
      </AlertCard>

      {/* Actions */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <Button
          onClick={handleContinue}
          className="bg-primary text-primary-foreground"
          disabled={!canContinue || isNavigating}
        >
          Continue to installer
        </Button>
        <Button variant="outline" onClick={handleSkip} disabled={isNavigating}>
          Skip pre-flight (advanced)
        </Button>
      </div>

      {/* Beginner Guide */}
      <SimplerGuide>
        <div className="space-y-6">
          <GuideExplain term="What is a pre-flight check?">
            {isLocal
              ? "A quick diagnostic that confirms your machine can run the ACFS sandbox before the full install."
              : "A quick diagnostic that confirms your VPS meets the requirements before the full install."}
          </GuideExplain>

          <GuideSection title="Step-by-Step">
            <div className="space-y-4">
              <GuideStep number={1} title="Copy the command">
                Click the copy button in the command box above.
              </GuideStep>
              <GuideStep number={2} title="Paste and run">
                {isLocal
                  ? "Run it from the ACFS repo root on your Ubuntu machine."
                  : "Paste into your terminal (make sure you&apos;re connected to your VPS)."}
              </GuideStep>
              <GuideStep number={3} title="Read the results">
                Green lines are good. Yellow warnings are okay. Red errors should be fixed.
              </GuideStep>
            </div>
          </GuideSection>

          <GuideCaution>
            <strong>Warnings are okay:</strong> Warnings mean something might be imperfect but not
            critical. If you see errors, fix those first or adjust your system resources.
          </GuideCaution>
        </div>
      </SimplerGuide>

    </div>
  );
}
