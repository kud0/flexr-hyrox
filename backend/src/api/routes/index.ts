import { Router } from 'express';
import authRoutes from './auth.routes';
import usersRoutes from './users.routes';
import workoutsRoutes from './workouts.routes';
import analyticsRoutes from './analytics.routes';
import gymsRoutes from './gyms.routes';
import relationshipsRoutes from './relationships.routes';
import socialRoutes from './social.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/workouts', workoutsRoutes);
router.use('/analytics', analyticsRoutes);
router.use('/gyms', gymsRoutes);
router.use('/relationships', relationshipsRoutes);
router.use('/social', socialRoutes);

export default router;
