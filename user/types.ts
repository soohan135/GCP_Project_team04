import React from 'react';

export interface RepairPart {
  name: string;
  cost: number;
  description: string;
  severity: 'low' | 'medium' | 'high';
}

export interface DamageEstimate {
  totalCost: number;
  currency: string;
  parts: RepairPart[];
  summary: string;
  vehicleType?: string;
}

export enum AppState {
  IDLE = 'IDLE',
  ANALYZING = 'ANALYZING',
  RESULT = 'RESULT',
  ERROR = 'ERROR'
}

export type Tab = 'home' | 'preview' | 'response' | 'chat' | 'map';

export interface NavItem {
  id: Tab;
  label: string;
  icon: React.ElementType;
}