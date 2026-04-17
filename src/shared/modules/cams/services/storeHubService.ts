import {
  HubConnection,
  HubConnectionBuilder,
  LogLevel,
  HubConnectionState,
} from '@microsoft/signalr';
import { env } from '@/config';
import type {
  PlayStreamPayload,
  PlaybackStateChangedPayload,
  SpaceStateDto,
} from '../types';

type StoreHubEventHandlers = {
  onPlayStream?: (payload: PlayStreamPayload) => void;
  onPlaybackStateChanged?: (payload: PlaybackStateChangedPayload) => void;
  onSpaceStateSync?: (spaceId: string, state: SpaceStateDto) => void;
  onConnected?: () => void;
  onDisconnected?: () => void;
  onReconnecting?: () => void;
  onReconnected?: () => void;
};

class StoreHubService {
  private connection: HubConnection | null = null;
  private currentStoreId: string | null = null;
  private joinedSpaceIds = new Set<string>();
  private eventHandlers: StoreHubEventHandlers = {};

  /**
   * Clock offset in ms: clientNow - serverNow at connection time.
   * Positive means client clock is ahead of server.
   * Used by getEffectiveSeekOffset to correct seek positions.
   */
  private _serverClockOffsetMs = 0;

  /** Exposed to playbackHelpers so seek math can compensate for clock skew. */
  public get serverClockOffsetMs(): number {
    return this._serverClockOffsetMs;
  }

  /**
   * Check if connection is active
   */
  public isConnected(): boolean {
    return (
      this.connection !== null &&
      this.connection.state === HubConnectionState.Connected
    );
  }

  /**
   * Connect to StoreHub and join manager room
   */
  public async connect(
    storeId: string,
    token: string,
    handlers: StoreHubEventHandlers = {},
  ): Promise<void> {
    // ✅ Prevent double-connect
    if (this.isConnected() && this.currentStoreId === storeId) {
      console.log('⏭️ Already connected to this store');
      return;
    }

    try {
      // ✅ Disconnect existing connection first
      if (this.connection) {
        console.log('🔄 Disconnecting existing connection...');
        await this.disconnect();
      }

      this.eventHandlers = handlers;
      this.currentStoreId = storeId;

      const hubUrl = `${env.baseUrl}/hubs/store`;

      console.log('🔌 Connecting to StoreHub:', {
        baseUrl: env.baseUrl,
        hubUrl,
        storeId,
        hasToken: !!token,
      });

      // Build connection
      this.connection = new HubConnectionBuilder()
        .withUrl(hubUrl, {
          accessTokenFactory: () => token,
        })
        .withAutomaticReconnect({
          nextRetryDelayInMilliseconds: (retryContext) => {
            // Exponential backoff: 2s, 4s, 8s, 16s, then 30s max
            const delay = Math.min(
              2000 * Math.pow(2, retryContext.previousRetryCount),
              30000,
            );
            console.log(
              `⏰ Retry ${retryContext.previousRetryCount + 1} in ${delay}ms`,
            );
            return delay;
          },
        })
        .configureLogging(LogLevel.Information)
        .build();

      // Register event listeners
      this.registerEventListeners();

      // Start connection
      await this.connection.start();

      console.log('✅ StoreHub connected successfully');

      // ✅ Wait a bit before joining to ensure connection is stable
      await new Promise((resolve) => setTimeout(resolve, 100));

      // Join manager room
      await this.joinStore(storeId);

      // Trigger connected callback
      this.eventHandlers.onConnected?.();
    } catch (error) {
      console.error('❌ Failed to connect to StoreHub:', error);
      this.connection = null;
      this.currentStoreId = null;
      throw error;
    }
  }

  /**
   * Join manager room for a store
   */
  private async joinStore(storeId: string): Promise<void> {
    if (!this.connection) {
      throw new Error('Connection not initialized');
    }

    // ✅ Check connection state before invoking
    if (this.connection.state !== HubConnectionState.Connected) {
      throw new Error(
        `Cannot join store: Connection state is ${this.connection.state}`,
      );
    }

    try {
      console.log('🚪 Joining manager room for store:', storeId);
      await this.connection.invoke('JoinManagerRoomAsync', storeId);
      console.log('✅ Joined manager room successfully');
    } catch (error) {
      console.error('❌ Failed to join manager room:', error);
      throw error;
    }
  }

  /**
   * Leave current store's manager room
   */
  private async leaveStore(): Promise<void> {
    if (!this.connection || !this.currentStoreId) {
      return;
    }

    // ✅ Only try to leave if connected
    if (this.connection.state !== HubConnectionState.Connected) {
      console.log('⏭️ Connection not active, skipping leave');
      return;
    }

    try {
      console.log('🚪 Leaving manager room for store:', this.currentStoreId);
      await this.connection.invoke(
        'LeaveManagerRoomAsync',
        this.currentStoreId,
      );
      console.log('✅ Left manager room successfully');
    } catch (error) {
      console.error('❌ Failed to leave store:', error);
      // Don't throw - just log
    }
  }

  /**
   * Join a specific space group to receive real-time updates
   */
  public async joinSpace(spaceId: string): Promise<void> {
    if (!this.connection) {
      throw new Error('Connection not initialized');
    }

    if (this.connection.state !== HubConnectionState.Connected) {
      throw new Error(
        `Cannot join space: Connection state is ${this.connection.state}`,
      );
    }

    try {
      console.log('🎵 Joining space group:', spaceId);
      await this.connection.invoke('JoinSpaceAsync', spaceId);
      this.joinedSpaceIds.add(spaceId);
      console.log('✅ Joined space group successfully:', spaceId);
    } catch (error) {
      console.error('❌ Failed to join space group:', error);
      throw error;
    }
  }

  /**
   * Leave a specific space group
   */
  public async leaveSpace(spaceId: string): Promise<void> {
    if (!this.connection) {
      return;
    }

    if (this.connection.state !== HubConnectionState.Connected) {
      console.log('⏭️ Connection not active, skipping leave space');
      return;
    }

    try {
      console.log('👋 Leaving space group:', spaceId);
      await this.connection.invoke('LeaveSpaceAsync', spaceId);
      this.joinedSpaceIds.delete(spaceId);
      console.log('✅ Left space group successfully:', spaceId);
    } catch (error) {
      console.error('❌ Failed to leave space group:', error);
      // Don't throw - just log
    }
  }

  /**
   * Register SignalR event listeners
   */
  private registerEventListeners(): void {
    if (!this.connection) return;

    // Server ack after JoinSpaceAsync / JoinManagerRoomAsync (camelCase over the wire)
    this.connection.on(
      'connectionconfirmed',
      (data: { serverTimeUtc?: string } | null) => {
        if (data?.serverTimeUtc) {
          const serverMs = new Date(data.serverTimeUtc).getTime();
          this._serverClockOffsetMs = Date.now() - serverMs;
          console.log(
            `🕐 Server clock offset computed: ${this._serverClockOffsetMs.toFixed(0)}ms (client − server)`,
          );
        }
      },
    );

    // PlayStream event (new track/playlist)
    this.connection.on('PlayStream', (payload: PlayStreamPayload) => {
      console.log('📡 PlayStream event:', payload);
      this.eventHandlers.onPlayStream?.(payload);
    });

    // PlaybackStateChanged event (pause/resume/skip)
    this.connection.on(
      'PlaybackStateChanged',
      (payload: PlaybackStateChangedPayload) => {
        console.log('📡 PlaybackStateChanged event:', payload);
        this.eventHandlers.onPlaybackStateChanged?.(payload);
      },
    );

    // SpaceStateSync event (full state sync)
    this.connection.on('SpaceStateSync', (state: SpaceStateDto) => {
      console.log('📡 SpaceStateSync event:', state);
      this.eventHandlers.onSpaceStateSync?.(state.spaceId, state);
    });

    // Connection lifecycle events
    this.connection.onreconnecting(() => {
      console.log('🔄 SignalR reconnecting...');
      this.eventHandlers.onReconnecting?.();
    });

    this.connection.onreconnected(async () => {
      console.log('✅ SignalR reconnected');
      try {
        // Rejoin manager room after reconnect
        if (this.currentStoreId) {
          await this.joinStore(this.currentStoreId);
        }

        // Rejoin all active space groups after reconnect.
        const spaceIds = Array.from(this.joinedSpaceIds);
        await Promise.all(
          spaceIds.map(async (spaceId) => {
            try {
              await this.connection?.invoke('JoinSpaceAsync', spaceId);
              console.log('✅ Rejoined space group after reconnect:', spaceId);
            } catch (err) {
              console.error('❌ Failed to rejoin space group:', spaceId, err);
            }
          }),
        );
      } finally {
        this.eventHandlers.onReconnected?.();
      }
    });

    this.connection.onclose(() => {
      console.log('❌ SignalR connection closed');
      this.eventHandlers.onDisconnected?.();
    });
  }

  /**
   * Disconnect from StoreHub
   */
  public async disconnect(): Promise<void> {
    if (!this.connection) {
      return;
    }

    try {
      // Leave manager room
      await this.leaveStore();

      // Stop connection
      await this.connection.stop();

      console.log('👋 StoreHub disconnected gracefully');
    } catch (error) {
      console.error('❌ Error during disconnect:', error);
    } finally {
      this.connection = null;
      this.currentStoreId = null;
      this.joinedSpaceIds.clear();
      this.eventHandlers = {};
    }
  }
}

// Singleton instance
export const storeHubService = new StoreHubService();
