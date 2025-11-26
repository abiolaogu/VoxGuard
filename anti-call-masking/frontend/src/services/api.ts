import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5001';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for auth token
api.interceptors.request.use((config) => {
  const authData = localStorage.getItem('acm-auth-storage');
  if (authData) {
    const { state } = JSON.parse(authData);
    if (state.token) {
      config.headers.Authorization = `Bearer ${state.token}`;
    }
  }
  return config;
});

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('acm-auth-storage');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Alert Types
export interface Alert {
  id: string;
  timestamp: string;
  bNumber: string;
  aNumbers: string[];
  sourceIps: string[];
  callCount: number;
  windowSeconds: number;
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  status: 'NEW' | 'INVESTIGATING' | 'RESOLVED' | 'FALSE_POSITIVE';
  assignedTo?: string;
  notes?: string;
}

export interface ThreatLevel {
  bNumber: string;
  threatLevel: number;
  distinctANumbers: number;
  distinctIps: number;
  callCount: number;
  lastSeen: string;
}

export interface SystemStats {
  totalAlerts: number;
  criticalAlerts: number;
  highAlerts: number;
  resolvedToday: number;
  avgResponseTime: number;
  callsProcessed: number;
  fraudPrevented: number;
  systemUptime: number;
}

export interface TrafficMetrics {
  timestamp: string;
  callsPerSecond: number;
  alertsPerMinute: number;
  detectionLatency: number;
}

// API Functions
export const alertsApi = {
  getAll: async (params?: { status?: string; severity?: string; limit?: number }) => {
    const response = await api.get<Alert[]>('/acm/alerts', { params });
    return response.data;
  },

  getById: async (id: string) => {
    const response = await api.get<Alert>(`/acm/alerts/${id}`);
    return response.data;
  },

  updateStatus: async (id: string, status: Alert['status'], notes?: string) => {
    const response = await api.patch<Alert>(`/acm/alerts/${id}`, { status, notes });
    return response.data;
  },

  assign: async (id: string, userId: string) => {
    const response = await api.patch<Alert>(`/acm/alerts/${id}/assign`, { userId });
    return response.data;
  },

  getRecent: async (minutes: number = 60) => {
    const response = await api.get<Alert[]>('/acm/alerts', { params: { minutes } });
    return response.data;
  },
};

export const threatApi = {
  getLevel: async (bNumber: string) => {
    const response = await api.get<ThreatLevel>('/acm/threat', { params: { b_number: bNumber } });
    return response.data;
  },

  getElevated: async () => {
    const response = await api.get<ThreatLevel[]>('/acm/threats');
    return response.data;
  },
};

export const statsApi = {
  getSystem: async () => {
    const response = await api.get<SystemStats>('/acm/stats');
    return response.data;
  },

  getTraffic: async (minutes: number = 60) => {
    const response = await api.get<TrafficMetrics[]>('/api/v1/analytics/traffic', { params: { minutes } });
    return response.data;
  },

  getHealth: async () => {
    const response = await api.get('/health');
    return response.data;
  },
};

export const analyticsApi = {
  getCarrierStats: async (minutes: number = 60) => {
    const response = await api.get('/api/v1/analytics/carriers', { params: { minutes } });
    return response.data;
  },

  getDestinationStats: async (minutes: number = 60, prefixLen: number = 3) => {
    const response = await api.get('/api/v1/analytics/destinations', { params: { minutes, prefixLen } });
    return response.data;
  },

  getHourlyPattern: async (days: number = 7) => {
    const response = await api.get('/api/v1/analytics/hourly', { params: { days } });
    return response.data;
  },
};
