local table = require("__flib__.table")
local translation = require("__flib__.translation")

local constants = require("constants")
local formatter = require("scripts.formatter")
local shared = require("scripts.shared")

local info_gui = require("scripts.gui.info.index")
local quick_ref_gui = require("scripts.gui.quick-ref")

local player_data = {}

function player_data.init(player_index)
  local data = {
    favorites = {},
    flags = {
      can_open_gui = false,
      gui_open = false,
      technology_gui_open = false,
      show_message_after_translation = false,
      translate_on_join = false
    },
    guis = {
      info = {
        _next_id = 1
      },
      quick_ref = {}
    },
    history = {
      global = {},
      session = {
        position = 1
      }
    },
    settings = {},
    translations = nil -- assigned its initial value in player_data.refresh
  }
  global.players[player_index] = data
end

function player_data.update_settings(player, player_table)
  local former_settings = player_table.settings
  local settings = {}

  -- Generic settings
  for _, settings_data in pairs(constants.settings) do
    for name, data in pairs(settings_data) do
      settings[name] = former_settings[name] or data.default_value
    end
  end

  -- Recipe categories
  local former_categories = former_settings.recipe_categories or {}
  local categories = {}
  for name in pairs(game.recipe_category_prototypes) do
    if former_categories[name] == nil then
      categories[name] = not constants.disabled_recipe_categories[name]
    end
  end
  settings.recipe_categories = categories

  -- Groups
  local former_groups = former_settings.groups or {}
  local groups = {}
  for name in pairs(global.recipe_book.group) do
    if former_groups[name] == nil then
      groups[name] = not constants.disabled_groups[name]
    end
  end
  settings.groups = groups

  -- Save to `global`
  player_table.settings = settings

  -- Create or purge memoizer cache
  formatter.create_cache(player.index)
end

function player_data.start_translations(player_index)
  translation.add_requests(player_index, constants.gui_strings)
  translation.add_requests(player_index, global.strings)
end

function player_data.validate_favorites(favorites)
  local recipe_book = global.recipe_book
  local i = 1
  while true do
    local obj = favorites[i]
    if obj then
      if recipe_book[obj.class] and recipe_book[obj.class][obj.name] then
        i = i + 1
      else
        table.remove(favorites, i)
        favorites[obj.class.."."..obj.name] = nil
      end
    else
      break
    end
  end
end

function player_data.refresh(player, player_table)
  -- destroy GUIs
  info_gui.destroy_all(player_table)
  quick_ref_gui.destroy_all(player_table)

  -- set flag
  player_table.flags.can_open_gui = false

  -- set shortcut state
  player.set_shortcut_toggled("rb-toggle-gui", false)
  player.set_shortcut_available("rb-toggle-gui", false)

  -- validate favorites
  player_data.validate_favorites(player_table.favorites)

  -- destroy global history
  -- TODO: Validate instead of destroy
  -- TODO: Implement global history
  player_table.global_history = {}

  -- update settings
  player_data.update_settings(player, player_table)

  -- run translations
  player_table.translations = table.deep_copy(constants.empty_translations_table)
  if player.connected then
    player_data.start_translations(player.index)
  else
    player_table.flags.translate_on_join = true
  end
end

function player_data.remove(player_index)
  global.players[player_index] = nil
end

function player_data.check_cursor_stack(player)
    local cursor_stack = player.cursor_stack
    if
      cursor_stack
      and cursor_stack.valid
      and cursor_stack.valid_for_read
      and global.recipe_book.item[cursor_stack.name]
    then
      return cursor_stack.name
    end
    return false
end

return player_data
