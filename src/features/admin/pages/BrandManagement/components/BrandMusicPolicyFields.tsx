import { Alert, Collapse, Form, InputNumber, Select, Typography } from 'antd';

import type { FuzzyProfileTemplateOption } from '@/features/admin/types';

import { FUZZY_PROFILE_TEMPLATE_OPTIONS } from '@/features/admin/constants/fuzzyMusicConstants';
import { useFuzzyProfileTemplateOptions } from '@/features/admin/hooks';

import { usePlaylistOptions } from '@/shared/modules/playlists/hooks';
import { MOOD_TYPE_LABELS } from '@/shared/modules/moods/constants';
import { MoodType } from '@/shared/modules/moods/types';

const MOOD_CANDIDATE_OPTIONS = Object.values(MoodType)
  .filter((value): value is MoodType => typeof value === 'number')
  .map((value) => ({
    label: MOOD_TYPE_LABELS[value],
    value,
  }));

const formatRange = (min?: number, max?: number) => {
  if (min == null || max == null) return 'Not configured';
  return `${min} - ${max} BPM`;
};

type BrandMusicPolicyFieldsProps = {
  /** Create brand only picks profile template; policy tuning is handled later. */
  variant: 'create' | 'edit';
};

export const BrandMusicPolicyFields = ({
  variant,
}: BrandMusicPolicyFieldsProps) => {
  const { data: playlistOptions = [], isLoading: playlistsLoading } =
    usePlaylistOptions();
  const {
    data: templateOptionsFromApi = [],
    isError: templatesError,
    isLoading: templatesLoading,
  } = useFuzzyProfileTemplateOptions();

  const requireMusicPolicy = variant === 'create';
  const showPolicyFields = variant === 'edit';
  const selectedTemplateKey = Form.useWatch('fuzzyProfileTemplate');

  const detailedTemplateOptions: FuzzyProfileTemplateOption[] =
    !templatesError && !templatesLoading && templateOptionsFromApi.length > 0
      ? templateOptionsFromApi
      : FUZZY_PROFILE_TEMPLATE_OPTIONS.map((t) => ({
          templateKey: t.value,
          displayName: t.label,
          sortOrder: 0,
          profileDescription: t.profileDescription,
          chillMoodDescription: t.chillMoodDescription,
          focusMoodDescription: t.focusMoodDescription,
          energeticMoodDescription: t.energeticMoodDescription,
          chillBpmMin: t.chillBpmMin,
          chillBpmMax: t.chillBpmMax,
          focusBpmMin: t.focusBpmMin,
          focusBpmMax: t.focusBpmMax,
          energeticBpmMin: t.energeticBpmMin,
          energeticBpmMax: t.energeticBpmMax,
        }));

  const templateSelectOptions = detailedTemplateOptions.map((t) => ({
    label: t.displayName,
    value: t.templateKey,
  }));

  const selectedTemplate = detailedTemplateOptions.find(
    (t) => t.templateKey === selectedTemplateKey,
  );

  return (
    <div style={{ marginBottom: 24 }}>
      <Typography.Title
        level={5}
        style={{ marginBottom: 16 }}
      >
        {variant === 'create'
          ? 'Brand profile template (CAMS)'
          : 'Music policy (CAMS fuzzy)'}
      </Typography.Title>

      <Form.Item
        label='Fuzzy profile template'
        name='fuzzyProfileTemplate'
        rules={
          requireMusicPolicy
            ? [{ required: true, message: 'Please select a template' }]
            : undefined
        }
        extra='Select the base music profile for this brand. Detailed mood behavior appears below.'
      >
        <Select
          size='large'
          placeholder='Select template'
          options={templateSelectOptions}
          loading={templatesLoading}
          optionFilterProp='label'
        />
      </Form.Item>

      {variant === 'create' && selectedTemplate ? (
        <Alert
          type='info'
          showIcon
          style={{ marginBottom: 16 }}
          message='Template detail preview'
          description={
            <div>
              <div style={{ marginBottom: 4 }}>
                <strong>Profile intent:</strong>{' '}
                {selectedTemplate.profileDescription ?? 'No description yet.'}
              </div>
              <div style={{ marginBottom: 4 }}>
                <strong>
                  Chill mood (
                  {formatRange(
                    selectedTemplate.chillBpmMin,
                    selectedTemplate.chillBpmMax,
                  )}
                  ):
                </strong>{' '}
                {selectedTemplate.chillMoodDescription ?? 'No description yet.'}
              </div>
              <div style={{ marginBottom: 4 }}>
                <strong>
                  Focus mood (
                  {formatRange(
                    selectedTemplate.focusBpmMin,
                    selectedTemplate.focusBpmMax,
                  )}
                  ):
                </strong>{' '}
                {selectedTemplate.focusMoodDescription ?? 'No description yet.'}
              </div>
              <div>
                <strong>
                  Energetic mood (
                  {formatRange(
                    selectedTemplate.energeticBpmMin,
                    selectedTemplate.energeticBpmMax,
                  )}
                  ):
                </strong>{' '}
                {selectedTemplate.energeticMoodDescription ??
                  'No description yet.'}
              </div>
            </div>
          }
        />
      ) : null}

      {showPolicyFields ? (
        <>
          <Form.Item
            label='Chill mood candidates'
            name='chillMoodCandidates'
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
            name='focusMoodCandidates'
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
            name='energeticMoodCandidates'
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

          <Form.Item
            label='Allowed playlists (optional)'
            name='allowedPlaylistIds'
            tooltip='Leave empty so AI is not restricted to specific playlists. Duplicates are rejected by the API.'
          >
            <Select
              mode='multiple'
              allowClear
              placeholder='Restrict AI track pick to these playlists'
              options={playlistOptions}
              loading={playlistsLoading}
              optionFilterProp='label'
            />
          </Form.Item>

          <Collapse
            bordered={false}
            items={[
              {
                key: 'advanced',
                label: 'Advanced threshold overrides (optional)',
                children: (
                  <>
                    <Typography.Text
                      type='secondary'
                      style={{ display: 'block', marginBottom: 12 }}
                    >
                      Leave blank to use template defaults. Values map to brand
                      fuzzy profile fields.
                    </Typography.Text>
                    <div
                      style={{
                        display: 'grid',
                        gridTemplateColumns: '1fr 1fr',
                        gap: '0 16px',
                      }}
                    >
                      <Form.Item
                        label='Chill BPM min'
                        name='chillBpmMin'
                      >
                        <InputNumber
                          className='w-full!'
                          min={1}
                        />
                      </Form.Item>
                      <Form.Item
                        label='Chill BPM max'
                        name='chillBpmMax'
                      >
                        <InputNumber
                          className='w-full!'
                          min={1}
                        />
                      </Form.Item>
                      <Form.Item
                        label='Focus BPM min'
                        name='focusBpmMin'
                      >
                        <InputNumber
                          className='w-full!'
                          min={1}
                        />
                      </Form.Item>
                      <Form.Item
                        label='Focus BPM max'
                        name='focusBpmMax'
                      >
                        <InputNumber
                          className='w-full!'
                          min={1}
                        />
                      </Form.Item>
                      <Form.Item
                        label='Energetic BPM min'
                        name='energeticBpmMin'
                      >
                        <InputNumber
                          className='w-full!'
                          min={1}
                        />
                      </Form.Item>
                      <Form.Item
                        label='Energetic BPM max'
                        name='energeticBpmMax'
                      >
                        <InputNumber
                          className='w-full!'
                          min={1}
                        />
                      </Form.Item>
                      <Form.Item
                        label='People count: Low level max'
                        name='pressureLowMax'
                        tooltip='If people count is below this value, CAMS treats crowd pressure as Low.'
                      >
                        <InputNumber
                          className='w-full!'
                          min={0}
                        />
                      </Form.Item>
                      <Form.Item
                        label='People count: Energetic trigger min'
                        name='pressureCriticalMin'
                        tooltip='If people count is above this value, CAMS treats crowd pressure as Critical and prioritizes Energetic.'
                      >
                        <InputNumber
                          className='w-full!'
                          min={0}
                        />
                      </Form.Item>
                      <Form.Item
                        label='Noise threshold: Quiet max (dB)'
                        name='noiseQuietMaxDb'
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
                        name='noiseLoudMinDb'
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
                        name='spaceCapacity'
                        tooltip='Reference capacity for the profile.'
                      >
                        <InputNumber
                          className='w-full!'
                          min={0}
                        />
                      </Form.Item>
                      <Form.Item
                        label='Fallback decibel when missing (dB)'
                        name='defaultDecibelWhenNull'
                        tooltip='Used only when telemetry payload does not include decibel.'
                      >
                        <InputNumber
                          className='w-full!'
                          min={0}
                          step={0.01}
                        />
                      </Form.Item>
                    </div>
                  </>
                ),
              },
            ]}
          />
        </>
      ) : null}
    </div>
  );
};
