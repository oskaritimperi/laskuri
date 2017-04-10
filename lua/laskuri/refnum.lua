-- Calculate the Finnish reference number
local refnum = function(invoicenr)
    local reversed = string.reverse(invoicenr)
    local weights = {7, 3, 1}
    local counter = 0
    local sum = 0
    for digit in string.gmatch(reversed, "%d") do
        local n = tonumber(digit)
        local w = weights[(counter % 3) + 1]
        counter = counter + 1
        sum = sum + n * w
    end
    local check = (sum + (10 - (sum % 10))) - sum
    if check == 10 then
        check = 0
    end
    return invoicenr .. tostring(math.tointeger(check))
end

return {
    refnum = refnum
}
