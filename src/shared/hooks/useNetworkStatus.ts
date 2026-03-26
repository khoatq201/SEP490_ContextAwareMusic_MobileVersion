import { useEffect, useState } from 'react';

type NetworkStatus = {
  isOnline: boolean;
  isSlowConnection: boolean;
};

export const useNetworkStatus = () => {
  const [status, setStatus] = useState<NetworkStatus>({
    isOnline: navigator.onLine,
    isSlowConnection: false,
  });

  useEffect(() => {
    const handleOnline = () => {
      setStatus((prev) => ({ ...prev, isOnline: true }));
    };

    const handleOffline = () => {
      setStatus((prev) => ({ ...prev, isOnline: false }));
    };

    // Detect slow connection (if connection type is available)
    const detectSlowConnection = () => {
      const connection = (navigator as any).connection;
      if (connection) {
        const slowTypes = ['slow-2g', '2g', '3g'];
        const isSlow = slowTypes.includes(connection.effectiveType);
        setStatus((prev) => ({ ...prev, isSlowConnection: isSlow }));
      }
    };

    // Event listeners
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Check slow connection
    detectSlowConnection();
    const connection = (navigator as any).connection;
    if (connection) {
      connection.addEventListener('change', detectSlowConnection);
    }

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
      if (connection) {
        connection.removeEventListener('change', detectSlowConnection);
      }
    };
  }, []);

  return status;
};
