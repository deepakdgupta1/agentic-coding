/**
 * VPS provider data for the comparison table in the wizard.
 *
 * Prices are as of early 2026 and should be reviewed periodically.
 * Provider data is separated from UI so it's easy to update without
 * touching component code.
 *
 * @see bd-w8fx
 */

export interface VPSPlan {
  /** Plan name as shown by the provider */
  name: string;
  /** RAM in GB */
  ramGB: number;
  /** Number of virtual CPUs */
  vCPU: number;
  /** Storage in GB */
  storageGB: number;
  /** Monthly price in USD (no-commitment) */
  priceUSD: number;
}

export interface VPSProvider {
  id: string;
  name: string;
  /** One-line description */
  tagline: string;
  /** URL to VPS product page */
  url: string;
  /** Recommended plan tier for 64GB or best available */
  recommended: VPSPlan;
  /** Budget plan tier for 48GB or best available */
  budget: VPSPlan;
  /** Typical activation time */
  activationTime: string;
  /** Key differentiator */
  bestFor: string;
  /** Data center regions available */
  regions: string;
  /** Whether this provider is our top recommendation */
  isTopPick?: boolean;
  /** Additional notes */
  note?: string;
}

export const VPS_PROVIDERS: VPSProvider[] = [
  {
    id: "contabo",
    name: "Contabo",
    tagline: "Best specs-to-price ratio",
    url: "https://contabo.com/en-us/vps/",
    recommended: {
      name: "Cloud VPS 50",
      ramGB: 64,
      vCPU: 16,
      storageGB: 400,
      priceUSD: 56,
    },
    budget: {
      name: "Cloud VPS 40",
      ramGB: 48,
      vCPU: 12,
      storageGB: 300,
      priceUSD: 36,
    },
    activationTime: "Minutes (up to ~1 hr)",
    bestFor: "Best value overall",
    regions: "US, EU, Asia, AU",
    isTopPick: true,
    note: "US datacenter pricing includes ~$10/mo surcharge",
  },
  {
    id: "ovh",
    name: "OVH",
    tagline: "Polished interface, fast activation",
    url: "https://us.ovhcloud.com/vps/",
    recommended: {
      name: "VPS-5",
      ramGB: 64,
      vCPU: 16,
      storageGB: 640,
      priceUSD: 40,
    },
    budget: {
      name: "VPS-4",
      ramGB: 48,
      vCPU: 12,
      storageGB: 480,
      priceUSD: 26,
    },
    activationTime: "Minutes",
    bestFor: "Lowest 64GB price",
    regions: "US, EU, CA, Asia",
  },
];

/** Date the pricing data was last verified */
export const PRICING_LAST_UPDATED = "2026-01";
