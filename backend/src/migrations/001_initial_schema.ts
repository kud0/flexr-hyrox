import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // Users table
  await knex.schema.createTable('users', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('apple_user_id').unique().notNullable();
    table.string('email').unique();
    table.string('first_name');
    table.string('last_name');
    table.enum('fitness_level', ['beginner', 'intermediate', 'advanced', 'elite']).defaultTo('intermediate');
    table.integer('age');
    table.enum('gender', ['male', 'female', 'other']);
    table.decimal('weight_kg', 5, 2);
    table.decimal('height_cm', 5, 2);
    table.jsonb('goals').defaultTo('[]');
    table.jsonb('injuries').defaultTo('[]');
    table.string('time_zone').defaultTo('UTC');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.timestamp('last_login_at');
  });

  // Training architectures table
  await knex.schema.createTable('training_architectures', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('name').notNullable();
    table.text('description');
    table.integer('weeks_to_race').notNullable();
    table.date('race_date');
    table.integer('workouts_per_week').notNullable().defaultTo(4);
    table.jsonb('weekly_structure').notNullable(); // Array of day configs
    table.jsonb('focus_areas').defaultTo('[]'); // e.g., ["running", "strength"]
    table.boolean('is_active').defaultTo(true);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });

  // Workouts table
  await knex.schema.createTable('workouts', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('architecture_id').references('id').inTable('training_architectures').onDelete('SET NULL');
    table.string('title').notNullable();
    table.text('description');
    table.enum('type', ['strength', 'running', 'hybrid', 'recovery', 'race_sim']).notNullable();
    table.date('scheduled_date');
    table.integer('total_duration_minutes');
    table.enum('difficulty', ['easy', 'moderate', 'hard', 'very_hard']).notNullable();
    table.integer('readiness_score'); // Score used when generating
    table.enum('status', ['scheduled', 'in_progress', 'completed', 'skipped']).defaultTo('scheduled');
    table.timestamp('started_at');
    table.timestamp('completed_at');
    table.jsonb('ai_context'); // Context used for AI generation
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());

    table.index(['user_id', 'scheduled_date']);
    table.index(['user_id', 'status']);
  });

  // Workout segments table
  await knex.schema.createTable('workout_segments', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('workout_id').notNullable().references('id').inTable('workouts').onDelete('CASCADE');
    table.integer('order_index').notNullable();
    table.enum('type', ['warmup', 'strength', 'cardio', 'hybrid', 'cooldown']).notNullable();
    table.string('name').notNullable();
    table.text('instructions');
    table.integer('duration_minutes');
    table.integer('sets');
    table.integer('reps');
    table.decimal('distance_km', 6, 2);
    table.string('target_pace'); // e.g., "5:30/km"
    table.string('target_heart_rate'); // e.g., "140-160 bpm"
    table.integer('rest_seconds');
    table.jsonb('exercises'); // Array of exercise objects for strength segments
    table.jsonb('metadata'); // Additional segment-specific data

    // Actual performance data (filled after completion)
    table.decimal('actual_distance_km', 6, 2);
    table.string('actual_pace');
    table.integer('actual_duration_minutes');
    table.integer('actual_heart_rate_avg');
    table.enum('completion_status', ['not_started', 'completed', 'partial', 'skipped']).defaultTo('not_started');
    table.text('notes');

    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());

    table.index(['workout_id', 'order_index']);
  });

  // Performance profiles table (AI learning)
  await knex.schema.createTable('performance_profiles', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.date('week_starting').notNullable();

    // Running performance
    table.decimal('avg_pace_km', 4, 2); // minutes per km
    table.integer('total_running_distance_km');
    table.integer('compromised_running_count').defaultTo(0); // Sessions where running < 3km

    // Strength performance
    table.integer('strength_sessions_completed');
    table.jsonb('strength_progression'); // Track weight/rep progressions

    // Recovery metrics
    table.decimal('avg_readiness_score', 3, 1);
    table.integer('recovery_sessions_completed');

    // Confidence metrics (0-1 scale)
    table.decimal('running_confidence', 3, 2).defaultTo(0.5);
    table.decimal('strength_confidence', 3, 2).defaultTo(0.5);
    table.decimal('endurance_confidence', 3, 2).defaultTo(0.5);

    // Learning metadata
    table.jsonb('workout_completion_rate'); // By type
    table.jsonb('ai_adjustments'); // Track AI decisions
    table.integer('version').defaultTo(1); // Profile version for weighted updates

    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());

    table.unique(['user_id', 'week_starting']);
    table.index(['user_id', 'week_starting']);
  });

  // Weekly summaries table
  await knex.schema.createTable('weekly_summaries', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.date('week_starting').notNullable();
    table.date('week_ending').notNullable();

    table.integer('workouts_planned');
    table.integer('workouts_completed');
    table.integer('total_duration_minutes');
    table.decimal('total_distance_km', 6, 2);
    table.decimal('avg_readiness_score', 3, 1);

    table.jsonb('workout_breakdown'); // By type
    table.jsonb('performance_insights'); // AI-generated insights
    table.text('notes');

    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());

    table.unique(['user_id', 'week_starting']);
    table.index(['user_id', 'week_starting']);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('weekly_summaries');
  await knex.schema.dropTableIfExists('performance_profiles');
  await knex.schema.dropTableIfExists('workout_segments');
  await knex.schema.dropTableIfExists('workouts');
  await knex.schema.dropTableIfExists('training_architectures');
  await knex.schema.dropTableIfExists('users');
}
