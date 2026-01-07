import axios, { AxiosError, AxiosRequestConfig } from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5001';

// API Configuration
const API_TIMEOUT = 30000; // 30 seconds
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 second base delay

// Custom error type for better error handling
export interface ApiError {
  message: string;
  status?: number;
  code?: string;
  isNetworkError: boolean;
  isTimeout: boolean;
}

// Helper to create API errors
function createApiError(error: AxiosError): ApiError {
  const isNetworkError = !error.response && error.code === 'ERR_NETWORK';
  const isTimeout = error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT';

  return {
    message: error.response?.data?.error || error.message || 'An unexpected error occurred',
    status: error.response?.status,
    code: error.code,
    isNetworkError,
    isTimeout,
  };
}

// Delay helper for retries
const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Retry logic with exponential backoff
async function retryRequest<T>(
  requestFn: () => Promise<T>,
  retries = MAX_RETRIES,
  delayMs = RETRY_DELAY
): Promise<T> {
  try {
    return await requestFn();
  } catch (error) {
    const axiosError = error as AxiosError;
    const status = axiosError.response?.status;

    // Don't retry client errors (4xx) except 429 (rate limit)
    if (status && status >= 400 && status < 500 && status !== 429) {
      throw error;
    }

    // Don't retry if no retries left
    if (retries <= 0) {
      throw error;
    }

    // Wait with exponential backoff
    await delay(delayMs);

    // Retry with reduced count and increased delay
    return retryRequest(requestFn, retries - 1, delayMs * 2);
  }
}

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for auth token
api.interceptors.request.use((config) => {
  const authData = localStorage.getItem('acm-auth-storage');
  if (authData) {
    try {
      const { state } = JSON.parse(authData);
      if (state?.token) {
        config.headers.Authorization = `Bearer ${state.token}`;
      }
    } catch {
      // Invalid JSON in storage, clear it
      localStorage.removeItem('acm-auth-storage');
    }
  }
  return config;
});

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('acm-auth-storage');
      // Only redirect if not already on login page
      if (!window.location.pathname.includes('/login')) {
        window.location.href = '/login';
      }
    }
    return Promise.reject(createApiError(error));
  }
);

// Helper for making requests with automatic retry
export async function apiRequest<T>(
  config: AxiosRequestConfig,
  options?: { retries?: number; skipRetry?: boolean }
): Promise<T> {
  const { retries = MAX_RETRIES, skipRetry = false } = options || {};

  const makeRequest = async () => {
    const response = await api.request<T>(config);
    return response.data;
  };

  if (skipRetry) {
    return makeRequest();
  }

  return retryRequest(makeRequest, retries);
}

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
