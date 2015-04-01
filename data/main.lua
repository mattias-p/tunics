local zentropy = require 'lib/zentropy'
local util = require 'lib/util'
local Pause = require 'menus/pause'

local dialog_box = require 'menus/dialog_box'

zentropy.init()

util.wdebug_truncate()

function sol.main:on_started()
    sol.language.set_language("en")

    local old_game = sol.game.load("zentropy1.dat")
    local old_values = {}
    for _, name in pairs{'seed', 'tier', 'override_tileset', 'override_keys', 'override_fairies', 'override_culdesacs'} do
        old_values[name] = old_game:get_value(name)
    end
    old_values.seed = old_values.seed or 1
    old_values.tier = old_values.tier or 1

    sol.game.delete("zentropy1.dat")
    local game = sol.game.load("zentropy1.dat")
    game:set_ability("sword", 1)
    game:set_max_life(12)
    game:set_life(12)
    game:set_value('small_key_amount', 0)

    for name, value in pairs(old_values) do
        game:set_value(name, value)
    end

    game:save()

    require('lib/map_include.lua')
    sol.main.load_file("hud/hud")(game)

    game:set_starting_location('dungeons/dungeon1')

    game.dialog_box = dialog_box:new{game=game}

    local pause = Pause:new{game=game}

    function game:on_command_pressed(command)
        if command == 'pause' and game:is_paused() then
            game:save()
            print("saved")
        end
    end

    function game:on_paused()
        pause:start_pause_menu()
        self:hud_on_paused()
    end

    function game:on_unpaused()
        pause:stop_pause_menu()
        self:hud_on_unpaused()
    end
    
    function game:on_started()
        game:get_hero():set_walking_speed(160)
        self.dialog_box:initialize_dialog_box()
        self:initialize_hud()
    end

    -- Called by the engine when a dialog starts.
    function game:on_dialog_started(dialog, info)

        self.dialog_box.dialog = dialog
        self.dialog_box.info = info
        sol.menu.start(self, self.dialog_box)
    end

    -- Called by the engine when a dialog finishes.
    function game:on_dialog_finished(dialog)

        sol.menu.stop(self.dialog_box)
        self.dialog_box.dialog = nil
        self.dialog_box.info = nil
    end

    function game:on_finished()
        self:quit_hud()
        self.dialog_box:quit_dialog_box()
    end

    function game:on_map_changed(map)
        self:hud_on_map_changed(map)
    end

    game:start()
end
