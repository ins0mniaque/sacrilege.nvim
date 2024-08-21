local M = { }

local repeats =
{
    a = 2,
    e = 3,
    i = 2,
    o = 3,
    u = 2,
    y = 3,
    A = 2,
    E = 3,
    I = 2,
    O = 3,
    U = 2,
    Y = 3
}

local replacements =
{
    a = 'α',
    b = 'ḅ',
    c = 'ͼ',
    d = 'ḍ',
    e = 'ḛ',
    f = 'ϝ',
    g = 'ḡ',
    h = 'ḥ',
    i = 'ḭ',
    j = 'ĵ',
    k = 'ḳ',
    l = 'ḽ',
    m = 'ṃ',
    n = 'ṇ',
    o = 'ṓ',
    p = 'ṗ',
    q = 'ʠ',
    r = 'ṛ',
    s = 'ṡ',
    t = 'ṭ',
    u = 'ṵ',
    v = 'ṽ',
    w = 'ẁ',
    x = 'ẋ',
    y = 'ẏ',
    z = 'ẓ',
    A = 'Ḁ',
    B = 'Ḃ',
    C = 'Ḉ',
    D = 'Ḍ',
    E = 'Ḛ',
    F = 'Ḟ',
    G = 'Ḡ',
    H = 'Ḥ',
    I = 'Ḭ',
    J = 'Ĵ',
    K = 'Ḱ',
    L = 'Ḻ',
    M = 'Ṁ',
    N = 'Ṅ',
    O = 'Ṏ',
    P = 'Ṕ',
    Q = 'Ǫ',
    R = 'Ṛ',
    S = 'Ṣ',
    T = 'Ṫ',
    U = 'Ṳ',
    V = 'Ṽ',
    W = 'Ŵ',
    X = 'Ẋ',
    Y = 'Ŷ',
    Z = 'Ż'
}

function M.language()
    return "pseudo"
end

function M.localize(text)
    for replace, with in pairs(replacements) do
        local replacement = with:rep(repeats[replace] or 1)

        text = text:gsub(replace, replacement)
    end

    return text
end

function M.format(format, ...)
    for replace, with in pairs(replacements) do
        local replacement = with:rep(repeats[replace] or 1)

        format = format:gsub(replace, replacement)
        format = format:gsub("(%%%-?%d*%.?%d*)" .. replacement, "%1" .. replace)
    end

    return string.format(format, ...)
end

return M
