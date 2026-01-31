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
        canDive = true,
        rollEndTimer = 0,
        lastSpeed = 0,

        gfxAngleX = 0,
        gfxAngleY = 0,
        gfxAngleZ = 0,
    }
end

for i = 0, (MAX_PLAYERS - 1) do
    reset_cynix_states(i)
end

c = gMarioStates[0] -- c for Cynix

jumpActs = {
    ACT_JUMP,
    ACT_DOUBLE_JUMP,
    ACT_TRIPLE_JUMP,
    ACT_BACKFLIP,
    ACT_SIDE_FLIP,
    ACT_LONG_JUMP,
    ACT_WALL_KICK_AIR,
    ACT_JUMP_KICK,
    ACT_FREEFALL,
    ACT_WATER_JUMP,
    ACT_DIVE,
    ACT_STEEP_JUMP,
    ACT_FORWARD_ROLLOUT,
    ACT_BACKWARD_ROLLOUT,
    ACT_TOP_OF_POLE_JUMP,
    ACT_GROUND_POUND,
    ACT_SPAWN_SPIN_AIRBORNE,
    ACT_SPAWN_NO_SPIN_AIRBORNE,
}
jumpAct = {}
for _, v in ipairs(jumpActs) do
    jumpAct[v] = true
end

excludeGroundSpinActs = {
    ACT_GROUND_BONK,
    ACT_BACKWARD_GROUND_KB,
    ACT_FORWARD_GROUND_KB,
    ACT_SOFT_BACKWARD_GROUND_KB,
    ACT_SOFT_FORWARD_GROUND_KB,
    ACT_STAR_DANCE_EXIT,
    ACT_STAR_DANCE_NO_EXIT,
    ACT_CREDITS_CUTSCENE,
    ACT_BUTT_STUCK_IN_GROUND,
    ACT_HOLD_BEGIN_SLIDING,
    ACT_HOLD_HEAVY_IDLE,
    ACT_UNLOCKING_STAR_DOOR,
    ACT_READING_SIGN,
    ACT_READING_NPC_DIALOG,
    ACT_PULLING_DOOR,
    ACT_PUTTING_ON_CAP,
    ACT_PUSHING_DOOR,
    ACT_HOLDING_BOWSER,
    ACT_HOLD_HEAVY_WALKING,
    ACT_HOLD_IDLE,
    ACT_HOLD_STOMACH_SLIDE,
    ACT_HOLD_WALKING,
    ACT_DIVE_SLIDE,
    ACT_DIVE_PICKING_UP,
    ACT_BUTT_SLIDE,
    ACT_STOMACH_SLIDE,
    ACT_UNLOCKING_KEY_DOOR,
    ACT_RIDING_SHELL_GROUND,
    ACT_READING_AUTOMATIC_DIALOG,
    ACT_EXIT_LAND_SAVE_DIALOG,
    ACT_DEATH_EXIT,
    ACT_DEATH_EXIT_LAND,
    ACT_DISAPPEARED,
    ACT_TELEPORT_FADE_IN,
    ACT_TELEPORT_FADE_OUT,
}
excludeGroundSpinAct = {}
for _, v in ipairs(excludeGroundSpinActs) do
    excludeGroundSpinAct[v] = true
end


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
    buttonXpress = c.controller.buttonPressed & X_BUTTON ~= 0
    buttonYpress = c.controller.buttonPressed & Y_BUTTON ~= 0
    buttonZpress = c.controller.buttonPressed & Z_TRIG ~= 0
    buttonAdown = c.controller.buttonDown & A_BUTTON ~= 0
    buttonBdown = c.controller.buttonDown & B_BUTTON ~= 0
    buttonXdown = c.controller.buttonDown & X_BUTTON ~= 0
    buttonYdown = c.controller.buttonDown & Y_BUTTON ~= 0
    buttonZdown = c.controller.buttonDown & Z_TRIG ~= 0
end

-- using this to simplify an action midair that should let you ground pound or any other stuff
-- this should also have the air spin and whatnot but ill fugure that out later
function make_actionable_air(m)

    if e.actionTick > 0 then
        if buttonZpress then
            set_mario_action(m, ACT_CYN_DIVE, 0) --will maybe replace with dive X3
        end

        if buttonBpress then
            c.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_JUMP_KICK, 0)
        end
    end
end

-- i copied this from honiOM, no idea how it works fr, let me burn
function apply_traction_friction(m, normalSpeed, tractionFactor)
    init_locals(m)
    local normalSpeed = normalSpeed or 34
    local stickMag = m.controller.stickMag

    local traction = tractionFactor or 0.03

    if stickMag > 25 then
        traction = traction * 0.25
    end

    if (m.floor ~= nil and (m.forwardVel > normalSpeed)) then
        local delta = m.forwardVel - normalSpeed
        if delta > 0.01 then
            m.forwardVel = m.forwardVel - (delta * traction)
            if m.forwardVel < normalSpeed then m.forwardVel = normalSpeed end
        else
            m.forwardVel = normalSpeed
        end
        return
    end
end

function is_grounded(m)
    if m.floorHeight == m.pos.y then
        return true
    end
    return false
end

function get_current_speed(m)
    return math.sqrt((m.vel.x * m.vel.x) + (m.vel.z * m.vel.z))
end


function init_locals(m)
    init_buttons()
    e = gCynixStates[m.playerIndex]
    mag = m.controller.stickMag / 64
    intendedYawbutcoolig = s16(m.intendedYaw - m.faceAngle.y)
    action = c.action 
end

function set_backflip_or_long_jump(m)
    init_locals(m)
    
    if mag < 1 and e.actionTick < 3 then
        if buttonApress then
            set_mario_action(m, ACT_BACKFLIP, 0)
        end
    end
    if mag > 0 then
        if buttonApress then
            set_mario_action(m, ACT_LONG_JUMP, 0)
        end
    end
end

function reset_rotation(m, nextAct, actionArg)
    m.marioBodyState.allowPartRotation = 0
end
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, reset_rotation)

function reset_pitch(m)
    if m.action == ACT_CYN_RUN then
        m.marioObj.oMarioWalkingPitch = 0
    end
end
hook_event(HOOK_ON_SET_MARIO_ACTION, reset_pitch)

function set_turn_speed(speed)
    c.faceAngle.y = c.intendedYaw - approach_s32(intendedYawbutcoolig, 0, speed, speed)
end

function update_cyn_run_speed(m)
    init_locals(m)
    local maxTargetSpeed = 0.0;
    local targetSpeed = 0.0;
    apply_traction_friction(m, 34, 0.07);
    if (m.floor ~= nil and m.floor.type == SURFACE_SLOW) then
        maxTargetSpeed = e.lastSpeed;
    else
        maxTargetSpeed = 34 or e.lastSpeed;
    end

    if (m.intendedMag < maxTargetSpeed) then
        targetSpeed = m.intendedMag + 2.1;
    else
        targetSpeed = maxTargetSpeed
    end

    if (m.forwardVel <= 0.0) then
        m.forwardVel = m.forwardVel + 5.1;
    elseif (m.forwardVel <= targetSpeed) then
        m.forwardVel = m.forwardVel + 5.1;
    end

    set_turn_speed(0x1000);

    apply_slope_accel(m);
end

function update_cyn_roll_speed(m)
    init_locals(m)
    local maxTargetSpeed = 0.0;
    local targetSpeed = 0.0;
    if e.actionTick > 10 then
        apply_traction_friction(m, 10, 0.1);
    end
    if (m.floor ~= nil and m.floor.type == SURFACE_SLOW) then
        maxTargetSpeed = e.lastSpeed;
    else
        maxTargetSpeed = e.lastSpeed;
    end

    if (m.intendedMag < maxTargetSpeed) then
        targetSpeed = m.intendedMag + 2.1;
    else
        targetSpeed = maxTargetSpeed
    end

    if (m.forwardVel <= 0.0) then
        m.forwardVel = m.forwardVel + 2.1;
    elseif (m.forwardVel <= targetSpeed) then
        m.forwardVel = m.forwardVel + 2.1;
    end

    set_turn_speed(0x1000);

    apply_slope_accel(m);
end

--from baconators lua recreation of act walkinggg
function fix_interactions(m, obj, interactType)
    if (m.action == ACT_CYN_RUN) then
        if (interactType == INTERACT_WARP_DOOR) then
            m.action = ACT_WALKING
            local interaction = interact_warp_door(m, INTERACT_WARP_DOOR, obj)
            if (interaction == 0) then
                m.action = ACT_CYN_RUN
            end
        end
        if (interactType == INTERACT_DOOR) then
            m.action = ACT_WALKING
            local interaction = interact_door(m, INTERACT_DOOR, obj)
            if (interaction == 0) then
                m.action = ACT_CYN_RUN
            end
        end
        if (interactType == INTERACT_KOOPA_SHELL) then
            m.action = ACT_WALKING
            local interaction = interact_koopa_shell(m, INTERACT_KOOPA_SHELL, obj)
            if (interaction == 0) then
                m.action = ACT_CYN_RUN
            end
        end
    end
end

hook_event(HOOK_ALLOW_INTERACT, fix_interactions)