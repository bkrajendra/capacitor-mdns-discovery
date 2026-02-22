export interface MdnsDevice {
  name: string;
  host: string;
  port: number;
  serviceType: string;
  txtRecords: Record<string, string>;
}

export interface StartDiscoveryOptions {
  serviceType?: string;
}

export interface StopDiscoveryOptions {
  serviceType?: string;
}

export interface MdnsDiscoveryPlugin {
  startDiscovery(options?: StartDiscoveryOptions): Promise<void>;
  stopDiscovery(options?: StopDiscoveryOptions): Promise<void>;
  addListener(
    eventName: 'deviceFound',
    listenerFunc: (device: MdnsDevice) => void
  ): Promise<{ remove: () => void }>;
  addListener(
    eventName: 'deviceLost',
    listenerFunc: (device: Pick<MdnsDevice, 'name' | 'serviceType'>) => void
  ): Promise<{ remove: () => void }>;
  addListener(
    eventName: 'discoveryError',
    listenerFunc: (error: { message: string; code: number }) => void
  ): Promise<{ remove: () => void }>;
  removeAllListeners(): Promise<void>;
}
