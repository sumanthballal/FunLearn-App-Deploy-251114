import {
  ActivityResponse,
  ActivitiesResponse,
  ModulesResponse,
  ProgressResponse,
  EmotionResponse,
  RecommendationsResponse,
  parseResponse,
} from './schemas';

const BASE_URL = 'http://127.0.0.1:5000';

// Timeout duration in milliseconds (5 seconds)
const TIMEOUT_MS = 5000;

// Reusable fetch with timeout and error handling
async function fetchWithTimeout(url: string, options: RequestInit = {}) {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), TIMEOUT_MS);
  
  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
    });
    clearTimeout(id);
    return response;
  } catch (error) {
    clearTimeout(id);
    if (error instanceof Error && error.name === 'AbortError') {
      throw new Error('Request timed out');
    }
    throw error;
  }
}

// API endpoints with validation and error handling
export async function getModules() {
  const response = await fetchWithTimeout(`${BASE_URL}/api/modules`);
  return parseResponse(ModulesResponse, response);
}

export async function getActivities(module: string) {
  const response = await fetchWithTimeout(`${BASE_URL}/api/activities/${module}`);
  return parseResponse(ActivitiesResponse, response);
}

export async function getActivity(id: string) {
  const response = await fetchWithTimeout(`${BASE_URL}/api/activity/${id}`);
  return parseResponse(ActivityResponse, response);
}

export async function getProgress(user: string) {
  const response = await fetchWithTimeout(`${BASE_URL}/progress/${user}`);
  return parseResponse(ProgressResponse, response);
}

export async function detectEmotion(imageBlob: Blob) {
  const formData = new FormData();
  formData.append('image', imageBlob);

  const response = await fetchWithTimeout(`${BASE_URL}/detect_emotion`, {
    method: 'POST',
    body: formData,
  });
  return parseResponse(EmotionResponse, response);
}

export async function getRecommendations(user: string) {
  const response = await fetchWithTimeout(`${BASE_URL}/recommend/${user}`);
  return parseResponse(RecommendationsResponse, response);
}

// Error types for better error handling
export class NetworkError extends Error {
  constructor(message = 'Network error occurred') {
    super(message);
    this.name = 'NetworkError';
  }
}

export class TimeoutError extends Error {
  constructor(message = 'Request timed out') {
    super(message);
    this.name = 'TimeoutError';
  }
}

export class ValidationError extends Error {
  constructor(message = 'Data validation failed') {
    super(message);
    this.name = 'ValidationError';
  }
}