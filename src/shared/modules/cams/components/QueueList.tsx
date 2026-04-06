import {
  memo,
  useCallback,
  useEffect,
  useMemo,
  useState,
  type CSSProperties,
} from 'react';
import {
  List,
  Tag,
  Button,
  Space,
  Typography,
  Empty,
  Tooltip,
  Checkbox,
  Popconfirm,
} from 'antd';
import {
  DeleteOutlined,
  DragOutlined,
  PlayCircleOutlined,
  CheckCircleOutlined,
  ClockCircleOutlined,
  StopOutlined,
} from '@ant-design/icons';
import {
  DndContext,
  DragOverlay,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent,
} from '@dnd-kit/core';
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import type { SpaceQueueItemResponse } from '../types';
import { QueueItemStatus, QueueItemSource } from '../types';

const { Text } = Typography;

interface QueueListProps {
  items: SpaceQueueItemResponse[];
  loading?: boolean;
  onRemove: (queueItemId: string) => void;
  onRemoveMany?: (queueItemIds: string[]) => Promise<void> | void;
  onReorder?: (queueItemIds: string[]) => void;
  onSkipToTrack?: (queueItemId: string, trackId?: string) => void;
}

const getStatusIcon = (status: QueueItemStatus) => {
  switch (status) {
    case QueueItemStatus.Playing:
      return <PlayCircleOutlined style={{ color: '#52c41a' }} />;
    case QueueItemStatus.Pending:
      return <ClockCircleOutlined style={{ color: '#1890ff' }} />;
    case QueueItemStatus.Played:
      return <CheckCircleOutlined style={{ color: '#8c8c8c' }} />;
    case QueueItemStatus.Skipped:
      return <StopOutlined style={{ color: '#ff4d4f' }} />;
    default:
      return null;
  }
};

const getStatusLabel = (status: QueueItemStatus) => {
  switch (status) {
    case QueueItemStatus.Playing:
      return 'Playing';
    case QueueItemStatus.Pending:
      return 'Pending';
    case QueueItemStatus.Played:
      return 'Played';
    case QueueItemStatus.Skipped:
      return 'Skipped';
    default:
      return 'Unknown';
  }
};

const getStatusColor = (status: QueueItemStatus) => {
  switch (status) {
    case QueueItemStatus.Playing:
      return 'success';
    case QueueItemStatus.Pending:
      return 'processing';
    case QueueItemStatus.Played:
      return 'default';
    case QueueItemStatus.Skipped:
      return 'error';
    default:
      return 'default';
  }
};

const getSourceLabel = (source: QueueItemSource) => {
  return source === QueueItemSource.AI ? 'AI' : 'Manager';
};

const getSourceColor = (source: QueueItemSource) => {
  return source === QueueItemSource.AI ? 'purple' : 'blue';
};

// Visual clone rendered in DragOverlay — no sortable hooks, renders as portal above list
const DragOverlayItem = ({
  item,
  selected,
}: {
  item: SpaceQueueItemResponse;
  selected: boolean;
}) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      padding: '12px 16px',
      backgroundColor: selected ? '#e6f4ff' : '#ffffff',
      boxShadow:
        '0 12px 32px rgba(0, 0, 0, 0.18), 0 2px 8px rgba(0, 0, 0, 0.08)',
      borderRadius: 8,
      border: '1px solid #bfdbfe',
      cursor: 'grabbing',
      gap: 12,
    }}
  >
    <Space>
      <div style={{ display: 'flex', alignItems: 'center', width: 16 }}>
        <DragOutlined style={{ color: '#1890ff' }} />
      </div>
      <Checkbox
        checked={selected}
        style={{ pointerEvents: 'none' }}
      />
      {item.coverImageUrl ? (
        <img
          src={item.coverImageUrl}
          alt={item.trackName}
          style={{ width: 40, height: 40, objectFit: 'cover', borderRadius: 4 }}
        />
      ) : (
        <div
          style={{
            width: 40,
            height: 40,
            background: '#fafafa',
            borderRadius: 4,
          }}
        />
      )}
    </Space>
    <div style={{ flex: 1, minWidth: 0 }}>
      <Space>
        {getStatusIcon(item.queueStatus)}
        <Text>{item.trackName}</Text>
      </Space>
      <div style={{ marginTop: 4 }}>
        <Space size='small'>
          <Tag
            color={getStatusColor(item.queueStatus)}
            style={{ fontSize: 11 }}
          >
            {getStatusLabel(item.queueStatus)}
          </Tag>
          <Tag
            color={getSourceColor(item.source)}
            style={{ fontSize: 11 }}
          >
            {getSourceLabel(item.source)}
          </Tag>
        </Space>
      </div>
    </div>
  </div>
);

// Sortable Item Component
interface SortableItemProps {
  item: SpaceQueueItemResponse;
  selected: boolean;
  onSelectChange: (queueItemId: string, checked: boolean) => void;
  onRemove: (queueItemId: string) => void;
  onSkipToTrack?: (queueItemId: string, trackId?: string) => void;
}

const SortableItem = memo(function SortableItem({
  item,
  selected,
  onSelectChange,
  onRemove,
  onSkipToTrack,
}: SortableItemProps) {
  const [isHovered, setIsHovered] = useState(false);
  const isDraggable = item.queueStatus === QueueItemStatus.Pending;

  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: item.queueItemId,
    disabled: !isDraggable,
  });

  const style: CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
    padding: '12px 16px',
    borderBottom: '1px solid #f0f0f0',
    backgroundColor: selected
      ? '#e6f4ff'
      : item.queueStatus === QueueItemStatus.Playing
        ? '#f6ffed'
        : 'transparent',
    // Hide original slot while DragOverlay follows the cursor
    opacity: isDragging ? 0 : 1,
  };

  return (
    <List.Item
      ref={setNodeRef}
      style={style}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      actions={[
        // Only show Play button when the item is not currently playing
        item.queueStatus !== QueueItemStatus.Playing && (
          <Tooltip
            key='play'
            title='Play this track'
          >
            <Button
              type='text'
              size='small'
              icon={<PlayCircleOutlined />}
              onClick={() => onSkipToTrack?.(item.queueItemId, item.trackId)}
            />
          </Tooltip>
        ),
        <Tooltip
          key='remove'
          title={
            item.queueStatus === QueueItemStatus.Playing
              ? 'Remove current track and transition to next'
              : 'Remove from queue'
          }
        >
          <Button
            type='text'
            size='small'
            danger
            icon={<DeleteOutlined />}
            onClick={() => onRemove(item.queueItemId)}
          />
        </Tooltip>,
      ]}
    >
      <List.Item.Meta
        avatar={
          <Space>
            <div
              {...attributes}
              {...(isDraggable ? listeners : {})}
              style={{
                cursor: isDraggable ? 'grab' : 'default',
                touchAction: 'none',
                display: 'flex',
                alignItems: 'center',
                width: 16,
                opacity: isHovered && isDraggable ? 1 : 0,
                transition: 'opacity 0.15s ease',
              }}
            >
              <DragOutlined style={{ color: '#1890ff' }} />
            </div>
            <Checkbox
              checked={selected}
              onChange={(e) =>
                onSelectChange(item.queueItemId, e.target.checked)
              }
              onClick={(e) => e.stopPropagation()}
            />
            {/* Cover image if available */}
            {item.coverImageUrl ? (
              <img
                src={item.coverImageUrl}
                alt={item.trackName}
                style={{
                  width: 40,
                  height: 40,
                  objectFit: 'cover',
                  borderRadius: 4,
                }}
              />
            ) : (
              <div
                style={{
                  width: 40,
                  height: 40,
                  background: '#fafafa',
                  borderRadius: 4,
                }}
              />
            )}
          </Space>
        }
        title={
          <Space>
            {getStatusIcon(item.queueStatus)}
            <Text>{item.trackName}</Text>
          </Space>
        }
        description={
          <Space size='small'>
            <Tag
              color={getStatusColor(item.queueStatus)}
              style={{ fontSize: 11 }}
            >
              {getStatusLabel(item.queueStatus)}
            </Tag>
            <Tag
              color={getSourceColor(item.source)}
              style={{ fontSize: 11 }}
            >
              {getSourceLabel(item.source)}
            </Tag>
            {!item.isReadyToStream && (
              <Tag
                color='warning'
                style={{ fontSize: 11 }}
              >
                Transcoding...
              </Tag>
            )}
          </Space>
        }
      />
    </List.Item>
  );
});

export const QueueList = ({
  items,
  loading,
  onRemove,
  onRemoveMany,
  onReorder,
  onSkipToTrack,
}: QueueListProps) => {
  const [selectedQueueItemIds, setSelectedQueueItemIds] = useState<string[]>(
    [],
  );
  const [activeId, setActiveId] = useState<string | null>(null);
  const [localItems, setLocalItems] = useState<SpaceQueueItemResponse[]>(() =>
    [...items].sort((a, b) => a.position - b.position),
  );

  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    }),
  );

  // Sync from props only when not actively dragging — preserves optimistic order
  useEffect(() => {
    if (!activeId) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setLocalItems([...items].sort((a, b) => a.position - b.position));
    }
  }, [items, activeId]);

  const activeItem = useMemo(
    () => localItems.find((item) => item.queueItemId === activeId) ?? null,
    [localItems, activeId],
  );

  const visibleQueueItemIdSet = useMemo(
    () => new Set(localItems.map((item) => item.queueItemId)),
    [localItems],
  );

  const effectiveSelectedQueueItemIds = useMemo(
    () => selectedQueueItemIds.filter((id) => visibleQueueItemIdSet.has(id)),
    [selectedQueueItemIds, visibleQueueItemIdSet],
  );

  const handleSelectItem = useCallback(
    (queueItemId: string, checked: boolean) => {
      setSelectedQueueItemIds((prev) => {
        if (checked) {
          return prev.includes(queueItemId) ? prev : [...prev, queueItemId];
        }

        return prev.filter((id) => id !== queueItemId);
      });
    },
    [],
  );

  if (!items || items.length === 0) {
    return (
      <Empty
        image={Empty.PRESENTED_IMAGE_SIMPLE}
        description='No tracks in queue'
        style={{ padding: '40px 0' }}
      />
    );
  }

  const allSelected =
    localItems.length > 0 &&
    effectiveSelectedQueueItemIds.length === localItems.length;

  const handleSelectAll = (checked: boolean) => {
    setSelectedQueueItemIds(
      checked ? localItems.map((item) => item.queueItemId) : [],
    );
  };

  const handleRemoveSelected = async () => {
    if (!onRemoveMany || effectiveSelectedQueueItemIds.length === 0) {
      return;
    }

    await onRemoveMany(effectiveSelectedQueueItemIds);
    setSelectedQueueItemIds([]);
  };

  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string);
  };

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveId(null);

    if (!over || active.id === over.id || !onReorder) {
      return;
    }

    const oldIndex = localItems.findIndex(
      (item) => item.queueItemId === active.id,
    );
    const newIndex = localItems.findIndex(
      (item) => item.queueItemId === over.id,
    );

    if (oldIndex === -1 || newIndex === -1) return;

    const reordered = arrayMove(localItems, oldIndex, newIndex);
    setLocalItems(reordered);
    onReorder(reordered.map((item) => item.queueItemId));
  };

  const handleDragCancel = () => {
    setActiveId(null);
  };

  return (
    <Space
      direction='vertical'
      size='small'
      style={{ width: '100%' }}
    >
      <Space
        align='center'
        style={{ width: '100%', justifyContent: 'space-between' }}
      >
        <Checkbox
          checked={allSelected}
          onChange={(e) => handleSelectAll(e.target.checked)}
        >
          Select all
        </Checkbox>

        {effectiveSelectedQueueItemIds.length > 0 && onRemoveMany && (
          <Popconfirm
            title='Remove selected tracks'
            description={`Remove ${effectiveSelectedQueueItemIds.length} selected track(s) from queue?`}
            onConfirm={handleRemoveSelected}
            okText='Remove'
            cancelText='Cancel'
            okButtonProps={{ danger: true }}
          >
            <Button
              danger
              size='small'
              icon={<DeleteOutlined />}
            >
              Remove ({effectiveSelectedQueueItemIds.length})
            </Button>
          </Popconfirm>
        )}
      </Space>

      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
        onDragCancel={handleDragCancel}
      >
        <SortableContext
          items={localItems.map((item) => item.queueItemId)}
          strategy={verticalListSortingStrategy}
        >
          <List
            loading={loading}
            dataSource={localItems}
            renderItem={(item) => (
              <SortableItem
                key={item.queueItemId}
                item={item}
                selected={effectiveSelectedQueueItemIds.includes(
                  item.queueItemId,
                )}
                onSelectChange={handleSelectItem}
                onRemove={onRemove}
                onSkipToTrack={onSkipToTrack}
              />
            )}
          />
        </SortableContext>
        <DragOverlay dropAnimation={null}>
          {activeItem ? (
            <DragOverlayItem
              item={activeItem}
              selected={effectiveSelectedQueueItemIds.includes(
                activeItem.queueItemId,
              )}
            />
          ) : null}
        </DragOverlay>
      </DndContext>
    </Space>
  );
};
