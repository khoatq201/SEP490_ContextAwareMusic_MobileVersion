import { MiniPlayer } from './MiniPlayer';
import { ExpandedPlayer } from './ExpandedPlayer';

type MusicPlayerProps = {
  sidebarCollapsed?: boolean;
};

export const MusicPlayer = ({ sidebarCollapsed }: MusicPlayerProps) => {
  return (
    <>
      <MiniPlayer sidebarCollapsed={sidebarCollapsed} />
      <ExpandedPlayer />
    </>
  );
};
