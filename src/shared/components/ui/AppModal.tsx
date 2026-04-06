import { Modal, type ModalProps } from 'antd';
import SimpleBar from 'simplebar-react';
import 'simplebar-react/dist/simplebar.min.css';

/**
 * Types
 */
import type { ModalFuncProps } from 'antd';

/**
 * Icons
 */
import {
  ExclamationCircleOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  InfoCircleOutlined,
  DeleteFilled,
} from '@ant-design/icons';

// ========== Static Modal Props ==========
type AppModalProps = ModalFuncProps & {
  blur?: boolean;
};

const baseModalConfig: ModalFuncProps = {
  centered: true,
  okButtonProps: {
    size: 'large',
    style: {
      fontSize: 14,
      borderRadius: 4,
      width: '49%',
    },
  },
  cancelButtonProps: {
    size: 'large',
    style: {
      fontSize: 14,
      borderRadius: 4,
      width: '49%',
    },
  },
  classNames: {
    body: 'static-modal-body',
  },
  styles: {
    mask: {
      backdropFilter: 'blur(4px)',
      backgroundColor: 'rgba(0, 0, 0, 0.45)',
    },
    body: {
      textAlign: 'center',
    },
    footer: {
      marginTop: 24,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
    },
  },
  width: 480,
  mask: {
    blur: false,
  },
};

// ========== Static Methods ==========
const appConfirm = (props: AppModalProps) => {
  return Modal.confirm({
    ...baseModalConfig,
    ...props,
    icon: props.icon ?? (
      <div className='mx-auto flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-red-100'>
        <DeleteFilled style={{ fontSize: 32, color: '#ff4d4f' }} />
      </div>
    ),
    okText: props.okText || 'Confirm',
    cancelText: props.cancelText || 'Cancel',
    okButtonProps: {
      ...baseModalConfig.okButtonProps,
      ...props.okButtonProps,
    },
    cancelButtonProps: {
      ...baseModalConfig.cancelButtonProps,
      ...props.cancelButtonProps,
    },
  });
};

const appSuccess = (props: AppModalProps) => {
  return Modal.success({
    ...baseModalConfig,
    ...props,
    icon: props.icon ?? (
      <CheckCircleOutlined style={{ fontSize: 24, color: '#52c41a' }} />
    ),
    okText: props.okText || 'OK',
    okButtonProps: {
      ...baseModalConfig.okButtonProps,
      ...props.okButtonProps,
      type: 'primary',
    },
  });
};

const appError = (props: AppModalProps) => {
  return Modal.error({
    ...baseModalConfig,
    ...props,
    icon: props.icon ?? (
      <CloseCircleOutlined style={{ fontSize: 24, color: '#ff4d4f' }} />
    ),
    okText: props.okText || 'OK',
    okButtonProps: {
      ...baseModalConfig.okButtonProps,
      ...props.okButtonProps,
      danger: true,
    },
  });
};

const appWarning = (props: AppModalProps) => {
  return Modal.warning({
    ...baseModalConfig,
    ...props,
    icon: props.icon ?? (
      <ExclamationCircleOutlined style={{ fontSize: 24, color: '#faad14' }} />
    ),
    okText: props.okText || 'OK',
    okButtonProps: {
      ...baseModalConfig.okButtonProps,
      ...props.okButtonProps,
    },
  });
};

const appInfo = (props: AppModalProps) => {
  return Modal.info({
    ...baseModalConfig,
    ...props,
    icon: props.icon ?? (
      <InfoCircleOutlined style={{ fontSize: 24, color: '#1677ff' }} />
    ),
    okText: props.okText || 'OK',
    okButtonProps: {
      ...baseModalConfig.okButtonProps,
      ...props.okButtonProps,
    },
  });
};

// ========== JSX Component Props ==========
type AppModalComponentProps = ModalProps & {
  maxHeight?: number | string;
  scrollable?: boolean;
};

// ========== JSX Component ==========
const AppModalComponent = ({
  children,
  maxHeight = '70vh',
  scrollable = true,
  size = 'middle',
  ...props
}: AppModalComponentProps & {
  size?: 'large' | 'middle' | 'small';
}) => {
  return (
    <Modal
      {...props}
      closeIcon={null}
      centered
      okButtonProps={{
        size: size,
      }}
      cancelButtonProps={{
        size: size,
      }}
      styles={{
        body: {
          // padding: scrollable ? '24px 0' : '24px',
          // maxHeight: scrollable ? maxHeight : undefined,
          // overflow: scrollable ? 'hidden' : undefined,
        },
        container: {
          padding: 0,
        },
        header: {
          padding: 20,
          paddingBottom: 15,
          borderBottom: '1px solid var(--color-border)',
        },
        footer: {
          padding: 20,
          paddingTop: 20,
          borderTop: '1px solid var(--color-border)',
        },
        mask: {
          backdropFilter: 'none',
        },
        ...props.styles,
      }}
    >
      {scrollable ? (
        <SimpleBar style={{ maxHeight, padding: '15px 24px' }}>
          {children}
        </SimpleBar>
      ) : (
        children
      )}
    </Modal>
  );
};

// ========== Export Combined ==========
export const AppModal = Object.assign(AppModalComponent, {
  confirm: appConfirm,
  success: appSuccess,
  error: appError,
  warning: appWarning,
  info: appInfo,
});
