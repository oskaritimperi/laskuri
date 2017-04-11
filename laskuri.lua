local ftcsv = require("ftcsv")
local refnum = require("laskuri.refnum")
local utils = require("laskuri.utils")
local pprint = require("pprint")

dofile("settings.lua")

-- Load data from the file `invoices.csv`
local data = ftcsv.parse("invoices.csv", ",")

-- Do some preprocessing for each row

-- Convert column names to internal representation. Also set defaults.
for _, row in pairs(data) do
    for columnid, column in pairs(columns) do
        if column ~= "" then
            local value = row[column]
            if not value then
                row[columnid] = defaults[columnid] or ""
            else
                if value == "" then
                    value = defaults[columnid] or ""
                end
                row[columnid] = value
                row[column] = nil
            end
        else
            row[columnid] = defaults[columnid] or ""
        end
    end
end

local num_fields = { "Amount", "Price", "Vat" }

for _, row in pairs(data) do
    -- Convert applicable fields to lua numbers
    for _, field in pairs(num_fields) do
        row[field] = tonumber(row[field])
    end

    -- Calculate tax and final price for each row
    row.Tax = row.Price * (row.Vat / 100.0)
    row.FinalPrice = row.Price + row.Tax
end

-- Group the data (rows) by the invoice number.
local invoices = utils.group_by(data, function(invoice)
    return invoice.InvoiceNr
end)

-- Calculate some needed data for each invoice including price, final price, due
-- date and reference number
for invoice_nr, rows in pairs(invoices) do
    local price = 0.0
    local final_price = 0.0
    local tax = 0.0
    local ref = nil

    for _, row in pairs(rows) do
        price = price + row.Price
        final_price = final_price + row.FinalPrice
        tax = tax + row.Tax
        ref = row.ReferenceNr
    end

    if ref and ref == "" then
        ref = nil
    end

    rows.data = {
        Price = price,
        FinalPrice = final_price,
        Tax = tax,
        Due = utils.due_date(14, date_fmt),
        ReferenceNr = ref or refrefnum.refnum(invoice_nr),
    }
end

local today = os.date(date_fmt)

-- pprint.pprint(invoices)

function to_filename(s)
    return string.gsub(s, "[^%w]", "_")
end

for invoice_nr, invoice in pairs(invoices) do
    doc = Document:New()

    doc:SetCompressionMode("all")
    doc:UseUTFEncodings()

    page = doc:AddPage()

    page:SetSize("A4", "portrait")

    font = doc:LoadTTFontFromFile("fonts/Roboto/Roboto-Regular.ttf", true, "UTF-8")
    font_bold = doc:LoadTTFontFromFile("fonts/Roboto/Roboto-Bold.ttf", true, "UTF-8")

    page:CreateGrid(15, 50)
    -- page:DrawGrid()

    page:BeginText()

    page:SetFontAndSize(font, 12)
    page:TextCell(0, 0, 3, 1, invoicer, "left")

    page:SetFontAndSize(font, 10)
    page:TextCell(0, 1, 3, 1, address_line_1, "left")
    page:TextCell(0, 2, 3, 1, address_line_2, "left")

    page:SetFontAndSize(font_bold, 14)
    page:TextCell(8, 0, 3, 1, "LASKU", "left")

    page:SetFontAndSize(font, 9)
    page:TextCell(8, 2, 3, 1, "Laskun päiväys:", "left")
    page:TextCell(8, 3, 3, 1, today, "left")

    page:TextCell(8, 4, 3, 1, "Laskunumero:", "left")
    page:TextCell(8, 5, 3, 1, invoice_nr, "left")

    page:TextCell(8, 6, 3, 1, "Eräpäivä:", "left")
    page:TextCell(8, 7, 3, 1, invoice.data.Due, "left")

    page:SetFontAndSize(font_bold, 10)
    page:TextCell(0, 5, 5, 3, invoice[1].Customer, "left")

    page:SetFontAndSize(font, 10)
    page:TextCell(0,  10, 3, 1,  "Nimike", "left")
    page:TextCell(3,  10, 2, 1, "Määrä", "right")
    page:TextCell(5,  10, 2, 1,  "Yks.", "left")
    page:TextCell(7,  10, 2, 1, "A'hinta EUR", "right")
    page:TextCell(9,  10, 2, 1, "Alv %", "right")
    page:TextCell(11, 10, 3, 1, "Verollinen yht. EUR", "right")

    product_row = 11

    for idx = 1, #invoice do
        product = invoice[idx]
        local row = product_row + idx - 1
        page:TextCell(0, row, 3, 1, product.Product, "left")
        page:TextCell(3, row, 2, 1, string.format("%d", product.Amount), "right")
        page:TextCell(5, row, 2, 1, product.Unit, "left")
        page:TextCell(7, row, 2, 1, string.format("%.2f", product.Price), "right")
        page:TextCell(9, row, 2, 1, string.format("%d", product.Vat), "right")
        page:TextCell(11, row, 3, 1, string.format("%.2f", product.FinalPrice), "right")
    end

    page:SetFontAndSize(font_bold, 10)
    page:TextCell(7, 38, 4, 1, "Veroton yhteensä EUR", "right")
    page:TextCell(7, 39, 4, 1, "ALV yhteensä EUR", "right")
    page:TextCell(7, 40, 4, 1, "Verollinen yhteensä EUR", "right")

    page:SetFontAndSize(font, 10)
    page:TextCell(11, 38, 3, 1, string.format("%.2f", invoice.data.Price), "right")
    page:TextCell(11, 39, 3, 1, string.format("%.2f", invoice.data.Tax), "right")
    page:TextCell(11, 40, 3, 1, string.format("%.2f", invoice.data.FinalPrice), "right")

    page:TextCell(0,  43, 7, 1, "IBAN:", "left")
    page:TextCell(0,  44, 7, 1, iban, "left")
    page:TextCell(7,  43, 4, 1, "BIC / SWIFT:", "left")
    page:TextCell(7,  44, 4, 1, bic_swift, "left")
    page:TextCell(11, 43, 3, 1, "Eräpäivä:", "left")
    page:TextCell(11, 44, 3, 1, invoice.data.Due, "left")

    page:TextCell(0,  45, 7, 1, "Viitenumero:", "left")
    page:SetFontAndSize(font_bold, 10)
    page:TextCell(0,  46, 7, 1, invoice.data.ReferenceNr, "left")
    page:SetFontAndSize(font, 10)
    page:TextCell(7,  45, 7, 1, "Yhteensä EUR:", "left")
    page:SetFontAndSize(font_bold, 10)
    page:TextCell(7,  46, 7, 1, string.format("%.2f", invoice.data.FinalPrice), "left")

    page:SetFontAndSize(font, 10)
    page:TextCell(0,  47, 7, 1, invoicer, "left")
    page:TextCell(0,  48, 7, 1, address_line_1, "left")
    page:TextCell(0,  49, 7, 1, address_line_2, "left")

    page:TextCell(7,  47, 2, 1, "Y-tunnus:", "left")
    page:TextCell(9,  47, 5, 1, business_id, "left")

    page:TextCell(7,  48, 2, 1, "WWW:", "left")
    page:TextCell(9,  48, 5, 1, www_address, "left")

    page:EndText()

    filename = to_filename(invoice_nr .. " " .. invoice[1].Customer)

    doc:Save(filename .. ".pdf")
end
