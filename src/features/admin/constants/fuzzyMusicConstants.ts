export const FUZZY_PROFILE_TEMPLATE_OPTIONS = [
  {
    label: 'Cafe',
    value: 'Cafe',
    profileDescription:
      'Balanced coffee-shop profile for calm mornings, focused work sessions, and gentle peak-hour acceleration.',
    chillMoodDescription:
      'Soft acoustic and ambient tracks for early hours and low-footfall comfort.',
    focusMoodDescription:
      'Moderate rhythmic tracks to support concentration and table turnover balance.',
    energeticMoodDescription:
      'Brighter higher-tempo tracks for rush periods and queue movement.',
    chillBpmMin: 55,
    chillBpmMax: 78,
    focusBpmMin: 80,
    focusBpmMax: 100,
    energeticBpmMin: 110,
    energeticBpmMax: 130,
  },
  {
    label: 'Apparel',
    value: 'Apparel',
    profileDescription:
      'Retail shopping profile tuned to keep browsing flow active while preserving conversation comfort.',
    chillMoodDescription:
      'Relaxed modern pop/indie for low traffic windows and visual browsing.',
    focusMoodDescription:
      'Steady groove tracks to maintain shopper attention and decision pacing.',
    energeticMoodDescription:
      'Campaign-friendly high-energy moments for promotions and peak traffic.',
    chillBpmMin: 60,
    chillBpmMax: 82,
    focusBpmMin: 88,
    focusBpmMax: 108,
    energeticBpmMin: 120,
    energeticBpmMax: 145,
  },
  {
    label: 'Furniture',
    value: 'Furniture',
    profileDescription:
      'Showroom profile that favors relaxed exploration and extended dwell time for considered purchases.',
    chillMoodDescription:
      'Warm unobtrusive instrumentals for calm product exploration.',
    focusMoodDescription:
      'Mid-tempo ambient layers for advisor interactions and product comparison.',
    energeticMoodDescription:
      'Controlled energy accents for campaign zones without sensory overload.',
    chillBpmMin: 52,
    chillBpmMax: 75,
    focusBpmMin: 78,
    focusBpmMax: 98,
    energeticBpmMin: 108,
    energeticBpmMax: 125,
  },
  {
    label: 'Luxury restaurant',
    value: 'LuxuryRestaurant',
    profileDescription:
      'Fine-dining profile emphasizing elegance, low noise pressure, and smooth atmosphere transitions.',
    chillMoodDescription:
      'Intimate lounge/neoclassical textures for premium calm ambience.',
    focusMoodDescription:
      'Polished mid-tempo selections that support conversation clarity.',
    energeticMoodDescription:
      'Subtle elevated energy for late seating while preserving luxury tone.',
    chillBpmMin: 48,
    chillBpmMax: 70,
    focusBpmMin: 75,
    focusBpmMax: 95,
    energeticBpmMin: 105,
    energeticBpmMax: 120,
  },
] as const;

export const STORE_OVERRIDE_LEVEL_OPTIONS = [
  {
    label: '1 — Brand lock',
    value: 1,
    description:
      'Store cannot override thresholds or allowed playlists (brand only).',
  },
  {
    label: '2 — Threshold only',
    value: 2,
    description:
      'Store may override fuzzy thresholds; allowed playlists stay from brand.',
  },
  {
    label: '3 — Full override',
    value: 3,
    description: 'Store may override thresholds and allowed playlists.',
  },
] as const;
