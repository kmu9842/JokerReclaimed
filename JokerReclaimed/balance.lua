-- All economy and test values live here. Restart Balatro after editing.
return {
    rarities = {
        [1] = { scraps = 1,  price = 10 },  -- Common / 일반
        [2] = { scraps = 3,  price = 30 },  -- Uncommon / 희귀
        [3] = { scraps = 7,  price = 60 },  -- Rare / 레어
        [4] = { scraps = 20, price = 100, dollars = 10 }, -- Legendary
    },
    -- Register custom rarity keys here; otherwise use the Rare tier.
    custom_rarities = {},
    fallback_rarity = 3,
    editions = {
        none = 0, foil = 5, holo = 10, polychrome = 20, negative = 50,
    },
    -- REPLACE the dollar price only. Highest selected override wins.
    -- Rental + perishable = $1; rental + eternal = $2.
    sticker_dollars = { rental = 1, perishable = 1, eternal = 2 },
    page_size = 8,
    cheats = { scraps = 1000, dollars = 100, key = 'f8', shop_key = 'f7' },
    wallet_directory = 'joker_reclaimed',
}
