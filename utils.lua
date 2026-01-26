-- just general utility functions that are handy when i make me codees

gCynixStates = {}
function reset_cynix_states(index)
    if index == nil then index = 0 end
    gCynixStates[index] = {
        index = network_global_index_from_local(0),
        actionTick = 0,
        prevFrameAction = 0,
        spinCooldown = 0,
        canSpin = true,

        gfxAngleX = 0,
        gfxAngleY = 0,
        gfxAngleZ = 0,
    }
end

for i = 0, (MAX_PLAYERS - 1) do
    reset_cynix_states(i)
end

c = gMarioStates[0] -- c for Cynix

function convert_s16(num)
    local min = -32768
    local max = 32767
    while (num < min) do
        num = max + (num - min)
    end
    while (num > max) do
        num = min + (num - max)
    end
    return num
end

-- iunno if this is the same as convert_s16... :<
function s16(x)
    x = (math.floor(x) & 0xFFFF)
    if x >= 32768 then return x - 65536 end
    return x
end

function spawn_particle(m, particle)
    m.particleFlags = m.particleFlags | particle
end

-- controller button variables for simplicity :3
function init_buttons()
    buttonP = c.controller.buttonPressed
    buttonD = c.controller.buttonDown

    buttonApress = c.controller.buttonPressed & A_BUTTON ~= 0
    buttonBpress = c.controller.buttonPressed & B_BUTTON ~= 0
end

isGrounded = c.action & ACT_FLAG_AIR == 0

function get_current_speed(m)
    return math.sqrt((m.vel.x * m.vel.x) + (m.vel.z * m.vel.z))
end


function init_locals(m)
    init_buttons()
    e = gCynixStates[m.playerIndex]
end