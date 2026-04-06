import { Flex, Segmented } from 'antd';

type CalendarToolbarProps = {
  currentView: 'timeGridWeek' | 'timeGridDay';
  onViewChange: (view: 'timeGridWeek' | 'timeGridDay') => void;
};

export const CalendarToolbar = ({
  currentView,
  onViewChange,
}: CalendarToolbarProps) => {
  return (
    <Flex
      align='center'
      gap={12}
    >
      {/* View Switcher */}
      <Segmented
        value={currentView}
        onChange={(value) =>
          onViewChange(value as 'timeGridWeek' | 'timeGridDay')
        }
        options={[
          { label: 'Week', value: 'timeGridWeek' },
          { label: 'Day', value: 'timeGridDay' },
        ]}
      />
    </Flex>
  );
};
