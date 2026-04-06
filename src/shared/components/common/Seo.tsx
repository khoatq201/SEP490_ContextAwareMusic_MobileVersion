import { Helmet } from 'react-helmet-async';

type SeoProps = {
  title: string;
  description?: string;
  keywords?: string;
};

/**
 * Standalone SEO component
 * Use this ONLY for pages without PageHeader (e.g., Login, 404, Dashboard without header)
 */
export const Seo = ({ title, description, keywords }: SeoProps) => {
  return (
    <Helmet>
      <title>{title} | CAMS</title>
      {description && (
        <meta
          name='description'
          content={description}
        />
      )}
      {keywords && (
        <meta
          name='keywords'
          content={keywords}
        />
      )}
    </Helmet>
  );
};
