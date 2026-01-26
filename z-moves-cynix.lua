if not _G.charSelectExists then return end


ACT_CYN_SPIN = allocate_mario_action(ACT_FLAG_ATTACKING | ACT_FLAG_MOVING | ACT_FLAG_INVULNERABLE)
ACT_CYN_SPIN_AIR = allocate_mario_action(ACT_FLAG_ATTACKING | ACT_FLAG_AIR | ACT_GROUP_AIRBORNE | ACT_FLAG_INVULNERABLE | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_MOVING)
ACT_CYN_DIVE = allocate_mario_action(ACT_FLAG_AIR | ACT_FLAG_MOVING | ACT_GROUP_AIRBORNE)
ACT_CYN_ROLL = allocate_mario_action(ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
ACT_CYN_RUN = allocate_mario_action(ACT_FLAG_MOVING | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_GROUP_MOVING)

local function act_cyn_spin(m)
    init_locals(m)

    if m.actionTimer == 0 then
        m.faceAngle.y = m.intendedYaw
        play_character_sound(m, CHAR_SOUND_HOOHOO)
        spawn_particle(m, PARTICLE_SPARKLES)
        set_mario_animation(m, CHAR_ANIM_TWIRL)
        e.spinCooldown = 15
    end

    local stepResult = perform_ground_step(m)


    e.canSpin = false

    e.gfxAngleY = e.gfxAngleY + 0x2800
    m.marioObj.header.gfx.angle.y = e.gfxAngleY

    m.actionTimer = m.actionTimer + 1

    if m.actionTimer > 10 then
        set_mario_action(m, ACT_IDLE, 0)
        return
    end
end
hook_mario_action(ACT_CYN_SPIN, { every_frame = act_cyn_spin, gravity = nil })

local function act_cyn_spin_air(m)
    init_locals(m)

    if m.actionTimer == 0 then
        mario_set_forward_vel(m, e.lastSpeed)
        
        m.vel.y = 15
        play_character_sound(m, CHAR_SOUND_YAHOO)
        spawn_particle(m, PARTICLE_SPARKLES)
        e.spinCooldown = 20
    end

    common_air_action_step(m, ACT_FREEFALL_LAND, CHAR_ANIM_TWIRL, AIR_STEP_NONE)

    m.faceAngle.y = m.faceAngle.y

    e.canSpin = false

    e.gfxAngleY = e.gfxAngleY + 0x2800
    m.marioObj.header.gfx.angle.y = e.gfxAngleY

    m.actionTimer = m.actionTimer + 1

    if m.actionTimer > 15 then
        set_mario_action(m, ACT_FREEFALL, 0)
        return
    end
end
hook_mario_action(ACT_CYN_SPIN_AIR, { every_frame = act_cyn_spin_air, gravity = nil })

local function do_spin_air_if(m)
    init_locals(m)

    if buttonP & X_BUTTON ~= 0 and e.canSpin and e.spinCooldown == 0 and not isGrounded then 
        set_mario_action(m, ACT_CYN_SPIN_AIR, 0)
    end
end

local function do_spin_ground_if(m)
    init_locals(m)

    if buttonP & X_BUTTON ~= 0 and e.canSpin and e.spinCooldown == 0 and isGrounded then 
        set_mario_action(m, ACT_CYN_SPIN, 0)
    end
end

local function update_cynix(m)
    init_locals(m)

    -- Global Action Timer 
    e.actionTick = e.actionTick + 1
    if e.prevFrameAction ~= m.action then
        e.prevFrameAction = m.action
        e.actionTick = 0
    end

    e.lastSpeed = get_current_speed(m)

    -- spin cooldown thing
    if e.spinCooldown > 0 then
        e.spinCooldown = e.spinCooldown - 1
    end

    if isGrounded and (m.action ~= ACT_CYN_SPIN or (m.action ~= ACT_CYN_SPIN_AIR or m.action ~= ACT_FREEFALL)) then
        e.canSpin = true
    end
    djui_chat_message_create("Spin:" .. tostring(e.canSpin) .. " Cooldown:" .. tostring(e.spinCooldown))

    do_spin_air_if(m)
    do_spin_ground_if(m)

end

_G.charSelect.character_hook_moveset(CHAR_CYNIX, HOOK_MARIO_UPDATE, update_cynix)
