import { Collapse, Form, Input, InputNumber, Select, Typography } from 'antd';

import { usePlaylistOptionsForStore } from '@/shared/modules/playlists/hooks';

const { Text } = Typography;

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
        optional.
      </Typography.Paragraph>

      <Form.Item
        label='Override profile name'
        name={['fuzzy', 'name']}
      >
        <Input placeholder='Optional label for this profile' />
      </Form.Item>

      <Collapse
        bordered={false}
        defaultActiveKey={
          defaultAdvancedExpanded ? ['fuzzyAdvanced'] : undefined
        }
        items={[
          {
            key: 'fuzzyAdvanced',
            label: 'Threshold & BPM overrides (optional)',
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
                  label='Pressure low max'
                  name={['fuzzy', 'pressureLowMax']}
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                  />
                </Form.Item>
                <Form.Item
                  label='Pressure critical min'
                  name={['fuzzy', 'pressureCriticalMin']}
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                  />
                </Form.Item>
                <Form.Item
                  label='Stress comfortable max'
                  name={['fuzzy', 'stressComfortableMax']}
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                    step={0.01}
                  />
                </Form.Item>
                <Form.Item
                  label='Stress high min'
                  name={['fuzzy', 'stressHighMin']}
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                    step={0.01}
                  />
                </Form.Item>
                <Form.Item
                  label='Density sparse max (0-1)'
                  name={['fuzzy', 'densitySparseMax']}
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                    max={1}
                    step={0.01}
                  />
                </Form.Item>
                <Form.Item
                  label='Density crowded min (0-1)'
                  name={['fuzzy', 'densityCrowdedMin']}
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                    max={1}
                    step={0.01}
                  />
                </Form.Item>
                <Form.Item
                  label='Space capacity'
                  name={['fuzzy', 'spaceCapacity']}
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                  />
                </Form.Item>
                <Form.Item
                  label='Default density ratio when null (0-1)'
                  name={['fuzzy', 'defaultDensityRatioWhenNull']}
                >
                  <InputNumber
                    className='w-full!'
                    min={0}
                    max={1}
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
