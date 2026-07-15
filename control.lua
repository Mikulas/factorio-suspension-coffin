local COFFIN_NAME = "suspension-coffin"
local COFFIN_VEHICLE_NAME = "suspension-coffin-vehicle"
local COFFIN_SPEED = 100
local NORMAL_SPEED = 1
local VIGNETTE_SPRITE = "suspension-coffin-vignette"
local SUSPENSION_RAMP_TICKS = 900
local STATUS_FRAME_WIDTH = 520
local STATUS_DOT_TICKS = 270
local VIGNETTE_BASE_TILES = 32
local VIGNETTE_SCALE_MARGIN = 1.2
local VIGNETTE_MIN_SCALE = 3.2
local VIGNETTE_MAX_SCALE = 32
local SUSPENSION_PERMISSION_GROUP = "suspension-coffin--suspended"

local function init_storage()
  storage.players_in_coffins = storage.players_in_coffins or {}
  storage.vignettes = storage.vignettes or {}
  storage.suspension_transitions = storage.suspension_transitions or {}
  storage.suspension_ui = storage.suspension_ui or {}
  storage.suspension_permission_groups = storage.suspension_permission_groups or {}
  storage.coffins = storage.coffins or {}
  storage.vehicle_to_coffin = storage.vehicle_to_coffin or {}
end

local function configure_suspension_permission_group(group)
  for _, action in pairs(defines.input_action) do
    group.set_allows_action(action, false)
  end

  -- The player must always be able to leave the coffin with the normal
  -- enter/exit-vehicle control. Console access is retained as a recovery path.
  group.set_allows_action(defines.input_action.toggle_driving, true)
  group.set_allows_action(defines.input_action.write_to_console, true)
end

local function get_suspension_permission_group()
  local group = game.permissions.get_group(SUSPENSION_PERMISSION_GROUP)
  if group then
    return group
  end

  group = game.permissions.create_group(SUSPENSION_PERMISSION_GROUP)
  if group then
    configure_suspension_permission_group(group)
  end
  return group
end

local function lock_player_interactions(player)
  if storage.suspension_permission_groups[player.index] == nil then
    local previous_group = player.permission_group
    storage.suspension_permission_groups[player.index] =
      previous_group and previous_group.group_id or false
  end

  local group = get_suspension_permission_group()
  if group and player.permission_group ~= group then
    player.permission_group = group
  end
end

local function restore_player_permissions(player)
  local previous_group_id = storage.suspension_permission_groups[player.index]
  if previous_group_id == nil then
    return
  end

  storage.suspension_permission_groups[player.index] = nil

  local previous_group = nil
  if type(previous_group_id) == "number" then
    previous_group = game.permissions.get_group(previous_group_id)
  end

  player.permission_group = previous_group
end

local function is_coffin_vehicle(entity)
  return entity and entity.valid and entity.name == COFFIN_VEHICLE_NAME
end

local function is_coffin_entity(entity)
  return entity and entity.valid and entity.name == COFFIN_NAME
end

local function destroy_vignette(player_index)
  local render_ids = storage.vignettes[player_index]
  if not render_ids then
    return
  end

  for _, render_id in pairs(render_ids) do
    local object = rendering.get_object_by_id(render_id)
    if object then
      object.destroy()
    end
  end

  storage.vignettes[player_index] = nil
end

local function set_vignette_alpha(player_index, alpha)
  local render_ids = storage.vignettes[player_index]
  if not render_ids then
    return
  end

  for _, render_id in pairs(render_ids) do
    local object = rendering.get_object_by_id(render_id)
    if object then
      object.color = {r = 1, g = 1, b = 1, a = alpha}
    end
  end
end

local function calculate_vignette_scale(player)
  local resolution = player.display_resolution
  local zoom = player.zoom

  if not zoom or zoom <= 0 then
    zoom = 1
  end

  -- At zoom 1, one tile is approximately 32 display pixels. Use the viewport
  -- diagonal rather than width/height so the square vignette stays offscreen
  -- at the corners. Clamp to avoid extreme scales from unusual zoom states.
  local visible_width_tiles = resolution.width / (32 * zoom)
  local visible_height_tiles = resolution.height / (32 * zoom)
  local visible_diagonal_tiles = math.sqrt(
    (visible_width_tiles * visible_width_tiles) +
    (visible_height_tiles * visible_height_tiles)
  )

  local scale = (visible_diagonal_tiles / VIGNETTE_BASE_TILES) * VIGNETTE_SCALE_MARGIN
  return math.min(VIGNETTE_MAX_SCALE, math.max(VIGNETTE_MIN_SCALE, scale))
end

local function update_vignette_scale(player)
  local render_ids = storage.vignettes[player.index]
  if not render_ids then
    return
  end

  local scale = calculate_vignette_scale(player)
  for _, render_id in pairs(render_ids) do
    local object = rendering.get_object_by_id(render_id)
    if object then
      object.x_scale = scale
      object.y_scale = scale
    end
  end
end

local VIEW_SETTING_KEYS = {
  "show_controller_gui",
  "show_minimap",
  "show_research_info",
  "show_entity_info",
  "show_alert_gui",
  "update_entity_selection",
  "show_side_menu",
  "show_pins_gui",
  "show_map_view_options",
  "show_entity_tooltip",
  "show_quickbar",
  "show_shortcut_bar",
  "show_crafting_queue",
  "show_tool_bar",
  "show_hotkey_suggestions",
  "show_surface_list"
}

local function destroy_suspension_gui(player)
  local frame = player.gui.screen.suspension_coffin_status
  if frame then
    frame.destroy()
  end
end

local function position_suspension_gui(player, frame)
  local resolution = player.display_resolution
  local scale = player.display_scale
  local frame_width = STATUS_FRAME_WIDTH * scale

  frame.location = {
    math.max(0, math.floor((resolution.width - frame_width) / 2)),
    math.max(0, math.floor((resolution.height / 3) - (32 * scale)))
  }
end

local function restore_player_ui(player)
  local saved = storage.suspension_ui[player.index]
  destroy_suspension_gui(player)

  if saved then
    for _, key in pairs(VIEW_SETTING_KEYS) do
      if saved.game_view_settings[key] ~= nil then
        player.game_view_settings[key] = saved.game_view_settings[key]
      end
    end

    if saved.minimap_enabled ~= nil then
      player.minimap_enabled = saved.minimap_enabled
    end
  end

  storage.suspension_ui[player.index] = nil
end

local function hide_player_ui(player)
  if not storage.suspension_ui[player.index] then
    local saved = {
      game_view_settings = {},
      minimap_enabled = player.minimap_enabled
    }

    for _, key in pairs(VIEW_SETTING_KEYS) do
      saved.game_view_settings[key] = player.game_view_settings[key]
    end

    storage.suspension_ui[player.index] = saved
  end

  for _, key in pairs(VIEW_SETTING_KEYS) do
    player.game_view_settings[key] = false
  end
  player.minimap_enabled = false

  destroy_suspension_gui(player)

  local frame = player.gui.screen.add{
    type = "frame",
    name = "suspension_coffin_status",
    direction = "vertical",
    caption = ""
  }
  position_suspension_gui(player, frame)
  frame.style.padding = 24
  frame.style.width = STATUS_FRAME_WIDTH

  local flow = frame.add{
    type = "flow",
    name = "suspension_coffin_status_flow",
    direction = "horizontal"
  }
  flow.style.width = STATUS_FRAME_WIDTH - 48
  flow.style.horizontal_align = "center"

  local prefix = flow.add{
    type = "label",
    name = "suspension_coffin_status_prefix",
    caption = {"suspension-coffin.status-prefix"}
  }
  prefix.style.font = "heading-1"
  prefix.style.font_color = {r = 0.72, g = 0.95, b = 1.0}

  local dots = flow.add{
    type = "label",
    name = "suspension_coffin_status_dots",
    caption = "."
  }
  dots.style.font = "heading-1"
  dots.style.font_color = {r = 0.72, g = 0.95, b = 1.0}
  dots.style.width = 42
  dots.style.horizontal_align = "left"
end

local function update_suspension_status_text(player)
  local frame = player.gui.screen.suspension_coffin_status
  if not frame then
    return
  end

  local flow = frame.suspension_coffin_status_flow
  if not flow then
    return
  end

  local dots = flow.suspension_coffin_status_dots
  if not dots then
    return
  end

  local phase = math.floor(game.tick / STATUS_DOT_TICKS) % 4
  if phase == 0 then
    dots.caption = ""
  elseif phase == 1 then
    dots.caption = "."
  elseif phase == 2 then
    dots.caption = ".."
  elseif phase == 3 then
    dots.caption = "..."
  end
end

local function block_suspended_player_interaction(player)
  if not player or not player.valid or not is_coffin_vehicle(player.vehicle) then
    return
  end

  lock_player_interactions(player)

  if player.opened then
    player.opened = nil
  end

  player.clear_cursor()
end

local function reposition_suspension_gui(event)
  local player = game.get_player(event.player_index)
  if not player or not storage.players_in_coffins[event.player_index] then
    return
  end

  local frame = player.gui.screen.suspension_coffin_status
  if frame then
    position_suspension_gui(player, frame)
  end

  update_vignette_scale(player)
end

local function clear_players_in_vehicle(vehicle)
  for _, player in pairs(game.players) do
    if player.vehicle == vehicle then
      storage.players_in_coffins[player.index] = nil
      storage.suspension_transitions[player.index] = nil
      destroy_vignette(player.index)
      restore_player_ui(player)
      restore_player_permissions(player)
    end
  end
end

local function unlink_coffin(coffin_unit_number)
  local link = storage.coffins[coffin_unit_number]
  if not link then
    return
  end

  local vehicle = link.vehicle
  if vehicle and vehicle.valid then
    clear_players_in_vehicle(vehicle)
    storage.vehicle_to_coffin[vehicle.unit_number] = nil
    vehicle.destroy()
  end

  storage.coffins[coffin_unit_number] = nil
end

local function spawn_vehicle_for_coffin(coffin)
  if not is_coffin_entity(coffin) then
    return
  end

  unlink_coffin(coffin.unit_number)

  local vehicle = coffin.surface.create_entity{
    name = COFFIN_VEHICLE_NAME,
    position = coffin.position,
    force = coffin.force,
    direction = coffin.direction,
    raise_built = false,
    create_build_effect_smoke = false
  }

  if not vehicle then
    return
  end

  vehicle.destructible = false

  storage.coffins[coffin.unit_number] = {
    coffin = coffin,
    vehicle = vehicle
  }
  storage.vehicle_to_coffin[vehicle.unit_number] = coffin.unit_number
end

local function rebuild_links()
  for _, link in pairs(storage.coffins or {}) do
    if link.vehicle and link.vehicle.valid then
      clear_players_in_vehicle(link.vehicle)
      link.vehicle.destroy()
    end
  end

  storage.coffins = {}
  storage.vehicle_to_coffin = {}

  for _, surface in pairs(game.surfaces) do
    for _, coffin in pairs(surface.find_entities_filtered{name = COFFIN_NAME}) do
      spawn_vehicle_for_coffin(coffin)
    end
  end
end

local function entity_offset_target(entity, x, y)
  return {
    type = "entity",
    entity = entity,
    offset = {x, y}
  }
end

local function draw_vignette_sprite(player, vehicle)
  local scale = calculate_vignette_scale(player)
  local object = rendering.draw_sprite{
    sprite = VIGNETTE_SPRITE,
    target = entity_offset_target(vehicle, 0, 0),
    surface = vehicle.surface,
    players = {player.index},
    x_scale = scale,
    y_scale = scale,
    color = {r = 1, g = 1, b = 1, a = 0},
    render_layer = "255",
    render_mode = "game",
    only_in_alt_mode = false
  }
  object.bring_to_front()
  return object.id
end

local function create_vignette(player, vehicle)
  destroy_vignette(player.index)

  storage.vignettes[player.index] = {
    draw_vignette_sprite(player, vehicle)
  }
end

local function update_active_vignettes()
  for player_index in pairs(storage.players_in_coffins) do
    local player = game.get_player(player_index)
    if player and player.valid and is_coffin_vehicle(player.vehicle) then
      update_vignette_scale(player)
    end
  end
end

local function has_active_suspension()
  for player_index in pairs(storage.players_in_coffins) do
    local player = game.get_player(player_index)
    if player and player.valid and is_coffin_vehicle(player.vehicle) then
      return true
    end

    storage.players_in_coffins[player_index] = nil
    storage.suspension_transitions[player_index] = nil
    destroy_vignette(player_index)
    if player and player.valid then
      restore_player_ui(player)
      restore_player_permissions(player)
    end
  end

  return false
end

local function refresh_game_speed()
  if not has_active_suspension() then
    game.speed = NORMAL_SPEED
    return
  end

  local target_speed = NORMAL_SPEED
  for player_index in pairs(storage.players_in_coffins) do
    local transition = storage.suspension_transitions[player_index]

    if transition then
      local progress = math.min(1, math.max(0, (game.tick - transition.start_tick) / SUSPENSION_RAMP_TICKS))
      target_speed = math.max(target_speed, NORMAL_SPEED + ((COFFIN_SPEED - NORMAL_SPEED) * progress))
    else
      target_speed = COFFIN_SPEED
      break
    end
  end

  game.speed = target_speed
end

local function update_suspension_transitions()
  update_active_vignettes()

  local changed = false

  for player_index in pairs(storage.players_in_coffins) do
    local player = game.get_player(player_index)
    if player and player.valid and is_coffin_vehicle(player.vehicle) then
      update_suspension_status_text(player)
      block_suspended_player_interaction(player)
    end
  end

  for player_index, transition in pairs(storage.suspension_transitions) do
    local player = game.get_player(player_index)
    if not player or not player.valid or not is_coffin_vehicle(player.vehicle) then
      storage.suspension_transitions[player_index] = nil
      set_vignette_alpha(player_index, 1)
      changed = true
    else
      local progress = math.min(1, math.max(0, (game.tick - transition.start_tick) / SUSPENSION_RAMP_TICKS))
      set_vignette_alpha(player_index, progress)

      if progress >= 1 then
        storage.suspension_transitions[player_index] = nil
      end

      changed = true
    end
  end

  if changed then
    refresh_game_speed()
  end
end

local function on_player_driving_changed_state(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  local vehicle = player.vehicle
  if is_coffin_vehicle(vehicle) then
    storage.players_in_coffins[event.player_index] = true
    storage.suspension_transitions[event.player_index] = {start_tick = game.tick}
    create_vignette(player, vehicle)
    hide_player_ui(player)
    block_suspended_player_interaction(player)
  else
    storage.players_in_coffins[event.player_index] = nil
    storage.suspension_transitions[event.player_index] = nil
    destroy_vignette(event.player_index)
    restore_player_ui(player)
    restore_player_permissions(player)
  end

  refresh_game_speed()
end

local function on_player_removed(event)
  storage.players_in_coffins[event.player_index] = nil
  storage.suspension_transitions[event.player_index] = nil
  destroy_vignette(event.player_index)
  local player = game.get_player(event.player_index)
  if player then
    restore_player_ui(player)
    restore_player_permissions(player)
  end
  refresh_game_speed()
end

local function on_gui_opened(event)
  if not storage.players_in_coffins[event.player_index] then
    return
  end

  local player = game.get_player(event.player_index)
  block_suspended_player_interaction(player)
end

local function on_created_entity(event)
  local entity = event.created_entity or event.entity or event.destination
  if is_coffin_entity(entity) then
    spawn_vehicle_for_coffin(entity)
  end
end

local function on_removed_entity(event)
  local entity = event.entity
  if not entity or not entity.valid then
    return
  end

  if is_coffin_entity(entity) then
    unlink_coffin(entity.unit_number)
    refresh_game_speed()
    return
  end

  if is_coffin_vehicle(entity) then
    local coffin_unit_number = storage.vehicle_to_coffin[entity.unit_number]
    storage.vehicle_to_coffin[entity.unit_number] = nil
    if coffin_unit_number then
      storage.coffins[coffin_unit_number] = nil
    end
    clear_players_in_vehicle(entity)
    refresh_game_speed()
  end
end

script.on_init(function()
  init_storage()
  get_suspension_permission_group()
end)
script.on_configuration_changed(function()
  init_storage()

  for player_index in pairs(storage.suspension_permission_groups) do
    local player = game.get_player(player_index)
    if player and player.valid then
      restore_player_permissions(player)
    end
  end

  for player_index in pairs(storage.suspension_ui) do
    local player = game.get_player(player_index)
    if player and player.valid then
      restore_player_ui(player)
    end
  end

  rendering.clear("suspension-coffin")
  storage.vignettes = {}
  storage.suspension_transitions = {}
  storage.suspension_ui = {}
  storage.suspension_permission_groups = {}
  get_suspension_permission_group()
  rebuild_links()
  refresh_game_speed()
end)

script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
script.on_event(defines.events.on_tick, update_suspension_transitions)
script.on_event(defines.events.on_player_left_game, on_player_removed)
script.on_event(defines.events.on_player_removed, on_player_removed)
script.on_event(defines.events.on_player_display_resolution_changed, reposition_suspension_gui)
script.on_event(defines.events.on_player_display_scale_changed, reposition_suspension_gui)
script.on_event(defines.events.on_gui_opened, on_gui_opened)

script.on_event(defines.events.on_built_entity, on_created_entity)
script.on_event(defines.events.on_robot_built_entity, on_created_entity)
script.on_event(defines.events.script_raised_built, on_created_entity)
script.on_event(defines.events.script_raised_revive, on_created_entity)

script.on_event(defines.events.on_pre_player_mined_item, on_removed_entity)
script.on_event(defines.events.on_robot_pre_mined, on_removed_entity)
script.on_event(defines.events.on_entity_died, on_removed_entity)
script.on_event(defines.events.script_raised_destroy, on_removed_entity)
