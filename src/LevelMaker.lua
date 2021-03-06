--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    local keyGenerated = false

    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY

        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        screen = SCREEN_TILE_WIDTH
        -- chance to just be emptiness
        if math.random(7) == 1 then
            --reserved for lock block
            if x >= (width - screen - 1 + screen/2) and x <= (width - screen + 1 + screen/2) then
                for y = 7, height do
                    table.insert(tiles[y],
                        Tile(x, y, TILE_ID_GROUND, y == 7 and topper or nil, tileset, topperset))
                end
                goto continue
            end
            --reserved for flag
            if x >= (width - 3) then
                for y = 7, height do
                    table.insert(tiles[y],
                        Tile(x, y, TILE_ID_GROUND, y == 7 and topper or nil, tileset, topperset))
                end
                goto continue
            end

            --spawn empty
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
            ::continue::
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- ensure 3 normal ground tiles for lock block.
            if x >= (width - screen - 1 + screen/2) and x <= (width - screen + 1 + screen/2) then
                goto continue

            -- last 3 tiles for flag get a normal ground tile.
            elseif x >= (width - 3) then
                goto continue

            -- chance to generate a pillar.
            elseif math.random(8) == 1 then
                blockHeight = 2

                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,

                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end

                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil

            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            elseif keyGenerated == false and math.random(3) == 1 then
                table.insert(objects,
                    -- key
                    GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#KEYS),
                        collidable = true,
                        hit = false,
                        solid = false,
                        consumable = true,

                        -- collision function takes itself
                        onConsume = function(player, object)
                            gSounds['pickup']:play()
                            player.score = player.score + 100
                            print("Player got the key!")

                            -- insert lock block at width - screen
                            table.insert(objects,
                                -- lock block
                                GameObject {
                                    texture = 'keys-and-locks',
                                    x = (width - screen - 1 + screen/2) * TILE_SIZE,
                                    y = (6 - 1) * TILE_SIZE,
                                    width = 16,
                                    height = 16,

                                    -- make it a random variant
                                    frame = math.random(5, 8),
                                    collidable = true,
                                    hit = false,
                                    solid = false,
                                    consumable = true,

                                    onConsume = function(player, object)
                                        -- spawns flagpole
                                        gSounds['powerup-reveal']:play()
                                        table.insert(objects,
                                            GameObject {
                                                texture = 'flagpoles',
                                                x = (width - 2) * TILE_SIZE,
                                                y = (4 - 1) * TILE_SIZE,
                                                width = 16,
                                                height = 64,
                                                frame = math.random(#FLAG_POLES),
                                                collidable = false,
                                                hit = false,
                                                solid = false,
                                                consumable = true,

                                                onConsume = function(player, object)
                                                    print("Hit the flag pole!")
                                                    player.score = player.score + 100
                                                    gStateMachine:change('play', {
                                                        score = player.score,
                                                        width = width + 20
                                                    })
                                                end
                                            }
                                        )
                                        table.insert(objects,
                                            GameObject {
                                                texture = 'flags',
                                                x = (width - 2) * TILE_SIZE + TILE_SIZE/2,
                                                y = (4 - 1) * TILE_SIZE + TILE_SIZE/2,
                                                width = 16,
                                                height = 64,

                                                frame = math.random(#FLAGS)
                                            }
                                        )
                                    end
                                }
                            )
                        end
                    }
                )
                keyGenerated = true
            end

            -- chance to spawn a block
            if math.random(10) == 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }

                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
        ::continue::
    end


    local map = TileMap(width, height)
    map.tiles = tiles

    return GameLevel(entities, objects, map)
end
