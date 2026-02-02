"use client";

import {
    Terminal,
    ShieldCheck,
    Package,
    Share2,
    HardDrive,
    Monitor,
    Layout,
    Zap,
} from "lucide-react";
import {
    Section,
    Paragraph,
    FeatureCard,
    FeatureGrid,
    TipBox,
    StepList,
    Highlight,
    Divider,
    GoalBanner,
    CodeBlock,
    DiagramBox,
} from "./lesson-components";

export function LocalDesktopLesson() {
    return (
        <div className="space-y-8">
            <GoalBanner>
                Learn how Local Desktop Mode protects your host system using sandboxed containers.
            </GoalBanner>

            {/* Why Local Desktop Mode? */}
            <Section
                title="Why Local Desktop Mode?"
                icon={<ShieldCheck className="h-5 w-5" />}
                delay={0.1}
            >
                <Paragraph highlight>
                    Standard ACFS is designed for fresh VPS instances. It makes invasive system-level changes like:
                </Paragraph>
                <div className="mt-4 ml-6 space-y-2">
                    <Paragraph>• Modifying <Highlight>/etc/sudoers.d/</Highlight> for passwordless access</Paragraph>
                    <Paragraph>• Updating <Highlight>/etc/ssh/sshd_config</Highlight> for secure orchestration</Paragraph>
                    <Paragraph>• Installing system-wide APT packages and runtimes</Paragraph>
                </div>
                <div className="mt-6">
                    <Paragraph>
                        <Highlight>Local Desktop Mode</Highlight> uses LXD system containers to isolate these changes,
                        providing a &quot;Vibe Mode&quot; experience without compromising your daily workstation.
                    </Paragraph>
                </div>
            </Section>

            <Divider />

            {/* The Sandbox Architecture */}
            <Section
                title="The Sandbox Architecture"
                icon={<Layout className="h-5 w-5" />}
                delay={0.2}
            >
                <Paragraph>
                    Your environment is split into two layers: the <Highlight>Host</Highlight> (your desktop) and the <Highlight>Sandbox</Highlight> (ACFS engine).
                </Paragraph>

                <div className="mt-10 grid grid-cols-1 md:grid-cols-[1fr_auto_1fr] gap-6 items-center">
                    <DiagramBox
                        label="Host Machine"
                        sublabel="Your PC (Ubuntu)"
                        icon={<Monitor className="h-8 w-8" />}
                        gradient="from-sky-500/20 to-blue-500/20"
                    />
                    <div className="flex flex-col items-center">
                        <Share2 className="h-6 w-6 text-primary animate-pulse" />
                        <span className="text-[10px] text-white/40 mt-1 uppercase">Mounted Workspace</span>
                    </div>
                    <DiagramBox
                        label="LXD Sandbox"
                        sublabel="acfs-local Container"
                        icon={<ShieldCheck className="h-8 w-8" />}
                        gradient="from-emerald-500/20 to-teal-500/20"
                    />
                </div>

                <div className="mt-8">
                    <FeatureGrid>
                        <FeatureCard
                            icon={<HardDrive className="h-5 w-5" />}
                            title="Shared Workspace"
                            description="Files are bidirectionally synced between ~/acfs-workspace and /data/projects"
                            gradient="from-amber-500/20 to-orange-500/20"
                        />
                        <FeatureCard
                            icon={<Zap className="h-5 w-5" />}
                            title="Port Forwarding"
                            description="Dashboard on port 38080 inside is accessible via localhost:38080 outside"
                            gradient="from-violet-500/20 to-purple-500/20"
                        />
                    </FeatureGrid>
                </div>
            </Section>

            <Divider />

            {/* Essential Commands */}
            <Section
                title="Essential Sandbox Commands"
                icon={<Terminal className="h-5 w-5" />}
                delay={0.3}
            >
                <Paragraph>
                    Manage your environment from your host terminal using the <Highlight>acfs-local</Highlight> wrapper.
                </Paragraph>

                <CodeBlock
                    code={`# Enter your ACFS environment
acfs-local shell

# View health and access info
acfs-local status

# Launch the browser dashboard
acfs-local dashboard

# Remove the sandbox (keeps your work safe)
acfs-local destroy`}
                />

                <TipBox variant="info">
                    The <Highlight>acfs-local</Highlight> script is a lightweight wrapper that communicates with LXD so
                    you don&apos;t have to remember complex <Highlight>lxc</Highlight> commands.
                </TipBox>

                <TipBox variant="tip">
                    <Highlight>acfs-local</Highlight> is installed to <Highlight>~/.local/bin</Highlight>. If the command
                    isn&apos;t found, open a new terminal or add it to your PATH.
                </TipBox>
            </Section>

            <Divider />

            {/* Getting Started */}
            <Section
                title="Installation & Beyond"
                icon={<Package className="h-5 w-5" />}
                delay={0.4}
            >
                <StepList
                    steps={[
                        {
                            title: "Provision the Sandbox",
                            description: "Run ./install.sh --local --yes to create the container and prepare the environment.",
                        },
                        {
                            title: "Inside the Shell",
                            description: "Run 'acfs-local shell' to step inside. You are now the 'ubuntu' user with full agent permissions.",
                        },
                        {
                            title: "Verify Setup",
                            description: "Run 'acfs doctor' inside the shell to ensure all 30+ tools are working correctly.",
                        },
                    ]}
                />
            </Section>

            <TipBox variant="tip">
                Your container persists across reboots. If you haven&apos;t used it for a while, just run{" "}
                <Highlight>acfs-local start</Highlight> to wake the engine.
            </TipBox>
        </div>
    );
}
