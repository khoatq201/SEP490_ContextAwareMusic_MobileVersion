import { useEffect } from 'react';
import { Alert, Form, Select } from 'antd';

/**
 * Hooks
 */
import {
  useStaffDetail,
  useAssignStaffStore,
  useStores,
} from '@/features/brand/hooks';

/**
 * Components
 */
import { AppModal } from '@/shared/components';

/**
 * Types
 */
import type { AssignStaffStoreRequest } from '@/features/brand/types';
import { EntityStatusEnum } from '@/shared/types';

/**
 * Validations
 */
import { assignStoreValidation } from '@/features/brand/validations';

/**
 * Configs
 */
import { MODAL_WIDTHS } from '@/config';

type AssignStaffStoreModalProps = {
  open: boolean;
  staffId: string | null;
  onClose: () => void;
  onSuccess: () => void;
};

export const AssignStaffStoreModal = ({
  open,
  staffId,
  onClose,
  onSuccess,
}: AssignStaffStoreModalProps) => {
  const [form] = Form.useForm<AssignStaffStoreRequest>();
  const { data: staff } = useStaffDetail(
    staffId || undefined,
    open && !!staffId,
  );
  const { data: storesData } = useStores({
    status: EntityStatusEnum.Active,
    pageSize: 100,
  });
  const assignStore = useAssignStaffStore();

  const storeOptions = [
    { label: 'Unassign (No Store)', value: null },
    ...(storesData?.items.map((store) => ({
      label: store.name,
      value: store.id,
    })) || []),
  ];

  // Pre-fill current store
  useEffect(() => {
    if (staff && open) {
      form.setFieldValue('newStoreId', staff.storeId);
    }
  }, [staff, open, form]);

  const handleSubmit = async (values: AssignStaffStoreRequest) => {
    if (!staffId) return;

    assignStore.mutate(
      { id: staffId, data: values },
      {
        onSuccess: () => {
          form.resetFields();
          onSuccess();
          onClose();
        },
      },
    );
  };

  const handleCancel = () => {
    form.resetFields();
    onClose();
  };

  return (
    <AppModal
      size='large'
      title='Assign Store'
      open={open}
      onCancel={handleCancel}
      onOk={() => form.submit()}
      okText='Assign Store'
      okButtonProps={{
        loading: assignStore.isPending,
      }}
      width={MODAL_WIDTHS.medium}
    >
      <Alert
        type='warning'
        showIcon
        title={
          <p className='text-xs'>
            This action will revoke access to the current brand and logout the
            user!
          </p>
        }
        className='mb-5!'
      />
      <Form
        form={form}
        layout='vertical'
        onFinish={handleSubmit}
        autoComplete='off'
        size='large'
        styles={{
          label: {
            height: 22,
          },
        }}
      >
        <Form.Item
          label='Select Store'
          name='newStoreId'
          rules={assignStoreValidation.newStoreId}
          extra='Select a store to assign or "Unassign" to remove assignment'
        >
          <Select
            placeholder='Select a store'
            options={storeOptions}
            showSearch
            filterOption={(input, option) =>
              option?.label
                ? option.label.toLowerCase().includes(input.toLowerCase())
                : false
            }
          />
        </Form.Item>
      </Form>
    </AppModal>
  );
};
