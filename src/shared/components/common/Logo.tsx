/**
 * Assets
 */
import LogoIcon from '@/assets/svg/logo.svg?react';

/**
 * Types
 */
type LogoProps = {
  isIcon?: boolean;
};

export const Logo = ({ isIcon = true }: LogoProps) => {
  return (
    <div className='flex items-center gap-3'>
      <LogoIcon className='size-10' />
      {!isIcon && <span className='text-3xl font-semibold'>CAMS</span>}
    </div>
  );
};
