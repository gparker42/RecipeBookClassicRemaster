local math = require("__flib__.math")

local constants = require("constants")

local util = require("scripts.util")

local fluid_proc = require("scripts.processors.fluid")

return function(recipe_book, dictionaries, metadata)
  for name, prototype in pairs(global.prototypes.recipe) do
    local category = prototype.category
    local group = prototype.group

    local enabled_at_start = prototype.enabled

    -- Add to recipe category
    local category_data = recipe_book.recipe_category[category]
    category_data.recipes[#category_data.recipes + 1] = {class = "recipe", name = name}

    -- Add to group
    local group_data = recipe_book.group[group.name]
    group_data.recipes[#group_data.recipes + 1] = {class = "recipe", name = name}

    local data = {
      class = "recipe",
      enabled_at_start = enabled_at_start,
      energy = prototype.energy,
      group = {class = "group", name = group.name},
      hidden = prototype.hidden,
      made_in = {},
      prototype_name = name,
      recipe_category = {class = "recipe_category", name = category},
      unlocked_by = {},
      used_as_fixed_recipe = metadata.fixed_recipes[name]
    }

    -- ingredients / products
    for lookup_type, io_type in pairs{ingredient_in = "ingredients", product_of = "products"} do
      local output = {}
      for i, material in ipairs(prototype[io_type]) do
        local amount_ident = util.build_amount_ident(material)
        local material_io_data = {
          class = material.type,
          name = material.name,
          amount_ident = amount_ident
        }
        local material_data = recipe_book[material.type][material.name]
        local lookup_table = material_data[lookup_type]
        lookup_table[#lookup_table + 1] = {class = "recipe", name = name}
        output[i] = material_io_data
        material_data.recipe_categories[#material_data.recipe_categories + 1] = category

        -- Don't set enabled at start if this is an ignored recipe
        local disabled = constants.disabled_categories.recipe_category[category]
        if io_type == "products" and (not disabled or disabled ~= 0) then
          local subtable = category_data[material.type.."s"]
          subtable[#subtable + 1] = {class = material.type, name = material.name}
          if enabled_at_start then
            material_data.enabled_at_start = true
          end
        end

        -- fluid temperatures
        if material.type == "fluid" then
          local temperature_ident = util.build_temperature_ident(material)
          if temperature_ident then
            material_io_data.temperature_ident = temperature_ident
            fluid_proc.add_temperature(
              recipe_book,
              dictionaries,
              metadata,
              recipe_book.fluid[material.name],
              temperature_ident
            )
          end
        end
      end

      data[io_type] = output
    end

    -- made in
    local num_ingredients = #data.ingredients
    for crafter_name, crafter_data in pairs(recipe_book.crafter) do
      if (crafter_data.ingredient_limit or 255) >= num_ingredients
        and crafter_data.recipe_categories_lookup[category]
      then
        local crafting_time = math.round_to(prototype.energy / crafter_data.crafting_speed, 2)
        data.made_in[#data.made_in + 1] = {
          class = "crafter",
          name = crafter_name,
          amount_ident = util.build_amount_ident{amount = crafting_time, format = "format_seconds_parenthesis"}
        }
        crafter_data.compatible_recipes[#crafter_data.compatible_recipes + 1] = {class = "recipe", name = name}
      end
    end

    recipe_book.recipe[name] = data
    dictionaries.recipe:add(name, prototype.localised_name)
    dictionaries.recipe_description:add(name, prototype.localised_description)
  end
end
