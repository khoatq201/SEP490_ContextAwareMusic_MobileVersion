/**
 * Components
 */
import { LinearProgress } from './LinearProgress';

export const Loader = () => {
  return (
    <div className='fixed top-0 right-0 left-0 z-1000'>
      <LinearProgress />
    </div>
  );
};
