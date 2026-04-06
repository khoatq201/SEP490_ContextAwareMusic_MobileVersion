/**
 * Types
 */
type LinearProgressProps = {
  percent?: number;
};

export const LinearProgress = ({ percent }: LinearProgressProps) => {
  const isIndeterminate = percent === undefined;

  return (
    <div className='bg-primary-bg relative h-2 w-full overflow-hidden'>
      {isIndeterminate ? (
        <div className='animate-progress-indeterminate bg-primary absolute inset-0 h-full w-full origin-left' />
      ) : (
        <div
          className='bg-primary h-full transition-all duration-300 ease-out'
          style={{ width: `${percent}%` }}
        />
      )}
    </div>
  );
};
