import { Router } from 'express';
import authRoutes from './auth.routes';
import usersRoutes from './users.routes';
import workoutsRoutes from './workouts.routes';
import analyticsRoutes from './analytics.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/workouts', workoutsRoutes);
router.use('/analytics', analyticsRoutes);

export default router;
