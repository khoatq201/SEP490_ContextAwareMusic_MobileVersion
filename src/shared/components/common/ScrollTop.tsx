/**
 * Node modules
 */
import React, { useEffect } from 'react';

export const ScrollTop = ({ children }: { children: React.ReactNode }) => {
  useEffect(() => {
    window.scrollTo({
      top: 0,
      left: 0,
      behavior: 'smooth',
    });
  }, []);

  return children || null;
};
