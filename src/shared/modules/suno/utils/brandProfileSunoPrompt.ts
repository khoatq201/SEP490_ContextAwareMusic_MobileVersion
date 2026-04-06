import type { BrandDetailResponse } from '@/features/admin/types';
import type { SunoBrandMusicProfileDto } from '../types';
import { buildPromptFromTemplate } from './sunoUtils';

export type BrandProfileSunoMood = 'chill' | 'focus' | 'energetic';

/** Brand detail or Suno config snapshot — same fuzzy fields. */
export type MusicProfileForSunoPrompt =
  | SunoBrandMusicProfileDto
  | BrandDetailResponse;

export function hasBrandMusicProfileData(
  profile: MusicProfileForSunoPrompt | undefined,
): boolean {
  if (!profile) return false;
  if (profile.fuzzyProfileTemplate?.trim()) return true;
  return (
    profile.chillBpmMin != null &&
    profile.chillBpmMax != null &&
    profile.focusBpmMin != null &&
    profile.focusBpmMax != null &&
    profile.energeticBpmMin != null &&
    profile.energeticBpmMax != null
  );
}

const storeOverrideLabels: Record<number, string> = {
  1: 'Brand lock',
  2: 'Threshold only',
  3: 'Full store override',
};

/** Compact English block so CAMS metrics always reach Suno even if the config template is static text. */
function buildCamsProfileSummaryBlock(
  brand: MusicProfileForSunoPrompt,
  mood: BrandProfileSunoMood,
  templateKey: string,
  chill: string,
  focus: string,
  energetic: string,
  bpmBand: string,
): string {
  const { label: moodLabel } = moodMeta[mood];
  const override =
    brand.storeOverrideLevel != null
      ? (storeOverrideLabels[brand.storeOverrideLevel] ??
        `level ${brand.storeOverrideLevel}`)
      : null;

  const parts = [
    `[CAMS brand music profile] Template: ${templateKey}.`,
    override ? `Store override policy: ${override}.` : '',
    `BPM guide (tempo hints for production, not for spoken lyrics): Chill ${chill}, Focus ${focus}, Energetic ${energetic}.`,
    `Primary zone for this request: ${moodLabel} (emphasize ~${bpmBand} BPM feel).`,
  ];

  if (brand.pressureLowMax != null && brand.pressureCriticalMin != null) {
    parts.push(
      `Crowding / pressure hints from profile: treat light load up to ${brand.pressureLowMax} guests, busy peak from ${brand.pressureCriticalMin} upward when shaping energy.`,
    );
  }

  return parts.filter(Boolean).join(' ');
}

function joinPromptWithinLimit(
  prefix: string,
  body: string,
  maxLen: number,
): string {
  const sep = '\n\n';
  const combined = `${prefix}${sep}${body}`;
  if (combined.length <= maxLen) return combined;
  const budget = maxLen - prefix.length - sep.length;
  if (budget < 80) {
    return prefix.slice(0, maxLen);
  }
  return `${prefix}${sep}${body.slice(0, budget)}`.slice(0, maxLen);
}

const moodMeta: Record<
  BrandProfileSunoMood,
  { label: string; description: string }
> = {
  chill: {
    label: 'Chill / calm zone',
    description: 'relaxed, low-intensity background music',
  },
  focus: {
    label: 'Focus / steady zone',
    description: 'neutral, concentration-friendly instrumental music',
  },
  energetic: {
    label: 'Energetic / peak zone',
    description: 'more driving, upbeat instrumental music',
  },
};

/**
 * Build a Suno-ready English prompt from the brand CAMS fuzzy profile (BPM bands, template, pressure).
 * If `sunoPromptTemplate` is set (Suno Configuration), interpolates extended placeholders; otherwise uses a default narrative.
 */
export function buildBrandProfileSunoPrompt(
  brand: MusicProfileForSunoPrompt,
  mood: BrandProfileSunoMood,
  extras: { title?: string; genre?: string; artist?: string },
  sunoPromptTemplate: string | null | undefined,
): string {
  const templateKey = brand.fuzzyProfileTemplate?.trim() || 'brand profile';

  const chillMin = brand.chillBpmMin ?? 60;
  const chillMax = brand.chillBpmMax ?? 80;
  const focusMin = brand.focusBpmMin ?? 85;
  const focusMax = brand.focusBpmMax ?? 105;
  const enerMin = brand.energeticBpmMin ?? 120;
  const enerMax = brand.energeticBpmMax ?? 140;

  const chill = `${chillMin}-${chillMax}`;
  const focus = `${focusMin}-${focusMax}`;
  const energetic = `${enerMin}-${enerMax}`;

  const bpmBand =
    mood === 'chill' ? chill : mood === 'focus' ? focus : energetic;
  const { label: moodLabel, description: moodDesc } = moodMeta[mood];

  const pressureLine =
    brand.pressureLowMax != null && brand.pressureCriticalMin != null
      ? `Venue traffic context from brand profile: light load up to ${brand.pressureLowMax} concurrent guests, busy peak from ${brand.pressureCriticalMin} upward (inform the energy curve only; do not mention numbers in lyrics).`
      : '';

  const defaultNarrative = [
    `Create royalty-free instrumental background music for a commercial space using the brand's CAMS music profile (template: ${templateKey}).`,
    `Primary direction: ${moodLabel} — ${moodDesc}. Use roughly the ${bpmBand} BPM range as a tempo guide (do not speak BPM numbers to the listener).`,
    `Palette: also allow calm (${chill} BPM feel) and high-energy (${energetic} BPM feel) for consistency with the same brand — this track should emphasize the ${mood} zone.`,
    pressureLine,
    extras.title ? `Working title: ${extras.title}.` : '',
    extras.genre ? `Genre hint: ${extras.genre}.` : '',
    extras.artist ? `Style or artist inspiration: ${extras.artist}.` : '',
    'Keep dynamics smooth for in-store playback; loop-friendly; no vocals unless the genre hint clearly requires subtle vocal texture.',
  ]
    .filter(Boolean)
    .join('\n\n');

  const tpl = sunoPromptTemplate?.trim();
  if (tpl) {
    const genre =
      extras.genre?.trim() ||
      extras.artist?.trim() ||
      'instrumental ambient suitable for retail';

    const fromTemplate = buildPromptFromTemplate(tpl, {
      mood: moodLabel,
      genre,
      title: extras.title?.trim() ?? '',
      artist: extras.artist?.trim() ?? '',
      fuzzyTemplate: templateKey,
      bpmBand,
      chillBpm: chill,
      focusBpm: focus,
      energeticBpm: energetic,
      pressureLowMax: brand.pressureLowMax?.toString() ?? '',
      pressureCriticalMin: brand.pressureCriticalMin?.toString() ?? '',
      stressComfortableMax: brand.stressComfortableMax?.toString() ?? '',
      stressHighMin: brand.stressHighMin?.toString() ?? '',
      densitySparseMax: brand.densitySparseMax?.toString() ?? '',
      densityCrowdedMin: brand.densityCrowdedMin?.toString() ?? '',
      spaceCapacity: brand.spaceCapacity?.toString() ?? '',
    });

    const camsSummary = buildCamsProfileSummaryBlock(
      brand,
      mood,
      templateKey,
      chill,
      focus,
      energetic,
      bpmBand,
    );

    return joinPromptWithinLimit(camsSummary, fromTemplate, 4000);
  }

  return defaultNarrative.slice(0, 4000);
}
