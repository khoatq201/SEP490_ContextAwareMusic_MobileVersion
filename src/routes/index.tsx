import { lazy, Suspense } from 'react';
import { createBrowserRouter, Navigate } from 'react-router';

import { Loader } from '@/shared/components/common/Loader';

import { AuthRoutes } from './AuthRoutes';
import { ErrorRoutes } from './ErrorRoutes';
import { MainRoutes } from './MainRoutes';

/**
 * MoMo redirect must stay **outside** ProtectedRoute: returning users may not have
 * the same session (e.g. http vs https cookie scope), and /login navigation drops query params.
 */
const MoMoPaymentReturnPage = lazy(() =>
  import('@/features/brand/pages/TokenBilling/MoMoPaymentReturn').then((m) => ({
    default: m.MoMoPaymentReturn,
  })),
);

export const router = createBrowserRouter([
  {
    path: '/',
    element: (
      <Navigate
        to='/login'
        replace
      />
    ),
  },
  AuthRoutes,
  {
    path: '/brand/tokens/payment-return',
    element: (
      <div className='min-h-screen bg-linear-to-b from-slate-50 via-white to-indigo-50/40 px-4 py-10 sm:py-14'>
        <div className='mx-auto max-w-lg'>
          <Suspense fallback={<Loader />}>
            <MoMoPaymentReturnPage />
          </Suspense>
        </div>
      </div>
    ),
  },
  ...MainRoutes,
  ...ErrorRoutes,
]);
