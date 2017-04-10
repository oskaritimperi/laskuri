-- Group values from given table by the function `fun`. Values from the table
-- are passed to `fun` and `fun` should return some value by which the values
-- are grouped by.
local group_by = function(tbl, fun)
    local result = {}
    for k, v in pairs(tbl) do
        local k = fun(v)
        if not result[k] then
            result[k] = {}
            result[k][1] = v
        else
            result[k][#result[k]+1] = v
        end
    end
    return result
end

-- Calculate the due date from this day forwards.
local due_date = function(days, fmt)
    fmt = fmt or "%Y-%m-%d"
    local days_secs = 60 * 60 * 24 * days
    local now = os.time()
    local due = now + days_secs
    return os.date(fmt, due)
end

return {
    group_by = group_by,
    due_date = due_date
}
