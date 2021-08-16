local util = require("scripts.util")

return function(recipe_book, dictionaries, metadata)
  -- Characters as crafters
  for name, prototype in pairs(global.prototypes.character) do
    local ingredient_limit = prototype.ingredient_count
    if ingredient_limit == 255 then
      ingredient_limit = nil
    end
    recipe_book.crafter[name] = {
      blueprintable = false,
      class = "crafter",
      compatible_fuels = {}, -- Always empty
      compatible_modules = {}, -- Always empty
      compatible_recipes = {},
      crafting_speed = 1,
      enabled = true,
      hidden = false,
      ingredient_limit = ingredient_limit,
      is_character = true,
      placed_by = util.process_placed_by(prototype),
      prototype_name = name,
      recipe_categories_lookup = prototype.crafting_categories,
      recipe_categories = util.convert_categories(prototype.crafting_categories, "recipe_category"),
      unlocked_by = {}
    }
    dictionaries.crafter:add(name, prototype.localised_name)
    dictionaries.crafter_description:add(name, prototype.localised_description)
  end

  -- Actual crafters
  metadata.allowed_effects = {}
  metadata.crafter_fluidbox_counts = {}
  metadata.fixed_recipes = {}
  local rocket_silo_categories = util.unique_obj_array()
  for name, prototype in pairs(global.prototypes.crafter) do
    -- Fixed recipe
    local fixed_recipe
    if prototype.fixed_recipe then
      metadata.fixed_recipes[prototype.fixed_recipe] = true
      fixed_recipe = {class = "recipe", name = prototype.fixed_recipe}
    end

    -- Rocket silo categories
    if prototype.rocket_parts_required then
      for category in pairs(prototype.crafting_categories) do
        table.insert(rocket_silo_categories, {class = "recipe_category", name = category})
      end
    end

    local ingredient_limit = prototype.ingredient_count
    if ingredient_limit == 255 then
      ingredient_limit = nil
    end

    metadata.allowed_effects[name] = prototype.allowed_effects

    local fluidboxes = prototype.fluidbox_prototypes
    if fluidboxes then
      local fluidbox_counts = {inputs = 0, outputs = 0}
      for _, fluidbox in pairs(fluidboxes) do
        local type = fluidbox.production_type
        if string.find(type, "input") then
          fluidbox_counts.inputs = fluidbox_counts.inputs + 1
        end
        if string.find(type, "output") then
          fluidbox_counts.outputs = fluidbox_counts.outputs + 1
        end
      end
      metadata.crafter_fluidbox_counts[name] = fluidbox_counts
    end

    local is_hidden = prototype.has_flag("hidden")
    recipe_book.crafter[name] = {
      blueprintable = not is_hidden and not prototype.has_flag("not-blueprintable"),
      class = "crafter",
      compatible_fuels = {},
      compatible_modules = {},
      compatible_recipes = {},
      crafting_speed = prototype.crafting_speed,
      fixed_recipe = fixed_recipe,
      fuel_categories = util.process_energy_source(prototype),
      hidden = is_hidden,
      ingredient_limit = ingredient_limit,
      placed_by = util.process_placed_by(prototype),
      prototype_name = name,
      recipe_categories_lookup = prototype.crafting_categories,
      recipe_categories = util.convert_categories(prototype.crafting_categories, "recipe_category"),
      rocket_parts_required = prototype.rocket_parts_required,
      size = util.get_size(prototype),
      unlocked_by = {}
    }
    dictionaries.crafter:add(name, prototype.localised_name)
    dictionaries.crafter_description:add(name, prototype.localised_description)
  end

  metadata.rocket_silo_categories = rocket_silo_categories
end
