import { z } from 'zod';

// Basic types
export const ModuleSchema = z.enum(['Math', 'Science', 'Reading', 'Art']);

export const MediaSchema = z.object({
  type: z.enum(['image', 'youtube']),
  src: z.string(),
}).or(z.null());

export const VideoSchema = z.object({
  url: z.string().url(),
}).optional();

// Activity schema
export const ActivitySchema = z.object({
  id: z.string(),
  module: z.string(),
  title: z.string(),
  type: z.enum(['lesson', 'practice', 'fun', 'quiz']),
  duration: z.number().optional(),
  difficulty: z.enum(['easy', 'medium', 'hard']).optional(),
  description: z.string(),
  media: MediaSchema,
  video: VideoSchema,
});

// API Response schemas
export const ModulesResponse = z.object({
  modules: z.array(z.string()),
}).or(z.array(z.string()));

export const ActivitiesResponse = z.object({
  activities: z.array(ActivitySchema),
}).or(z.array(ActivitySchema));

export const ActivityResponse = ActivitySchema;

export const ProgressRecord = z.object({
  user: z.string(),
  module: z.string(),
  activity: z.string(),
  timestamp: z.string().datetime(),
});

export const ProgressResponse = z.array(ProgressRecord);

export const EmotionResponse = z.object({
  emotion: z.string(),
});

export const RecommendationsResponse = z.object({
  recommendations: z.array(z.object({
    title: z.string(),
    duration: z.number().optional(),
  })),
}).or(z.array(z.object({
  title: z.string(),
  duration: z.number().optional(),
})));

// Helper to safely parse API responses
export async function parseResponse<T>(schema: z.ZodType<T>, response: Response): Promise<T> {
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
  const data = await response.json();
  return schema.parse(data);
}