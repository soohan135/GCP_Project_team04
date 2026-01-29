export interface EstimateResult {
  damageAnalysis: string;
  estimatedCostMin: number;
  estimatedCostMax: number;
  repairSteps: string[];
  funFact: string; // A cute message from the AI character
}

export enum AppView {
  HOME = 'HOME',
  ESTIMATE = 'ESTIMATE',
  CHAT = 'CHAT',
  MAP = 'MAP'
}
