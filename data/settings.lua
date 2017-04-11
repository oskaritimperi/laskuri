invoicer = ""
address_line_1 = ""
address_line_2 = ""
business_id = ""
www_address = ""
iban = ""
bic_swift = ""

-- How to format dates. See
--
--     http://www.lua.org/manual/5.3/manual.html#pdf-os.date
--
-- and
--
--     http://strftime.net
--
-- for documentation.
date_fmt = "%d.%m.%Y"

-- Maps column names in your CSV to laskuri internal names. Substitute the
-- values in double quotes with your own column names.
columns = {
    InvoiceNr = "InvoiceNr",
    ReferenceNr = "ReferenceNr",
    Price = "Price",
    Amount = "Amount",
    Unit = "Unit",
    Customer = "Customer",
    Product = "Product",
    Vat = "Vat",
}

-- Defaults for columns.
defaults = {
    Price = 0,
    Amount = 1,
    Unit = "kpl",
    Vat = 0,
}
