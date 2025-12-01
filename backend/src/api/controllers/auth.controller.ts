import { Request, Response } from 'express';
import { z } from 'zod';
import supabaseAdmin, { supabase } from '../../config/supabase';
import { generateToken } from '../middleware/auth.middleware';
import { AppError } from '../middleware/error.middleware';
import logger from '../../utils/logger';

const appleSignInSchema = z.object({
  identityToken: z.string().min(1),
  user: z.object({
    email: z.string().email().optional(),
    firstName: z.string().optional(),
    lastName: z.string().optional(),
  }).optional(),
});

const refreshTokenSchema = z.object({
  token: z.string().min(1),
});

/**
 * Apple Sign-In with Supabase Auth
 * Verifies Apple identity token and creates/updates user
 */
export const appleSignIn = async (req: Request, res: Response): Promise<void> => {
  const { identityToken, user: userData } = appleSignInSchema.parse(req.body);

  // TODO: Verify Apple identity token with Apple's public keys
  // For now, we'll extract the user ID from the token (in production, verify signature)
  let appleUserId: string;
  let email: string | undefined;

  try {
    // Decode token (without verification for demo - MUST verify in production)
    const tokenParts = identityToken.split('.');
    if (tokenParts.length !== 3) {
      throw new AppError(400, 'Invalid identity token format');
    }
    const payload = JSON.parse(Buffer.from(tokenParts[1], 'base64').toString());
    appleUserId = payload.sub;
    email = payload.email || userData?.email;

    if (!appleUserId) {
      throw new AppError(400, 'Invalid identity token - missing subject');
    }
  } catch (error) {
    logger.error('Failed to decode Apple identity token:', error);
    throw new AppError(400, 'Invalid identity token');
  }

  // Check if user exists
  const { data: existingUser, error: fetchError } = await supabaseAdmin
    .from('users')
    .select('*')
    .eq('apple_user_id', appleUserId)
    .single();

  let user;
  let isNewUser = false;

  if (fetchError && fetchError.code !== 'PGRST116') {
    // PGRST116 is "not found" error
    logger.error('Error fetching user:', fetchError);
    throw new AppError(500, 'Database error');
  }

  if (!existingUser) {
    // Create new user
    const { data: newUser, error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        apple_user_id: appleUserId,
        email: email || null,
        first_name: userData?.firstName || null,
        last_name: userData?.lastName || null,
        last_login_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (insertError) {
      logger.error('Error creating user:', insertError);
      throw new AppError(500, 'Failed to create user');
    }

    user = newUser;
    isNewUser = true;
    logger.info(`New user created: ${user.id}`);
  } else {
    // Update last login
    const { data: updatedUser, error: updateError } = await supabaseAdmin
      .from('users')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', existingUser.id)
      .select()
      .single();

    if (updateError) {
      logger.error('Error updating user:', updateError);
      throw new AppError(500, 'Failed to update user');
    }

    user = updatedUser;
  }

  // Generate JWT
  const token = generateToken({
    id: user.id,
    apple_user_id: user.apple_user_id,
  });

  res.json({
    success: true,
    data: {
      token,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        fitnessLevel: user.fitness_level,
      },
      isNewUser,
    },
  });
};

/**
 * Refresh JWT token
 */
export const refreshToken = async (req: Request, res: Response): Promise<void> => {
  const { token } = refreshTokenSchema.parse(req.body);

  // TODO: Verify old token and issue new one
  // For now, just return the same token (implement proper refresh token flow in production)

  res.json({
    success: true,
    data: {
      token,
    },
  });
};

/**
 * Logout
 * Client-side token invalidation (optional server-side blacklist)
 */
export const logout = async (req: Request, res: Response): Promise<void> => {
  // TODO: Add token to blacklist if implementing server-side invalidation

  res.json({
    success: true,
    message: 'Logged out successfully',
  });
};
