local J = JRC
local draw_card = Card.draw

-- The native perspective shader displaces even an idle card with zero ambient tilt.
-- Keep menu previews and the tear's clipping edges in their measured screen bounds.
SMODS.DrawStep{
    key = 'flat_preview', order = -49,
    func = function(card)
        if card.jrc_preview_key or card.jrc_rip then card.hover_tilt = 0 end
    end,
}

-- Clip the actual card art into two jagged paper edges, retaining its edition shader.
-- No replacement Joker art, gameplay RNG calls, or additional asset dependencies.
function Card:draw(layer)
    if not self.jrc_rip or G.SETTINGS.reduced_motion then return draw_card(self, layer) end
    local progress = math.min(1, (G.TIMERS.REAL - self.jrc_rip) / 0.7)
    local spread = (1 - (1 - progress)^3) * self.VT.w * 0.23
    local px = G.TILESIZE * G.TILESCALE
    local sx, sy, sw, sh = love.graphics.getScissor()
    local function clip(x, y, w, h)
        local x1, y1 = love.graphics.transformPoint(x * px, y * px)
        local x2, y2 = love.graphics.transformPoint((x + w) * px, (y + h) * px)
        x1, y1, x2, y2 = math.floor(x1), math.floor(y1), math.ceil(x2), math.ceil(y2)
        if sx then
            x1, y1, x2, y2 = math.max(x1, sx), math.max(y1, sy), math.min(x2, sx + sw), math.min(y2, sy + sh)
        end
        love.graphics.setScissor(x1, y1, math.max(0, x2 - x1), math.max(0, y2 - y1))
    end
    self.VT.r, self.VT.scale = 0, 1
    self.states.hover.is, self.states.focus.is, self.ambient_tilt = false, false, 0
    local bands = 8
    for _, side in ipairs({-1, 1}) do
        love.graphics.push()
        love.graphics.translate(side * spread * px, progress * progress * 0.24 * self.VT.h * px)
        for band = 0, bands - 1 do
            local cut = self.VT.w * (band % 2 == 0 and 0.45 or 0.55)
            local x = self.VT.x + (side == 1 and cut or 0)
            local width = side == 1 and self.VT.w - cut or cut
            clip(x, self.VT.y + band * self.VT.h / bands, width, self.VT.h / bands)
            draw_card(self, layer)
        end
        love.graphics.pop()
    end
    if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end
end

function J.play_tear(card, amount)
    card.jrc_rip = G.TIMERS.REAL
    card.states.click.can, card.states.drag.can, card.states.hover.can = false, false, false
    card.T.r, card.VT.r = 0, 0
    play_sound('crumple1', 0.95, 0.65)
    local pieces = Particles(card.T.x + card.T.w * 0.5, card.T.y + card.T.h * 0.5, 0, 0, {
        timer_type = 'REAL', timer = 0.012, scale = 0.16, speed = 1.8,
        lifespan = 0.55, max = 18, pulse_max = 12, colours = {G.C.WHITE, G.C.JOKER_GREY, G.C.GOLD},
    })
    G.E_MANAGER:add_event(Event{trigger = 'after', delay = 0.2, timer = 'REAL',
        blocking = false, blockable = false, func = function()
        if not card.removed then
            play_sound('crumple3', 1.15, 0.4)
            card:start_dissolve({G.C.WHITE, G.C.JOKER_GREY, G.C.GOLD}, true,
                0.75 * (G.SPEEDFACTOR or 1), true)
            card_eval_status_text(card, 'extra', nil, nil, nil,
                {message = J.text('gain', {amount}), colour = G.C.GOLD, instant = true})
        end
        pieces:fade(0.4)
        return true
    end})
    G.E_MANAGER:add_event(Event{trigger = 'after', delay = 0.9, timer = 'REAL',
        blocking = false, blockable = false, func = function() pieces:remove(); return true end})
end
