/**
 * Node modules
 */
import { Suspense, lazy, type ComponentType } from 'react';

/**
 * Components
 */
import { Loader } from './Loader';

/**
 * Types
 */
type ImportFactory<T> = () => Promise<T>;

export const Loadable = <T, K extends keyof T>(
  factory: ImportFactory<T>,
  name: K,
) => {
  const LazyComponent = lazy(() =>
    factory().then((module) => ({
      default: module[name] as unknown as ComponentType<any>,
    })),
  );

  return (props: any) => (
    <Suspense fallback={<Loader />}>
      <LazyComponent {...props} />
    </Suspense>
  );
};
