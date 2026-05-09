// CurrencyData.js - Shared currency definitions for currency-exchange plugin
// Supported currencies from frankfurter.app API

.pragma library

var currencies = [
  "AUD", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR",
  "GBP", "HKD", "HUF", "IDR", "ILS", "INR", "ISK", "JPY",
  "KRW", "MXN", "MYR", "NOK", "NZD", "PHP", "PLN", "RON",
  "SEK", "SGD", "THB", "TRY", "USD", "ZAR"
];

var currencyNames = {
  "AUD": "Australian Dollar",
  "BRL": "Brazilian Real",
  "CAD": "Canadian Dollar",
  "CHF": "Swiss Franc",
  "CNY": "Chinese Renminbi Yuan",
  "CZK": "Czech Koruna",
  "DKK": "Danish Krone",
  "EUR": "Euro",
  "GBP": "British Pound",
  "HKD": "Hong Kong Dollar",
  "HUF": "Hungarian Forint",
  "IDR": "Indonesian Rupiah",
  "ILS": "Israeli New Shekel",
  "INR": "Indian Rupee",
  "ISK": "Icelandic Króna",
  "JPY": "Japanese Yen",
  "KRW": "South Korean Won",
  "MXN": "Mexican Peso",
  "MYR": "Malaysian Ringgit",
  "NOK": "Norwegian Krone",
  "NZD": "New Zealand Dollar",
  "PHP": "Philippine Peso",
  "PLN": "Polish Złoty",
  "RON": "Romanian Leu",
  "SEK": "Swedish Krona",
  "SGD": "Singapore Dollar",
  "THB": "Thai Baht",
  "TRY": "Turkish Lira",
  "USD": "United States Dollar",
  "ZAR": "South African Rand"
};

var currencySymbols = {
  "AUD": "A$",
  "BRL": "R$",
  "CAD": "C$",
  "CHF": "CHF",
  "CNY": "¥",
  "CZK": "Kč",
  "DKK": "kr",
  "EUR": "€",
  "GBP": "£",
  "HKD": "HK$",
  "HUF": "Ft",
  "IDR": "Rp",
  "ILS": "₪",
  "INR": "₹",
  "ISK": "kr",
  "JPY": "¥",
  "KRW": "₩",
  "MXN": "MX$",
  "MYR": "RM",
  "NOK": "kr",
  "NZD": "NZ$",
  "PHP": "₱",
  "PLN": "zł",
  "RON": "lei",
  "SEK": "kr",
  "SGD": "S$",
  "THB": "฿",
  "TRY": "₺",
  "USD": "$",
  "ZAR": "R"
};

// Build combo box model with full names (for settings)
function buildComboModel(includeEmpty) {
  var model = [];
  if (includeEmpty) {
    model.push({ "key": "", "name": "None (disabled)" });
  }
  for (var i = 0; i < currencies.length; i++) {
    var code = currencies[i];
    model.push({
      "key": code,
      "name": currencyNames[code] + " (" + code + ")"
    });
  }
  return model;
}

// Build compact combo box model with just code (for panel)
function buildCompactModel() {
  var model = [];
  for (var i = 0; i < currencies.length; i++) {
    var code = currencies[i];
    model.push({
      "key": code,
      "name": code
    });
  }
  return model;
}

// Get display name for a currency code
function getDisplayName(code) {
  return currencyNames[code] || code;
}

// Get symbol for a currency code
function getSymbol(code) {
  return currencySymbols[code] || code;
}

// Check if a currency code is valid
function isValidCurrency(code) {
  return currencies.indexOf(code) !== -1;
}
