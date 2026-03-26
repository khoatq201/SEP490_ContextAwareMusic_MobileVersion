import { useState, useRef } from 'react';
import { Card, Flex, Tag } from 'antd';
import FullCalendar from '@fullcalendar/react';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';

/**
 * Icons
 */
import { CalendarOutlined } from '@ant-design/icons';

/**
 * Types
 */
import type { EventClickArg, DateSelectArg } from '@fullcalendar/core';

/**
 * Components
 */
import { CalendarHeader } from './CalendarHeader';
import { CalendarToolbar } from './CalendarToolbar';
import { CalendarLegend } from './CalendarLegend';

/**
 * Mock Data
 */
import { mockEvents } from './mockData';

/**
 * CSS
 */
import './styles.css';

export const MusicScheduleCalendar = () => {
  const calendarRef = useRef<FullCalendar>(null);
  const [currentView, setCurrentView] = useState<
    'timeGridWeek' | 'timeGridDay'
  >('timeGridWeek');

  const handlePrevious = () => {
    calendarRef.current?.getApi().prev();
  };

  const handleNext = () => {
    calendarRef.current?.getApi().next();
  };

  const handleToday = () => {
    calendarRef.current?.getApi().today();
  };

  const handleViewChange = (view: 'timeGridWeek' | 'timeGridDay') => {
    calendarRef.current?.getApi().changeView(view);
    setCurrentView(view);
  };

  const handleEventClick = (info: EventClickArg) => {
    console.log('Event clicked:', info.event.extendedProps);
    // TODO: Mở modal chi tiết lịch
  };

  const handleDateSelect = (selectInfo: DateSelectArg) => {
    // Prevent selecting past dates
    if (selectInfo.start < new Date()) {
      return;
    }
    console.log('Date selected:', selectInfo);
    // TODO: Mở modal tạo lịch mới
  };

  const getDateRangeText = () => {
    const calendarApi = calendarRef.current?.getApi();
    if (!calendarApi) return '';

    const view = calendarApi.view;
    const start = view.currentStart;
    const end = view.currentEnd;

    if (currentView === 'timeGridDay') {
      return start.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });
    } else {
      const startStr = start.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
      });
      const endDate = new Date(end);
      endDate.setDate(endDate.getDate() - 1);
      const endStr = endDate.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      });
      return `${startStr} - ${endStr}`;
    }
  };

  return (
    <Card>
      {/* Header */}
      <Flex
        justify='space-between'
        align='center'
        style={{ marginBottom: 24 }}
      >
        <CalendarHeader
          dateRangeText={getDateRangeText()}
          onPrevious={handlePrevious}
          onNext={handleNext}
          onToday={handleToday}
        />

        <CalendarToolbar
          currentView={currentView}
          onViewChange={handleViewChange}
        />
      </Flex>

      {/* Legend */}
      <CalendarLegend />

      {/* Calendar */}
      <div style={{ minHeight: 700 }}>
        <FullCalendar
          ref={calendarRef}
          plugins={[timeGridPlugin, interactionPlugin]}
          initialView='timeGridWeek'
          headerToolbar={false}
          events={mockEvents}
          editable={true}
          selectable={true}
          selectMirror={true}
          selectAllow={(selectInfo) => selectInfo.start >= new Date()}
          dayMaxEvents={true}
          weekends={true}
          slotMinTime='07:00:00'
          slotMaxTime='22:00:00'
          slotDuration='01:00:00'
          height='auto'
          eventClick={handleEventClick}
          select={handleDateSelect}
          slotLabelFormat={{
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
          }}
          eventTimeFormat={{
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
          }}
          nowIndicator={true}
          nowIndicatorContent={
            <div className='relative'>
              <span className='absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2 rounded-sm bg-gray-800 p-2 py-1 text-xs text-white'>
                {new Date().toLocaleTimeString('EN-US', {
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </span>
            </div>
          }
          // slotMinHeight={slotHeight}
          eventContent={(eventInfo) => {
            const { event } = eventInfo;
            const props = event.extendedProps;
            return (
              <div style={{ padding: '6px 10px', overflow: 'hidden' }}>
                <div style={{ fontWeight: 600, fontSize: 13, marginBottom: 4 }}>
                  {event.title}
                </div>
                {props.playlist && (
                  <div style={{ fontSize: 11, opacity: 0.9, marginBottom: 4 }}>
                    <CalendarOutlined style={{ marginRight: 4 }} />
                    {props.playlist}
                  </div>
                )}
                {props.mood && (
                  <Tag
                    color={props.autoMode ? 'green' : 'blue'}
                    style={{ fontSize: 10 }}
                  >
                    {props.mood}
                  </Tag>
                )}
              </div>
            );
          }}
        />
      </div>
    </Card>
  );
};
