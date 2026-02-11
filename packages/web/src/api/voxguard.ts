/**
 * VoxGuard API Client
 * Adapted from VoxSwitch-IM frontend for the VoxGuard standalone app.
 */

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '/api/v1';

async function fetchJSON<T>(url: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('voxguard-token');
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const response = await fetch(url, { ...options, headers });
  if (!response.ok) throw new Error(`Request failed: ${response.status}`);
  if (response.status === 204) return undefined as T;
  return response.json() as Promise<T>;
}

// Types
export interface RVSHealth {
  status: 'connected' | 'degraded' | 'disconnected';
  latency_ms: number;
  uptime_pct: number;
  last_check: string;
  circuit_breaker: 'closed' | 'open' | 'half-open';
  version: string;
}

export interface VerificationRequest {
  id: string;
  calling_number: string;
  called_number: string;
  timestamp: string;
  rvs_score: number;
  hlr_status: string;
  hlr_network: string;
  hlr_country: string;
  response_time_ms: number;
  cached: boolean;
}

export interface CompositeDecision {
  id: string;
  call_id: string;
  timestamp: string;
  voxguard_score: number;
  rvs_score: number;
  composite_score: number;
  decision: 'allow' | 'block' | 'review';
  factors: { name: string; weight: number; value: number; contribution: number }[];
  latency_ms: number;
}

export interface ListEntry {
  id: string;
  list_type: 'blacklist' | 'whitelist';
  pattern: string;
  pattern_type: string;
  reason: string;
  added_by: string;
  added_at: string;
  expires_at?: string;
  hit_count: number;
  last_hit?: string;
  source: string;
}

export interface MultiCallPattern {
  id: string;
  b_number: string;
  call_count: number;
  unique_a_numbers: number;
  time_window_minutes: number;
  first_seen: string;
  last_seen: string;
  risk_score: number;
  status: string;
  source_ips?: string[];
  fraud_type?: string;
}

export interface WangiriIncident {
  id: string;
  calling_number: string;
  country: string;
  ring_duration_sec: number;
  callback_count: number;
  revenue_risk: number;
  detected_at: string;
  status: string;
  destination_type: string;
}

export interface IrsfIncident {
  id: string;
  destination: string;
  country: string;
  total_minutes: number;
  total_cost: number;
  pump_pattern: string;
  detected_at: string;
  status: string;
}

export interface TrafficRule {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
  priority: number;
  conditions: { field: string; operator: string; value: string }[];
  action: string;
  created_at: string;
  updated_at: string;
  hit_count: number;
}

export interface FalsePositiveCase {
  id: string;
  original_alert_id: string;
  alert_type: string;
  calling_number: string;
  called_number: string;
  original_score: number;
  status: string;
  confidence: number;
  detection_method?: string;
  matched_patterns?: string[];
}

export interface FeatureFlag {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
  phase: string;
  updated_at: string;
}

export interface MLModelStatus {
  model_name: string;
  version: string;
  status: string;
  accuracy: number;
  last_trained: string;
  features_count: number;
}

export interface DetectionEngineHealth {
  status: string;
  latency_p99_ms: number;
  calls_per_second: number;
  cache_hit_rate: number;
  uptime_pct: number;
}

// API Client
export const voxguardApi = {
  // RVS
  getRVSHealth: () => fetchJSON<RVSHealth>(`${API_BASE_URL}/rvs/health`),
  getVerifications: () => fetchJSON<VerificationRequest[]>(`${API_BASE_URL}/rvs/verifications`),

  // Composite
  getCompositeDecisions: () => fetchJSON<CompositeDecision[]>(`${API_BASE_URL}/composite/decisions`),

  // Lists
  getListEntries: (type: string) => fetchJSON<ListEntry[]>(`${API_BASE_URL}/lists?type=${type}`),
  createListEntry: (entry: Partial<ListEntry>) => fetchJSON<ListEntry>(`${API_BASE_URL}/lists`, { method: 'POST', body: JSON.stringify(entry) }),
  deleteListEntry: (id: string) => fetchJSON<void>(`${API_BASE_URL}/lists/${id}`, { method: 'DELETE' }),

  // Multi-Call
  getMultiCallPatterns: () => fetchJSON<MultiCallPattern[]>(`${API_BASE_URL}/multicall/patterns`),
  blockMultiCallPattern: (id: string) => fetchJSON<unknown>(`${API_BASE_URL}/multicall/patterns/${id}/block`, { method: 'POST' }),

  // Revenue Fraud
  getWangiriIncidents: () => fetchJSON<WangiriIncident[]>(`${API_BASE_URL}/wangiri/incidents`),
  getIrsfIncidents: () => fetchJSON<IrsfIncident[]>(`${API_BASE_URL}/irsf/incidents`),
  blockWangiri: (id: string) => fetchJSON<unknown>(`${API_BASE_URL}/wangiri/incidents/${id}/block`, { method: 'POST' }),

  // Traffic
  getTrafficRules: () => fetchJSON<TrafficRule[]>(`${API_BASE_URL}/traffic/rules`),
  createTrafficRule: (rule: Partial<TrafficRule>) => fetchJSON<TrafficRule>(`${API_BASE_URL}/traffic/rules`, { method: 'POST', body: JSON.stringify(rule) }),
  deleteTrafficRule: (id: string) => fetchJSON<void>(`${API_BASE_URL}/traffic/rules/${id}`, { method: 'DELETE' }),

  // False Positives
  getFalsePositives: () => fetchJSON<FalsePositiveCase[]>(`${API_BASE_URL}/false-positives`),

  // Feature Flags
  getFeatureFlags: () => fetchJSON<FeatureFlag[]>(`${API_BASE_URL}/feature-flags`),
  updateFeatureFlag: (id: string, enabled: boolean) => fetchJSON<FeatureFlag>(`${API_BASE_URL}/feature-flags/${id}`, { method: 'PUT', body: JSON.stringify({ enabled }) }),

  // ML & Detection
  getMLModelStatus: () => fetchJSON<MLModelStatus[]>(`${API_BASE_URL}/ml/status`),
  getDetectionHealth: () => fetchJSON<DetectionEngineHealth>(`${API_BASE_URL}/detection/health`),
  getDashboardSummary: () => fetchJSON<unknown>(`${API_BASE_URL}/dashboard/summary`),
};
