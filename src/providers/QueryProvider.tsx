import { message } from 'antd';
import { useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

/**
 * Hooks
 */
import { useNetworkStatus } from '@/shared/hooks';

export const QueryProvider = ({ children }: { children: React.ReactNode }) => {
  const { isOnline } = useNetworkStatus();

  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000,
            gcTime: 1000 * 60 * 60 * 24,
            retry: (failureCount, _error) => {
              // Don't retry if offline
              if (!navigator.onLine) return false;
              // Retry up to 2 times for other errors
              return failureCount < 2;
            },
            refetchOnWindowFocus: isOnline, // Only refetch if online
            refetchOnReconnect: true, // Auto-refetch when reconnected
          },
          mutations: {
            // Block mutations when offline
            retry: (failureCount, _error) => {
              if (!navigator.onLine) {
                message.error('Cannot perform action while offline!');
                return false;
              }
              return failureCount < 1;
            },
            onError: (_error) => {
              if (!navigator.onLine) {
                message.error('Cannot perform action while offline!');
              }
            },
          },
        },
      }),
  );

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
};
