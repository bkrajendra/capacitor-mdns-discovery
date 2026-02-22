import { registerPlugin } from '@capacitor/core';
import type { MdnsDiscoveryPlugin } from './definitions';

const MdnsDiscovery = registerPlugin<MdnsDiscoveryPlugin>('MdnsDiscovery', {
  web: () => import('./web').then(m => new m.MdnsDiscoveryWeb()),
});

export * from './definitions';
export { MdnsDiscovery };
