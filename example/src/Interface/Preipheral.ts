export interface Peripheral {
  identifier: string;
  name: string;
  rssi: number;
  advertisementData: Record<string, any>;
}
