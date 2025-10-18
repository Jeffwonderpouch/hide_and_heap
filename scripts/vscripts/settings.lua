-- GAME CONFIGURATIONS
STRATEGY_TIME = 0.0               -- How long should strategy time last? Bug: You can buy items during strategy time and it will not be spent!
SHOWCASE_TIME = 0.0               -- How long should show case time be?
DEV_MODE = 0
REQUIRED_PUDGE_COUNT = 3 -- If there are less than the required number of actual pudge players, we will spawn in bots to fill the slots.
REQUIRED_CM_COUNT = 7 -- If there are less than the required number of actual CM players, we will spawn in bots to fill the rest of the slots.
HIDE_DURATION = 20
PRE_GAME_TIME = 20
MAX_ALLOWED = DOTA_MAX_TEAM_PLAYERS
LOBBY_WAIT_TIME = 30

PUDGE_INIT_STUN_DURATION = 18
PUDGE_INIT_SIZE_SCALE = 0.50
PUDGE_KILL_SIZE_SCALING = 0.25
PUDGE_KILL_VISION_BONUS = 250
PUDGE_KILL_MOVE_SPEED_BONUS = 25
PUDGE_STARTING_LEVEL = 20
PUDGE_STARTING_GOLD = 69

CM_STARTING_LEVEL = 5
CM_STARTING_GOLD = 69
CM_STARTING_DISTANCE_FROM_CENTER = 2500
SPREAD_CONTROL_FACTOR = 3

DEFAULT_STARTING_GOLD = 69
GOLD_PER_TICK = 69
TICK_DURATION = 60

GAME_ROUND_DURATION = 300 -- 5 minute long round.
ITEM_SPAWN_TIME = 90 -- new items will spawn every 60 seconds

ROUND_TIME = GAME_ROUND_DURATION -- honestly not even sure if this is used but i just set it to the other one.
AUTO_FILL_TEAMS = true


-- DEV MODE
DEV_MODE_CM_VISION = 2000