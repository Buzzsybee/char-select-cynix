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

    m.faceAngle.y = m.intendedYaw - approach_s32(intendedYawbutcoolig, 0, 0x1000, 0x1000)

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

    m.faceAngle.y = m.intendedYaw - approach_s32(intendedYawbutcoolig, 0, 0x1000, 0x1000)

    apply_slope_accel(m);
end


function open_doors_check(m)
  
    local dist = 150
    local doorwarp = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvDoorWarp)
    local door = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvDoor)
    local stardoor = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvStarDoor)
    local shell = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvKoopaShell)
    
    if m.action == ACT_WALKING or m.action == ACT_HOLD_WALKING then
        if
        ((doorwarp ~= nil and dist_between_objects(m.marioObj, doorwarp) > dist) or
        (door ~= nil and dist_between_objects(m.marioObj, door) > dist) or
        (stardoor ~= nil and dist_between_objects(m.marioObj, stardoor) > dist) or (dist_between_objects(m.marioObj, shell) > dist and shell ~= nil) and m.heldObj == nil)
        then
            return set_mario_action(m, ACT_CYN_RUN, 0)
        elseif doorwarp == nil and door == nil and stardoor == nil and shell == nil then
            return set_mario_action(m, ACT_CYN_RUN, 0)
        end
    end
    
    if m.action == ACT_CYN_RUN then
        if
        (dist_between_objects(m.marioObj, doorwarp) < dist and doorwarp ~= nil) or
        (dist_between_objects(m.marioObj, door) < dist and door ~= nil) or
        (dist_between_objects(m.marioObj, stardoor) < dist and stardoor ~= nil) or (dist_between_objects(m.marioObj, shell) < dist and shell ~= nil)
        then
          if m.heldObj == nil then
            return set_mario_action(m, ACT_WALKING, 0)
            else
              return set_mario_action(m, ACT_HOLD_WALKING, 0)
          end
        
        end
    end
end