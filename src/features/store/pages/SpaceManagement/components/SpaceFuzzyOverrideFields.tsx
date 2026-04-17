import { Collapse, Form, Input, InputNumber, Select, Typography } from 'antd';

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

type SpaceFuzzyOverrideFieldsProps = {
  storeIdForPlaylists?: string;
  defaultAdvancedExpanded?: boolean;
};

/**
 * Optional fields for POST /api/spaces/{id}/fuzzy-profiles (JSON body).
 */
export const SpaceFuzzyOverrideFields = ({
  storeIdForPlaylists,
  defaultAdvancedExpanded = false,
}: SpaceFuzzyOverrideFieldsProps) => {
  const { data: playlistOptions = [], isLoading: playlistsLoading } =
    usePlaylistOptionsForStore(storeIdForPlaylists);

  return (
    <>
      <Typography.Paragraph
        type='secondary'
        style={{ marginBottom: 12 }}
      >
        Create and activate a space-specific fuzzy profile. Thresholds are
        optional. Use people-count and noise thresholds to control mood
        switching.
      </Typography.Paragraph>

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
                  tooltip='Reference capacity for this space profile.'
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

      {storeIdForPlaylists ? (
        <Form.Item
          label='Allowed playlists'
          name={['fuzzy', 'allowedPlaylistIds']}
          tooltip='Optional: if set, CAMS runtime limits AI-selected tracks to these playlists for this space profile.'
        >
          <Select
            size='large'
            mode='multiple'
            allowClear
            placeholder='Optional - restrict AI to these playlists'
            options={playlistOptions}
            loading={playlistsLoading}
            optionFilterProp='label'
          />
        </Form.Item>
      ) : (
        <Text type='secondary'>
          Allowed playlists can be selected when the store id is available.
        </Text>
      )}
    </>
  );
};
