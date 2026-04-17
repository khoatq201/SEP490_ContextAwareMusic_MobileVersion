import { Collapse, Form, Input, InputNumber, Select, Typography } from 'antd';

import { getStoreOverrideLevelDescription } from '@/features/brand/constants/storeMusicPolicy';
import { usePlaylistOptionsForStore } from '@/shared/modules/playlists/hooks';
import { MOOD_TYPE_LABELS } from '@/shared/modules/moods/constants';
import { MoodType } from '@/shared/modules/moods/types';

const { Text } = Typography;

const MOOD_CANDIDATE_OPTIONS = Object.values(MoodType)
  .filter((value): value is MoodType => typeof value === 'number')
  .map((value) => ({
    label: MOOD_TYPE_LABELS[value],
    value,
  }));

type StoreFuzzyOverrideFieldsProps = {
  /** When set, allowed-playlist multi-select is loaded for this store. */
  storeIdForPlaylists?: string;
  /** Store-level override policy (1|2|3). */
  storeOverrideLevel?: number | null;
  /** New-store flow: copy for allowed-playlist hint when store id is not known yet. */
  isCreateFlow?: boolean;
  /** Expand advanced BPM / threshold collapse by default (e.g. create store drawer). */
  defaultAdvancedExpanded?: boolean;
};

/**
 * Optional fields for POST /api/stores/{id}/fuzzy-profiles (JSON body).
 */
export const StoreFuzzyOverrideFields = ({
  storeIdForPlaylists,
  storeOverrideLevel,
  isCreateFlow = false,
  defaultAdvancedExpanded = false,
}: StoreFuzzyOverrideFieldsProps) => {
  const { data: playlistOptions = [], isLoading: playlistsLoading } =
    usePlaylistOptionsForStore(storeIdForPlaylists);

  const level = storeOverrideLevel;
  const showPlaylistMultiselect = !!storeIdForPlaylists;

  const playlistFooter = (() => {
    if (!storeIdForPlaylists && !isCreateFlow) {
      return (
        <Text type='secondary'>
          Allowed playlists for the override can be set when editing this store
          (requires a store id).
        </Text>
      );
    }
    if (!storeIdForPlaylists && isCreateFlow) {
      return (
        <Text type='secondary'>
          Playlist links are per store. Configure allowed playlists after create
          (edit store) when the store id is available.
        </Text>
      );
    }
    return null;
  })();

  const levelHint = getStoreOverrideLevelDescription(level ?? undefined);

  return (
    <>
      {levelHint ? (
        <Typography.Paragraph
          type='secondary'
          style={{ marginBottom: 12 }}
        >
          {levelHint}
        </Typography.Paragraph>
      ) : null}

      <Form.Item
        label='Override profile name'
        name={['fuzzy', 'name']}
      >
        <Input placeholder='Optional label for this profile' />
      </Form.Item>

      <Form.Item
        label='Chill mood candidates'
        name={['fuzzy', 'chillMoodCandidates']}
        tooltip='Optional lane mapping override. Leave empty to use runtime default mapping.'
      >
        <Select
          size='large'
          mode='multiple'
          allowClear
          placeholder='Optional - moods allowed for Chill lane'
          options={MOOD_CANDIDATE_OPTIONS}
          optionFilterProp='label'
        />
      </Form.Item>

      <Form.Item
        label='Focus mood candidates'
        name={['fuzzy', 'focusMoodCandidates']}
        tooltip='Optional lane mapping override. Leave empty to use runtime default mapping.'
      >
        <Select
          size='large'
          mode='multiple'
          allowClear
          placeholder='Optional - moods allowed for Focus lane'
          options={MOOD_CANDIDATE_OPTIONS}
          optionFilterProp='label'
        />
      </Form.Item>

      <Form.Item
        label='Energetic mood candidates'
        name={['fuzzy', 'energeticMoodCandidates']}
        tooltip='Optional lane mapping override. Leave empty to use runtime default mapping.'
      >
        <Select
          size='large'
          mode='multiple'
          allowClear
          placeholder='Optional - moods allowed for Energetic lane'
          options={MOOD_CANDIDATE_OPTIONS}
          optionFilterProp='label'
        />
      </Form.Item>

      <Collapse
        bordered={false}
        defaultActiveKey={
          defaultAdvancedExpanded ? ['fuzzyAdvanced'] : undefined
        }
        items={[
          {
            key: 'fuzzyAdvanced',
            label: 'Advanced mood thresholds & BPM (optional)',
            children: (
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr',
                  gap: '0 16px',
                }}
              >
                <Form.Item
                  label='Chill BPM min'
                  name={['fuzzy', 'chillBpmMin']}
                >
                  <InputNumber
                    className='w-full!'
                    min={1}
                  />
                </Form.Item>
                <Form.Item
                  label='Chill BPM max'
                  name={['fuzzy', 'chillBpmMax']}
                >
                  <InputNumber
                    className='w-full!'
                    min={1}
                  />
                </Form.Item>
                <Form.Item
                  label='Focus BPM min'
                  name={['fuzzy', 'focusBpmMin']}
                >
                  <InputNumber
                    className='w-full!'
                    min={1}
                  />
                </Form.Item>
                <Form.Item
                  label='Focus BPM max'
                  name={['fuzzy', 'focusBpmMax']}
                >
                  <InputNumber
                    className='w-full!'
                    min={1}
                  />
                </Form.Item>
                <Form.Item
                  label='Energetic BPM min'
                  name={['fuzzy', 'energeticBpmMin']}
                >
                  <InputNumber
                    className='w-full!'
                    min={1}
                  />
                </Form.Item>
                <Form.Item
                  label='Energetic BPM max'
                  name={['fuzzy', 'energeticBpmMax']}
                >
                  <InputNumber
                    className='w-full!'
                    min={1}
                  />
                </Form.Item>
                <Form.Item
                  label='People count: Low level max'
                  name={['fuzzy', 'pressureLowMax']}
                  tooltip='If people count is below this value, CAMS treats crowd pressure as Low.'
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                  />
                </Form.Item>
                <Form.Item
                  label='People count: Energetic trigger min'
                  name={['fuzzy', 'pressureCriticalMin']}
                  tooltip='If people count is above this value, CAMS treats crowd pressure as Critical and prioritizes Energetic.'
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                  />
                </Form.Item>
                <Form.Item
                  label='Noise threshold: Quiet max (dB)'
                  name={['fuzzy', 'noiseQuietMaxDb']}
                  tooltip='If decibel is below this value, CAMS classifies ambient noise as Quiet.'
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                    step={0.01}
                  />
                </Form.Item>
                <Form.Item
                  label='Noise threshold: Loud min (dB)'
                  name={['fuzzy', 'noiseLoudMinDb']}
                  tooltip='If decibel is above this value, CAMS classifies ambient noise as Loud.'
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                    step={0.01}
                  />
                </Form.Item>
                <Form.Item
                  label='Space capacity (reference)'
                  name={['fuzzy', 'spaceCapacity']}
                  tooltip='Reference capacity for this space/store profile.'
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                  />
                </Form.Item>
                <Form.Item
                  label='Fallback decibel when missing (dB)'
                  name={['fuzzy', 'defaultDecibelWhenNull']}
                  tooltip='Used only when telemetry payload does not include decibel.'
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                    step={0.01}
                  />
                </Form.Item>
              </div>
            ),
          },
        ]}
      />

      {showPlaylistMultiselect ? (
        <Form.Item
          label='Allowed playlists'
          name={['fuzzy', 'allowedPlaylistIds']}
          tooltip='Optional: if set, CAMS runtime limits AI-selected tracks to these playlists for this store profile.'
        >
          <Select
            size='large'
            mode='multiple'
            allowClear
            placeholder='Optional — restrict AI to these playlists'
            options={playlistOptions}
            loading={playlistsLoading}
            optionFilterProp='label'
          />
        </Form.Item>
      ) : null}
      {playlistFooter}
    </>
  );
};
