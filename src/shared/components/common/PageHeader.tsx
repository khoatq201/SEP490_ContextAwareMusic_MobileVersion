import { Breadcrumb, Flex, Typography } from 'antd';
import { Helmet } from 'react-helmet-async';

/**
 * Types
 */
import type { BreadcrumbItemType } from 'antd/es/breadcrumb/Breadcrumb';
import type { ReactNode } from 'react';

const { Title } = Typography;

type PageHeaderProps = {
  title: string;
  breadcrumbs?: BreadcrumbItemType[];
  extra?: ReactNode;
  /**
   * SEO metadata (optional)
   */
  seo?: {
    description?: string;
    keywords?: string;
  };
};

export const PageHeader = ({
  title,
  breadcrumbs,
  extra,
  seo,
}: PageHeaderProps) => {
  return (
    <>
      {/* Auto SEO with page title */}
      <Helmet>
        <title>{title} | CAMS</title>
        {seo?.description && (
          <meta
            name='description'
            content={seo.description}
          />
        )}
        {seo?.keywords && (
          <meta
            name='keywords'
            content={seo.keywords}
          />
        )}
      </Helmet>

      {/* Breadcrumbs */}
      {breadcrumbs && (
        <Breadcrumb
          className='custom-breadcrumb mb-3!'
          items={breadcrumbs}
        />
      )}

      {/* Page Title & Actions */}
      <Flex
        justify='space-between'
        align='center'
        className='mb-6!'
      >
        <Title level={2}>{title}</Title>
        {extra}
      </Flex>
    </>
  );
};
