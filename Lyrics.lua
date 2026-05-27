-- Word-by-word lyrics with timing extracted from the original WeakAura (wago.io/ihJP5eZK2)
-- colorAt = absolute time (seconds) when this word turns yellow
-- yellAt = absolute time when the full line is yelled in chat

local _, ns = ...

ns.LYRICS = {
    {
        text = "Dolly and Dot are my best friends!",
        yellAt = 0.5,
        startTime = 0.0,
        endTime = 2.8,
        words = {
            { text = "Dolly",    colorAt = 0.5 },
            { text = "and",      colorAt = 0.9 },
            { text = "Dot",      colorAt = 1.2 },
            { text = "are",      colorAt = 1.6 },
            { text = "my",       colorAt = 1.9 },
            { text = "best",     colorAt = 2.1 },
            { text = "friends!", colorAt = 2.5 },
        },
    },
    {
        text = "They pull my wagon through dunes of sand!",
        yellAt = 3.1,
        startTime = 2.8,
        endTime = 5.45,
        words = {
            { text = "They",    colorAt = 3.1 },
            { text = "pull",    colorAt = 3.25 },
            { text = "my",      colorAt = 3.6 },
            { text = "wagon",   colorAt = 3.9 },
            { text = "through", colorAt = 4.3 },
            { text = "dunes",   colorAt = 4.6 },
            { text = "of",      colorAt = 4.95 },
            { text = "sand!",   colorAt = 5.15 },
        },
    },
    {
        text = "They have small teeth and they love to eat!",
        yellAt = 5.75,
        startTime = 5.45,
        endTime = 8.28,
        words = {
            { text = "They",  colorAt = 5.75 },
            { text = "have",  colorAt = 6.1 },
            { text = "small", colorAt = 6.4 },
            { text = "teeth", colorAt = 6.55 },
            { text = "and",   colorAt = 6.9 },
            { text = "they",  colorAt = 7.2 },
            { text = "love",  colorAt = 7.4 },
            { text = "to",    colorAt = 7.8 },
            { text = "eat!",  colorAt = 7.9 },
        },
    },
    {
        text = "They're the best 'pacas in all the laaaand!",
        yellAt = 8.65,
        startTime = 8.28,
        endTime = 11.5,
        words = {
            { text = "They're",  colorAt = 8.65 },
            { text = "the",      colorAt = 8.92 },
            { text = "best",     colorAt = 9.05 },
            { text = "'pacas",   colorAt = 9.35 },
            { text = "in",       colorAt = 9.75 },
            { text = "all",      colorAt = 10.10 },
            { text = "the",      colorAt = 10.4 },
            { text = "laaaand!", colorAt = 10.65 },
        },
    },
}