import { WebPlugin } from '@capacitor/core';
import type { MdnsDiscoveryPlugin, StartDiscoveryOptions, StopDiscoveryOptions } from './definitions';

export class MdnsDiscoveryWeb extends WebPlugin implements MdnsDiscoveryPlugin {
  async startDiscovery(_options?: StartDiscoveryOptions): Promise<void> {
    console.warn('[MdnsDiscovery] Not supported in browser.');
  }
  async stopDiscovery(_options?: StopDiscoveryOptions): Promise<void> {
    console.warn('[MdnsDiscovery] Not supported in browser.');
  }
}
