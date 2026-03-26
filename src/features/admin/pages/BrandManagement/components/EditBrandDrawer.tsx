import { useEffect, useState } from 'react';
import {
  Button,
  Drawer,
  Form,
  Input,
  Select,
  message,
  Row,
  Col,
  Typography,
  Flex,
  Spin,
} from 'antd';

/**
 * Hooks
 */
import { useUpdateBrand, useBrand } from '@/features/admin/hooks';

/**
 * Types
 */
import type { UploadFile } from 'antd';
import type { BrandRequest } from '@/features/admin/types';

/**
 * Constants
 */
import { INDUSTRY_OPTIONS } from '@/features/admin/constants';

/**
 * Validations
 */
import { brandValidation } from '@/features/admin/validations';

/**
 * Utils
 */
import { nullToUndefined, createImageUploadProps } from '@/shared/utils';

/**
 * Components
 */
import { ImageDragger } from '@/shared/components';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { TextArea } = Input;
const { Title } = Typography;

type EditBrandDrawerProps = {
  open: boolean;
  brandId: string | null;
  onClose: () => void;
  onSuccess: () => void;
};

export const EditBrandDrawer = ({
  open,
  brandId,
  onClose,
  onSuccess,
}: EditBrandDrawerProps) => {
  const [form] = Form.useForm<BrandRequest>();
  const [logoFile, setLogoFile] = useState<UploadFile | null>(null);
  const [existingLogoUrl, setExistingLogoUrl] = useState<string | null>(null);

  const { data: brand, isLoading: isFetching } = useBrand(
    brandId || undefined,
    open && !!brandId,
  );

  const updateBrand = useUpdateBrand();

  useEffect(() => {
    if (brand && open) {
      form.setFieldsValue({
        name: brand.name,
        industry: nullToUndefined(brand.industry),
        description: nullToUndefined(brand.description),
        website: nullToUndefined(brand.website),
        contactEmail: nullToUndefined(brand.contactEmail),
        contactPhone: nullToUndefined(brand.contactPhone),
        primaryContactName: nullToUndefined(brand.primaryContactName),
        technicalContactEmail: nullToUndefined(brand.technicalContactEmail),
        legalName: nullToUndefined(brand.legalName),
        taxCode: nullToUndefined(brand.taxCode),
        billingAddress: nullToUndefined(brand.billingAddress),
      });
      setExistingLogoUrl(brand.logoUrl);
    }
  }, [brand, open, form]);

  const handleSubmit = async (values: BrandRequest) => {
    if (!brandId) return;

    const formData = new FormData();

    if (values.name) formData.append('name', values.name);
    if (logoFile?.originFileObj) {
      formData.append('logo', logoFile.originFileObj);
    }
    if (values.description) formData.append('description', values.description);
    if (values.website) formData.append('website', values.website);
    if (values.industry) formData.append('industry', values.industry);
    if (values.contactEmail)
      formData.append('contactEmail', values.contactEmail);
    if (values.contactPhone)
      formData.append('contactPhone', values.contactPhone);
    if (values.primaryContactName)
      formData.append('primaryContactName', values.primaryContactName);
    if (values.technicalContactEmail)
      formData.append('technicalContactEmail', values.technicalContactEmail);
    if (values.legalName) formData.append('legalName', values.legalName);
    if (values.taxCode) formData.append('taxCode', values.taxCode);
    if (values.billingAddress)
      formData.append('billingAddress', values.billingAddress);
    if (values.defaultTimeZone)
      formData.append('defaultTimeZone', values.defaultTimeZone);

    updateBrand.mutate(
      { id: brandId, formData },
      {
        onSuccess: () => {
          handleCancel();
          onSuccess();
        },
      },
    );
  };

  const handleSubmitFailed = () => {
    message.error('Please fill in all required fields correctly!');
  };

  const handleCancel = () => {
    form.resetFields();
    setLogoFile(null);
    setExistingLogoUrl(null);
    onClose();
  };

  const uploadProps = createImageUploadProps<BrandRequest>(
    setLogoFile,
    (field, value) => form.setFieldValue(field, value),
  );

  const getPreviewUrl = () => {
    if (logoFile?.originFileObj) {
      return URL.createObjectURL(logoFile.originFileObj);
    }
    return existingLogoUrl;
  };

  return (
    <Drawer
      closeIcon={null}
      title='Edit Brand'
      placement='right'
      width={DRAWER_WIDTHS.medium}
      open={open}
      onClose={handleCancel}
      footer={
        <Flex
          justify='end'
          gap='small'
        >
          <Button
            size='large'
            onClick={handleCancel}
          >
            Cancel
          </Button>
          <Button
            size='large'
            type='primary'
            onClick={() => form.submit()}
            loading={updateBrand.isPending}
          >
            Update Brand
          </Button>
        </Flex>
      }
    >
      {isFetching ? (
        <Flex
          justify='center'
          align='center'
          style={{ minHeight: 400 }}
        >
          <Spin size='large' />
        </Flex>
      ) : (
        <Form
          size='large'
          form={form}
          layout='vertical'
          onFinish={handleSubmit}
          onFinishFailed={handleSubmitFailed}
          styles={{
            label: {
              height: 22,
            },
          }}
        >
          {/* Basic Information Section */}
          <div style={{ marginBottom: 24 }}>
            <Title
              level={5}
              style={{ marginBottom: 16 }}
            >
              Basic Information
            </Title>

            <Form.Item
              label='Brand Name'
              name='name'
              rules={brandValidation.name}
            >
              <Input placeholder='e.g., Moonlight Coffee' />
            </Form.Item>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  label='Industry'
                  name='industry'
                  rules={brandValidation.industry}
                >
                  <Select
                    placeholder='Select industry'
                    options={INDUSTRY_OPTIONS}
                  />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  label='Website'
                  name='website'
                  rules={brandValidation.website}
                >
                  <Input placeholder='https://example.com' />
                </Form.Item>
              </Col>
            </Row>

            <Form.Item
              label='Logo'
              name='logo'
              valuePropName='file'
            >
              <ImageDragger
                previewUrl={getPreviewUrl()}
                uploadProps={uploadProps}
              />
            </Form.Item>

            <Form.Item
              label='Description'
              name='description'
              rules={brandValidation.description}
            >
              <TextArea
                rows={3}
                placeholder='Brief description of the brand'
                maxLength={2000}
                showCount
              />
            </Form.Item>
          </div>

          {/* Contact Information Section */}
          <div style={{ marginBottom: 24 }}>
            <Title
              level={5}
              style={{ marginBottom: 16 }}
            >
              Contact Information
            </Title>

            <Form.Item
              label='Primary Contact Name'
              name='primaryContactName'
              rules={brandValidation.primaryContactName}
            >
              <Input placeholder='e.g., John Doe' />
            </Form.Item>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  label='Contact Email'
                  name='contactEmail'
                  rules={brandValidation.contactEmail}
                >
                  <Input placeholder='contact@example.com' />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  label='Contact Phone'
                  name='contactPhone'
                  rules={brandValidation.contactPhone}
                >
                  <Input placeholder='+84 901 234 567' />
                </Form.Item>
              </Col>
            </Row>

            <Form.Item
              label='Technical Contact Email'
              name='technicalContactEmail'
              rules={brandValidation.technicalContactEmail}
            >
              <Input placeholder='tech@example.com' />
            </Form.Item>
          </div>

          {/* Legal & Billing Section */}
          <div style={{ marginBottom: 24 }}>
            <Title
              level={5}
              style={{ marginBottom: 16 }}
            >
              Legal & Billing Information
            </Title>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  label='Legal Name'
                  name='legalName'
                  rules={brandValidation.legalName}
                >
                  <Input placeholder='Official company name' />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  label='Tax Code'
                  name='taxCode'
                  rules={brandValidation.taxCode}
                >
                  <Input placeholder='e.g., 0123456789' />
                </Form.Item>
              </Col>
            </Row>

            <Form.Item
              label='Billing Address'
              name='billingAddress'
              rules={brandValidation.billingAddress}
            >
              <TextArea
                rows={2}
                placeholder='Full billing address'
                maxLength={500}
                showCount
              />
            </Form.Item>
          </div>
        </Form>
      )}
    </Drawer>
  );
};
