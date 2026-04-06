/**
 * Assets
 */
import LogoIcon from '@/assets/svg/logo.svg?react';

export const AuthBackground = () => {
  return (
    <div className='absolute inset-0 -z-10 blur-lg'>
      <LogoIcon className='absolute bottom-20 -left-20 aspect-square h-125' />
    </div>
  );
};
