if not _G.charSelectExists then return end

ACT_CYN_RUN = allocate_mario_action(ACT_FLAG_MOVING | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_GROUP_MOVING)
ACT_CYN_SPIN = allocate_mario_action(ACT_FLAG_ATTACKING | ACT_FLAG_MOVING | ACT_FLAG_INVULNERABLE)
ACT_CYN_SPIN_AIR = allocate_mario_action(ACT_FLAG_ATTACKING | ACT_FLAG_AIR | ACT_GROUP_AIRBORNE | ACT_FLAG_INVULNERABLE | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_MOVING)
ACT_CYN_DIVE = allocate_mario_action(ACT_FLAG_AIR | ACT_FLAG_MOVING | ACT_GROUP_AIRBORNE)
ACT_CYN_ROLL = allocate_mario_action(ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
ACT_CYN_ROLL_FALL = allocate_mario_action(ACT_FLAG_AIR | ACT_FLAG_MOVING | ACT_GROUP_AIRBORNE)
ACT_CYN_RUN = allocate_mario_action(ACT_FLAG_MOVING | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_GROUP_MOVING)

local function act_cyn_run(m)
    local startPos = m.pos;
    local startYaw = m.faceAngle.y;

    mario_drop_held_object(m);

    if (m.input & INPUT_A_PRESSED ~= 0) then
        return set_jump_from_landing(m);
    end

    if (check_ground_dive_or_punch(m) ~= 0) then
        return 1;
    end

    if (m.input & INPUT_ZERO_MOVEMENT ~= 0) then
        return begin_braking_action(m);
    end
    
    if (analog_stick_held_back(m) ~= 0 and m.forwardVel >= 16.0) then
        return set_mario_action(m, ACT_TURNING_AROUND, 0);
    end

    if (m.input & INPUT_Z_PRESSED ~= 0) then
        return set_mario_action(m, ACT_CROUCH_SLIDE, 0);
    end
    m.actionState = 0;

    vec3f_copy(startPos, m.pos);
    update_cyn_run_speed(m);
    open_doors_check(m);
    

    local stepResult = perform_ground_step(m)
    if (stepResult == GROUND_STEP_LEFT_GROUND) then
        set_mario_action(m, ACT_FREEFALL, 0);
        set_character_animation(m, CHAR_ANIM_GENERAL_FALL);    
    elseif (stepResult == GROUND_STEP_NONE) then
        anim_and_audio_for_walk(m);
        if ((m.intendedMag - m.forwardVel) > 16.0) then
            set_mario_particle_flags(m, PARTICLE_DUST, false);
        end
    elseif (stepResult == GROUND_STEP_HIT_WALL) then
        push_or_sidle_wall(m, startPos);
        m.actionTimer = 0;
    end

    if m.forwardVel > 40 then
        spawn_particle(m, PARTICLE_DUST)
        tilt_body_walking(m, startYaw);
    else
        m.marioBodyState.torsoAngle.x = 0
        m.marioBodyState.torsoAngle.z = 0
    end
    m.marioBodyState.allowPartRotation = 1
    return 0;
end
hook_mario_action(ACT_CYN_RUN, { every_frame = act_cyn_run, gravity = nil } )

local function act_cyn_spin(m)
    init_locals(m)

    if m.actionTimer == 0 then
        m.faceAngle.y = m.intendedYaw
        play_character_sound(m, CHAR_SOUND_HOOHOO)
        
        set_mario_animation(m, CHAR_ANIM_TWIRL)
        e.spinCooldown = 15
    end

    local stepResult = perform_ground_step(m)
    if (stepResult == GROUND_STEP_LEFT_GROUND) then
        set_mario_action(m, ACT_FREEFALL, 0);
        set_character_animation(m, CHAR_ANIM_GENERAL_FALL);
    end


    e.canSpin = false
    spawn_particle(m, PARTICLE_SPARKLES)

    e.gfxAngleY = e.gfxAngleY + 0x2800
    m.marioObj.header.gfx.angle.y = e.gfxAngleY

    m.actionTimer = m.actionTimer + 1

    if m.actionTimer > 10 then
        set_mario_action(m, ACT_IDLE, 0)
        return
    end

    if buttonApress then
        set_jump_from_landing(m)
    end
end
hook_mario_action(ACT_CYN_SPIN, { every_frame = act_cyn_spin, gravity = nil }, INT_KICK)

local function act_cyn_spin_air(m)
    init_locals(m)

    if m.actionTimer == 0 then
        mario_set_forward_vel(m, e.lastSpeed)
        m.vel.y = 40
        play_character_sound(m, CHAR_SOUND_YAHOO)
    end

    common_air_action_step(m, ACT_FREEFALL_LAND, CHAR_ANIM_TWIRL, AIR_STEP_NONE)

    make_actionable_air(m)

    m.faceAngle.y = m.faceAngle.y

    e.canSpin = false

    e.gfxAngleY = e.gfxAngleY + 0x2900
    m.marioObj.header.gfx.angle.y = e.gfxAngleY

    m.actionTimer = m.actionTimer + 1

    if m.actionTimer < 10 then
        spawn_particle(m, PARTICLE_SPARKLES)
    end
end
hook_mario_action(ACT_CYN_SPIN_AIR, { every_frame = act_cyn_spin_air })

local function act_cyn_roll(m)
    init_locals(m)

    if e.actionTick == 0 then
        mario_set_forward_vel(m, e.lastSpeed + 10)
        set_mario_animation(m, CHAR_ANIM_FORWARD_SPINNING)
        e.rollEndTimer = 5
    end


    local stepResult = perform_ground_step(m)
    if (stepResult == GROUND_STEP_LEFT_GROUND) then
        set_mario_action(m, ACT_CYN_ROLL_FALL, 0);
    end

    mario_set_forward_vel(m, e.lastSpeed)
    spawn_particle(m, PARTICLE_DUST)
    update_cyn_roll_speed(m)

    if m.forwardVel <= 29 then
        e.rollEndTimer = e.rollEndTimer - 1
    else
        e.rollEndTimer = 5
    end

    if not buttonZdown then
        e.rollEndTimer = 0
    end

    if e.rollEndTimer <= 0 then
        if mag < 1 then
        set_mario_action(m, ACT_BRAKING, 0)
        return
        end
        set_mario_action(m, ACT_CYN_RUN, 0)
    end

    set_backflip_or_long_jump(m)
    
    m.actionTimer = m.actionTimer + 1
end
hook_mario_action(ACT_CYN_ROLL, { every_frame = act_cyn_roll, gravity = nil })

local function act_cyn_roll_fall(m)
    init_locals(m)

    if m.actionTimer == 0 then
        set_mario_animation(m, CHAR_ANIM_FORWARD_SPINNING)
    end

    common_air_action_step(m, ACT_CYN_ROLL, CHAR_ANIM_FORWARD_SPINNING, AIR_STEP_NONE)

    if not buttonZdown then
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    m.actionTimer = m.actionTimer + 1
end
hook_mario_action(ACT_CYN_ROLL_FALL, { every_frame = act_cyn_roll_fall })

local function act_cyn_dive(m)
    init_locals(m)

    if m.actionTimer == 0 then
        play_character_sound(m, CHAR_SOUND_HOOHOO)
        m.faceAngle.y = m.intendedYaw
    end

    m.vel.y = -80
    m.forwardVel = 80

    common_air_action_step(m, ACT_CYN_ROLL, CHAR_ANIM_SLIDE_DIVE, AIR_STEP_NONE)


    m.marioObj.header.gfx.angle.x = m.marioObj.header.gfx.angle.x + 0x2048


    m.actionTimer = m.actionTimer + 1

    if m.actionTimer < 10 then
        spawn_particle(m, PARTICLE_SPARKLES)
    end
end
hook_mario_action(ACT_CYN_DIVE, { every_frame = act_cyn_dive })

local function do_spin_air_if(m)
    init_locals(m)

    if buttonXpress and e.canSpin and e.spinCooldown == 0 then 
        if not is_grounded(m) then
            if e.actionTick > 0 then
                set_mario_action(m, ACT_CYN_SPIN_AIR, 0)
            end
        end
    end
end

local function do_spin_ground_if(m)
    init_locals(m)

    if buttonXpress and e.canSpin and e.spinCooldown == 0 then 
        set_mario_action(m, ACT_CYN_SPIN, 0)
    end
end

local function do_dive_if(m)
    init_locals(m)

    if e.actionTick > 0 and m.action ~= ACT_CYN_DIVE  then
        if buttonZpress then
            set_mario_action(m, ACT_CYN_DIVE, 0)
        end
    end
end

local function before_action_cynix(m)
    init_locals(m)


    if m.action == ACT_CYN_ROLL then
        if e.actionTick == 0 then
            mario_set_forward_vel(m, e.lastSpeed + m.vel.y)
        end
    end

    if m.action == ACT_WALKING then
        set_mario_action(m, ACT_CYN_RUN, 0)
    end

    prevFrameSpeed = e.lastSpeed

end

local function update_cynix(m)
    init_locals(m)

    local stickMag = m.controller.stickMag

    --djui_chat_message_create("mag: " .. tostring(stickMag))


    m.peakHeight = m.pos.y

    -- Global Action Timer 
    e.actionTick = e.actionTick + 1
    if e.prevFrameAction ~= m.action then
        e.prevFrameAction = m.action
        e.actionTick = 0
    end

    e.lastSpeed = get_current_speed(m)
    local isGrounded = is_grounded(m)
    --djui_chat_message_create("isGrounded: " .. tostring(isGrounded))

    -- spin cooldown thing
    if e.spinCooldown > 0 then
        e.spinCooldown = e.spinCooldown - 1
    end

    if m.action == ACT_WALL_KICK_AIR then 
        e.canSpin = true
    end

    if isGrounded and (m.action ~= ACT_CYN_SPIN or (m.action ~= ACT_CYN_SPIN_AIR)) then
        e.canSpin = true

        do_spin_ground_if(m)
    end

    if not isGrounded then
        do_spin_air_if(m)
        do_dive_if(m)
    end

    if m.action == ACT_BACKFLIP then
        if e.actionTick == 0 then
            m.vel.y = m.vel.y + 10
        end
    end
    if m.action == ACT_LONG_JUMP then
        if e.actionTick == 0 then
            m.forwardVel = m.forwardVel + 10
        end
    end

    if m.action == ACT_LONG_JUMP_LAND then
        if buttonZdown then
            set_mario_action(m, ACT_CYN_ROLL, 0)
        end
    end


    if m.action == ACT_DIVE then
        do_dive_if(m)
    end

end

_G.charSelect.character_hook_moveset(CHAR_CYNIX, HOOK_BEFORE_MARIO_UPDATE, before_action_cynix)
_G.charSelect.character_hook_moveset(CHAR_CYNIX, HOOK_MARIO_UPDATE, update_cynix)
