import React from 'react';
import { Repeat, Repeat1 } from 'lucide-react';
import { QueueEndBehavior } from '@/shared/modules/cams/types/camsTypes';

export type RepeatButtonProps = {
  queueEndBehavior: QueueEndBehavior | number; // 0=Stop,1=RepeatAll,2=RepeatOne
  onChange: (next: QueueEndBehavior | number) => void;
  size?: number; // icon pixel size
  className?: string;
};

/**
 * Spotify-style Repeat / Loop toggle button.
 * - Single button cycles 0 -> 1 -> 2 -> 0 on click
 * - Uses Tailwind classes for styling
 */
export const RepeatButton: React.FC<RepeatButtonProps> = ({
  queueEndBehavior,
  onChange,
  size = 18,
  className = '',
}) => {
  const isActive = (queueEndBehavior ?? 0) !== 0;
  const isRepeatOne = (queueEndBehavior ?? 0) === 2;

  const handleClick = () => {
    const cur = Number(queueEndBehavior) || 0;
    const next = (cur + 1) % 3; // cycles 0->1->2->0
    onChange(next);
  };

  const title =
    queueEndBehavior === QueueEndBehavior.RepeatQueue
      ? 'Repeat (All) — click to change'
      : queueEndBehavior === QueueEndBehavior.ReturnToSchedule
        ? 'Repeat One — click to change'
        : 'Repeat Off — click to change';

  const iconClasses = `transition-colors duration-200 ${
    isActive
      ? 'text-blue-600 hover:text-blue-500'
      : 'text-gray-400 hover:text-gray-200'
  }`;

  return (
    <button
      type='button'
      aria-pressed={isActive}
      aria-label={title}
      title={title}
      onClick={handleClick}
      className={`m-0 inline-flex items-center justify-center border-0 bg-transparent p-0 focus:outline-none ${className}`}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          handleClick();
        }
      }}
    >
      <div className='relative flex items-center justify-center'>
        {isRepeatOne ? (
          <Repeat1
            className={iconClasses}
            size={size}
          />
        ) : (
          <Repeat
            className={iconClasses}
            size={size}
          />
        )}

        {/* subtle indicator dot for active states */}
        {isActive && (
          <span
            aria-hidden
            className='absolute -bottom-2.5 h-1.5 w-1.5 rounded-full bg-blue-600'
            style={{ boxShadow: '0 0 0 3px rgba(59,130,246,0.06)' }}
          />
        )}
      </div>
    </button>
  );
};

export default RepeatButton;
