import { RouterProvider } from 'react-router';

/**
 * Providers
 */
import { AppProvider } from '@/providers';

/**
 * Routes
 */
import { router } from '@/routes';

/**
 * Components
 */
import { ScrollTop, ErrorBoundary } from '@/shared/components';

export const App = () => {
  return (
    <ErrorBoundary>
      <AppProvider>
        <ScrollTop>
          <RouterProvider router={router} />
        </ScrollTop>
      </AppProvider>
    </ErrorBoundary>
  );
};
