# capacitor-mdns-discovery

mDNS device discovery for IoT Devices

## Install

```bash
npm install capacitor-mdns-discovery
npx cap sync
```

## API

<docgen-index>

* [`startDiscovery(...)`](#startdiscovery)
* [`stopDiscovery(...)`](#stopdiscovery)
* [`addListener('deviceFound', ...)`](#addlistenerdevicefound-)
* [`addListener('deviceLost', ...)`](#addlistenerdevicelost-)
* [`addListener('discoveryError', ...)`](#addlistenerdiscoveryerror-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### startDiscovery(...)

```typescript
startDiscovery(options?: StartDiscoveryOptions | undefined) => Promise<void>
```

| Param         | Type                                                                    |
| ------------- | ----------------------------------------------------------------------- |
| **`options`** | <code><a href="#startdiscoveryoptions">StartDiscoveryOptions</a></code> |

--------------------


### stopDiscovery(...)

```typescript
stopDiscovery(options?: StopDiscoveryOptions | undefined) => Promise<void>
```

| Param         | Type                                                                  |
| ------------- | --------------------------------------------------------------------- |
| **`options`** | <code><a href="#stopdiscoveryoptions">StopDiscoveryOptions</a></code> |

--------------------


### addListener('deviceFound', ...)

```typescript
addListener(eventName: 'deviceFound', listenerFunc: (device: MdnsDevice) => void) => Promise<{ remove: () => void; }>
```

| Param              | Type                                                                   |
| ------------------ | ---------------------------------------------------------------------- |
| **`eventName`**    | <code>'deviceFound'</code>                                             |
| **`listenerFunc`** | <code>(device: <a href="#mdnsdevice">MdnsDevice</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;{ remove: () =&gt; void; }&gt;</code>

--------------------


### addListener('deviceLost', ...)

```typescript
addListener(eventName: 'deviceLost', listenerFunc: (device: Pick<MdnsDevice, 'name' | 'serviceType'>) => void) => Promise<{ remove: () => void; }>
```

| Param              | Type                                                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'deviceLost'</code>                                                                                                       |
| **`listenerFunc`** | <code>(device: <a href="#pick">Pick</a>&lt;<a href="#mdnsdevice">MdnsDevice</a>, 'name' \| 'serviceType'&gt;) =&gt; void</code> |

**Returns:** <code>Promise&lt;{ remove: () =&gt; void; }&gt;</code>

--------------------


### addListener('discoveryError', ...)

```typescript
addListener(eventName: 'discoveryError', listenerFunc: (error: { message: string; code: number; }) => void) => Promise<{ remove: () => void; }>
```

| Param              | Type                                                                |
| ------------------ | ------------------------------------------------------------------- |
| **`eventName`**    | <code>'discoveryError'</code>                                       |
| **`listenerFunc`** | <code>(error: { message: string; code: number; }) =&gt; void</code> |

**Returns:** <code>Promise&lt;{ remove: () =&gt; void; }&gt;</code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

--------------------


### Interfaces


#### StartDiscoveryOptions

| Prop              | Type                |
| ----------------- | ------------------- |
| **`serviceType`** | <code>string</code> |


#### StopDiscoveryOptions

| Prop              | Type                |
| ----------------- | ------------------- |
| **`serviceType`** | <code>string</code> |


#### MdnsDevice

| Prop              | Type                                                            |
| ----------------- | --------------------------------------------------------------- |
| **`name`**        | <code>string</code>                                             |
| **`host`**        | <code>string</code>                                             |
| **`port`**        | <code>number</code>                                             |
| **`serviceType`** | <code>string</code>                                             |
| **`txtRecords`**  | <code><a href="#record">Record</a>&lt;string, string&gt;</code> |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>


#### Pick

From T, pick a set of properties whose keys are in the union K

<code>{ [P in K]: T[P]; }</code>

</docgen-api>
