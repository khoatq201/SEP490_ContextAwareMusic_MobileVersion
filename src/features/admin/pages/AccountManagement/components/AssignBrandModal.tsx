import { useEffect } from 'react';
import { Alert, Form, message, Select } from 'antd';

/**
 * Hooks
 */
import {
  useAssignAccountBrand,
  useBrands,
  useAccount,
} from '@/features/admin/hooks';

/**
 * Components
 */
import { AppModal } from '@/shared/components/ui';

/**
 * Types
 */
import type { AssignBrandRequest } from '@/features/admin/types';

/**
 * Validations
 */
import { assignBrandValidation } from '@/features/admin/validations';

/**
 * Configs
 */
import { MODAL_WIDTHS } from '@/config';
import { ErrorCodeEnum } from '@/shared/types';

type AssignBrandModalProps = {
  open: boolean;
  accountId: string | null;
  onClose: () => void;
  onSuccess: () => void;
};

export const AssignBrandModal = ({
  open,
  accountId,
  onClose,
  onSuccess,
}: AssignBrandModalProps) => {
  const [form] = Form.useForm<AssignBrandRequest>();
  const assignBrand = useAssignAccountBrand();

  const { data: account } = useAccount(
    accountId || undefined,
    open && !!accountId,
  );
  const { data: brandsData } = useBrands({ pageSize: 100 });

  const brandOptions =
    brandsData?.items.map((brand) => ({
      label: brand.name,
      value: brand.id,
    })) || [];

  // Pre-fill current brand
  useEffect(() => {
    if (account && open) {
      form.setFieldValue('newBrandId', account.brandId);
    }
  }, [account, open, form]);

  const handleSubmit = async (values: AssignBrandRequest) => {
    if (!accountId) return;

    assignBrand.mutate(
      {
        id: accountId,
        data: values,
        skipDefaultError: true,
      },
      {
        onSuccess: () => {
          form.resetFields();
          onSuccess();
          onClose();
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        onError: (error: any) => {
          const errorCode = error.response?.data?.errorCode;
          if (errorCode === ErrorCodeEnum.Forbidden) {
            message.error(
              'Vui lòng chuyển nhượng quyền trước khi chuyển người dùng!',
            );
            return;
          }
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
      title='Assign Brand'
      open={open}
      onCancel={handleCancel}
      onOk={() => form.submit()}
      okText='Assign Brand'
      okButtonProps={{
        loading: assignBrand.isPending,
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
          label='Select Brand'
          name='newBrandId'
          rules={assignBrandValidation.newBrandId}
          extra='This account will be reassigned to the selected brand'
          className='mb-0!'
        >
          <Select
            placeholder='Select a brand'
            options={brandOptions}
            showSearch
            filterOption={(input, option) =>
              (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
            }
          />
        </Form.Item>
      </Form>
    </AppModal>
  );
};
