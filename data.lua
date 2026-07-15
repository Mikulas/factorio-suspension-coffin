local entity_graphic = "__suspension-coffin__/graphics/entity/suspension-coffin/suspension-coffin.png"
local item_icon = "__suspension-coffin__/graphics/icons/suspension-coffin.png"
local technology_icon = "__suspension-coffin__/graphics/technology/suspension-coffin.png"
local vignette_graphic = "__suspension-coffin__/graphics/effects/suspension-vignette.png"

local subgroup = {
  type = "item-subgroup",
  name = "suspension-coffin",
  group = "space",
  order = "c[suspension-coffin]"
}

local vignette_sprite = {
  type = "sprite",
  name = "suspension-coffin-vignette",
  filename = vignette_graphic,
  priority = "extra-high-no-scale",
  width = 1024,
  height = 1024
}

local coffin = {
  type = "simple-entity-with-owner",
  name = "suspension-coffin",
  localised_name = {"entity-name.suspension-coffin"},
  localised_description = {"entity-description.suspension-coffin"},
  icon = item_icon,
  icon_size = 64,
  flags = {"placeable-player", "player-creation"},
  minable = {
    mining_time = 0.5,
    result = "suspension-coffin"
  },
  selection_box = {{-2.0, -2.0}, {2.0, 2.0}},
  collision_box = {{-1.9, -1.9}, {1.9, 1.9}},
  surface_conditions = {
    {
      property = "gravity",
      min = 0.1
    }
  },
  max_health = 500,
  corpse = "medium-remnants",
  dying_explosion = "medium-explosion",
  picture = {
    filename = entity_graphic,
    priority = "high",
    width = 1254,
    height = 1254,
    scale = 0.12,
    shift = {0, -0.05}
  }
}

local coffin_vehicle = table.deepcopy(data.raw["car"]["car"])

coffin_vehicle.name = "suspension-coffin-vehicle"
coffin_vehicle.localised_name = {"entity-name.suspension-coffin"}
coffin_vehicle.localised_description = {"entity-description.suspension-coffin"}
coffin_vehicle.icon = item_icon
coffin_vehicle.icon_size = 64
coffin_vehicle.flags = {"placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable"}
coffin_vehicle.selectable_in_game = false
coffin_vehicle.minable = nil
coffin_vehicle.selection_box = {{-2.0, -2.0}, {2.0, 2.0}}
coffin_vehicle.collision_box = {{-0.1, -0.1}, {0.1, 0.1}}
coffin_vehicle.collision_mask = {layers = {}}
coffin_vehicle.surface_conditions = {
  {
    property = "gravity",
    min = 0.1
  }
}
coffin_vehicle.max_health = 500
coffin_vehicle.inventory_size = 0
coffin_vehicle.guns = nil
coffin_vehicle.equipment_grid = nil
coffin_vehicle.turret_animation = nil
coffin_vehicle.light_animation = nil
coffin_vehicle.water_reflection = nil
coffin_vehicle.animation = {
  layers = {
    {
      filename = "__core__/graphics/empty.png",
      priority = "low",
      width = 1,
      height = 1,
      direction_count = 1
    }
  }
}

-- Keep the script-owned vehicle fixed in place. The visible chamber is the
-- actual placed entity; this invisible vehicle exists only to let the player
-- enter/exit a "coffin".
coffin_vehicle.energy_source = {type = "void"}
coffin_vehicle.consumption = "1W"
coffin_vehicle.braking_power = "1000MW"
coffin_vehicle.rotation_speed = 0
coffin_vehicle.weight = 1000000000
coffin_vehicle.friction = 1
coffin_vehicle.terrain_friction_modifier = 1

local item = {
  type = "item-with-entity-data",
  name = "suspension-coffin",
  localised_name = {"item-name.suspension-coffin"},
  localised_description = {"item-description.suspension-coffin"},
  icon = item_icon,
  icon_size = 64,
  subgroup = "suspension-coffin",
  order = "a[suspension-coffin]",
  place_result = "suspension-coffin",
  weight = 1 * tons,
  stack_size = 20
}

local recipe = {
  type = "recipe",
  name = "suspension-coffin",
  localised_name = {"recipe-name.suspension-coffin"},
  subgroup = "suspension-coffin",
  order = "a[suspension-coffin]",
  enabled = false,
  energy_required = 30,
  ingredients = {
    {type = "item", name = "fluoroketone-cold-barrel", amount = 10},
    {type = "item", name = "cryogenic-plant", amount = 1},
    {type = "item", name = "heating-tower", amount = 5},
    {type = "item", name = "steel-plate", amount = 100}
  },
  results = {
    {type = "item", name = "suspension-coffin", amount = 1}
  }
}

local technology = {
  type = "technology",
  name = "suspension-coffin",
  localised_name = {"technology-name.suspension-coffin"},
  localised_description = {"technology-description.suspension-coffin"},
  icon = technology_icon,
  icon_size = 256,
  effects = {
    {
      type = "unlock-recipe",
      recipe = "suspension-coffin"
    }
  },
  prerequisites = {"cryogenic-science-pack"},
  unit = {
    count = 500,
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"agricultural-science-pack", 1},
      {"cryogenic-science-pack", 1}
    },
    time = 60
  },
  order = "e-p-b-c"
}

data:extend({subgroup, vignette_sprite, coffin, coffin_vehicle, item, recipe, technology})
