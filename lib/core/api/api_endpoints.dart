class ApiEndpoints {
  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String modules = '/api/auth/modules';

  // Daily Logs
  static const String dailyLogs = '/api/daily-logs';
  static String dailyLogById(String id) => '/api/daily-logs/$id';

  // Workouts
  static const String workouts = '/api/workouts';
  static String workoutById(String id) => '/api/workouts/$id';
  static String workoutExercises(String id) => '/api/workouts/$id/exercises';
  static String workoutExercise(String id, String exId) => '/api/workouts/$id/exercises/$exId';
  static String workoutExerciseSets(String id, String exId) => '/api/workouts/$id/exercises/$exId/sets';
  static String workoutSet(String id, String setId) => '/api/workouts/$id/sets/$setId';

  // Gyms
  static const String gyms = '/api/gyms';
  static String gymById(String id) => '/api/gyms/$id';

  // Machines
  static const String machines = '/api/machines';
  static String machineById(String id) => '/api/machines/$id';
  static String machineHistory(String id) => '/api/machines/$id/history';

  // Plannings
  static const String plannings = '/api/plannings';
  static String planningById(String id) => '/api/plannings/$id';

  // Routines
  static const String routines = '/api/routines';
  static String routineById(String id) => '/api/routines/$id';
  static String routineExercises(String id) => '/api/routines/$id/exercises';
  static String routineExercise(String id, String exId) => '/api/routines/$id/exercises/$exId';

  // Meals
  static const String meals = '/api/meals';
  static String mealById(String id) => '/api/meals/$id';

  // Hydration
  static const String hydration = '/api/hydration';
  static String hydrationById(String id) => '/api/hydration/$id';

  // Supplements
  static const String supplements = '/api/supplements';
  static String supplementById(String id) => '/api/supplements/$id';
  static String supplementLog(String id) => '/api/supplements/$id/log';
  static String supplementLogs(String id) => '/api/supplements/$id/logs';
  static const String supplementLogsList = '/api/supplement-logs';

  // Body Checks
  static const String bodyChecks = '/api/body-checks';
  static String bodyCheckById(String id) => '/api/body-checks/$id';

  // Cardio
  static const String cardio = '/api/cardio';
  static String cardioById(String id) => '/api/cardio/$id';

  // Sleep
  static const String sleep = '/api/sleep';
  static String sleepById(String id) => '/api/sleep/$id';

  // Heart Rate
  static const String heartRate = '/api/heart-rate';
  static const String heartRateBatch = '/api/heart-rate/batch';

  // Devices
  static const String devices = '/api/devices';
  static String deviceById(String id) => '/api/devices/$id';
}
