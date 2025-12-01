import { Response } from 'express';
import { z } from 'zod';
import supabaseAdmin from '../../config/supabase';
import { AuthRequest } from '../middleware/auth.middleware';
import { AppError } from '../middleware/error.middleware';

const updateUserSchema = z.object({
  email: z.string().email().optional(),
  firstName: z.string().optional(),
  lastName: z.string().optional(),
  fitnessLevel: z.enum(['beginner', 'intermediate', 'advanced', 'elite']).optional(),
  age: z.number().int().min(13).max(120).optional(),
  gender: z.enum(['male', 'female', 'other']).optional(),
  weightKg: z.number().positive().optional(),
  heightCm: z.number().positive().optional(),
  goals: z.array(z.string()).optional(),
  injuries: z.array(z.string()).optional(),
  timeZone: z.string().optional(),
});

/**
 * Get current user profile with stats
 */
export const getCurrentUser = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;

  const { data: user, error: userError } = await supabaseAdmin
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();

  if (userError || !user) {
    throw new AppError(404, 'User not found');
  }

  // Get workout stats
  const { data: workouts } = await supabaseAdmin
    .from('workouts')
    .select('id, status, total_duration_minutes')
    .eq('user_id', userId);

  const totalWorkouts = workouts?.length || 0;
  const completedWorkouts = workouts?.filter((w) => w.status === 'completed').length || 0;
  const totalDurationMinutes = workouts
    ?.filter((w) => w.status === 'completed')
    .reduce((sum, w) => sum + (w.total_duration_minutes || 0), 0) || 0;

  // Get total distance from completed segments
  const { data: segments } = await supabaseAdmin
    .from('workout_segments')
    .select('actual_distance_km, workout_id')
    .eq('completion_status', 'completed')
    .in(
      'workout_id',
      workouts?.map((w) => w.id) || []
    );

  const totalDistanceKm = segments
    ?.reduce((sum, s) => sum + (s.actual_distance_km || 0), 0) || 0;

  res.json({
    success: true,
    data: {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        fitnessLevel: user.fitness_level,
        age: user.age,
        gender: user.gender,
        weightKg: user.weight_kg,
        heightCm: user.height_cm,
        goals: user.goals,
        injuries: user.injuries,
        timeZone: user.time_zone,
        createdAt: user.created_at,
        lastLoginAt: user.last_login_at,
      },
      stats: {
        totalWorkouts,
        completedWorkouts,
        totalDurationMinutes,
        totalDistanceKm,
      },
    },
  });
};

/**
 * Update current user profile
 */
export const updateCurrentUser = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const updates = updateUserSchema.parse(req.body);

  // Convert camelCase to snake_case for database
  const dbUpdates: any = {};

  if (updates.email !== undefined) dbUpdates.email = updates.email;
  if (updates.firstName !== undefined) dbUpdates.first_name = updates.firstName;
  if (updates.lastName !== undefined) dbUpdates.last_name = updates.lastName;
  if (updates.fitnessLevel !== undefined) dbUpdates.fitness_level = updates.fitnessLevel;
  if (updates.age !== undefined) dbUpdates.age = updates.age;
  if (updates.gender !== undefined) dbUpdates.gender = updates.gender;
  if (updates.weightKg !== undefined) dbUpdates.weight_kg = updates.weightKg;
  if (updates.heightCm !== undefined) dbUpdates.height_cm = updates.heightCm;
  if (updates.goals !== undefined) dbUpdates.goals = updates.goals;
  if (updates.injuries !== undefined) dbUpdates.injuries = updates.injuries;
  if (updates.timeZone !== undefined) dbUpdates.time_zone = updates.timeZone;

  const { data: updatedUser, error } = await supabaseAdmin
    .from('users')
    .update(dbUpdates)
    .eq('id', userId)
    .select()
    .single();

  if (error || !updatedUser) {
    throw new AppError(500, 'Failed to update user');
  }

  res.json({
    success: true,
    data: {
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        firstName: updatedUser.first_name,
        lastName: updatedUser.last_name,
        fitnessLevel: updatedUser.fitness_level,
        age: updatedUser.age,
        gender: updatedUser.gender,
        weightKg: updatedUser.weight_kg,
        heightCm: updatedUser.height_cm,
        goals: updatedUser.goals,
        injuries: updatedUser.injuries,
        timeZone: updatedUser.time_zone,
      },
    },
  });
};

/**
 * Delete current user account
 */
export const deleteCurrentUser = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;

  const { error } = await supabaseAdmin
    .from('users')
    .delete()
    .eq('id', userId);

  if (error) {
    throw new AppError(500, 'Failed to delete user');
  }

  res.json({
    success: true,
    message: 'Account deleted successfully',
  });
};

/**
 * Get user by ID
 */
export const getUserById = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const currentUserId = req.user!.id;

  // Only allow users to view their own profile
  if (id !== currentUserId) {
    throw new AppError(403, 'You can only view your own profile');
  }

  const { data: user, error } = await supabaseAdmin
    .from('users')
    .select('*')
    .eq('id', id)
    .single();

  if (error || !user) {
    throw new AppError(404, 'User not found');
  }

  res.json({
    success: true,
    data: {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        fitnessLevel: user.fitness_level,
      },
    },
  });
};
