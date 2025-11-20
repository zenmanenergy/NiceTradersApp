import { baseURL } from '../Settings';
import { SuperFetch } from '../SuperFetch';

/**
 * Download latest exchange rates from API and save to database
 */
export async function handleDownloadExchangeRates(callback) {
    console.log('[handleDownloadExchangeRates] Downloading exchange rates');
    
    const url = `${baseURL}/ExchangeRates/Download?`;
    
    const response = await SuperFetch(url, {}, true);
    console.log('[handleDownloadExchangeRates] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Get all current exchange rates from database
 */
export async function handleGetExchangeRates(date = null, callback) {
    console.log('[handleGetExchangeRates] Getting exchange rates for date:', date || 'latest');
    
    const data = {};
    if (date) {
        data.date = date;
    }
    
    const url = `${baseURL}/ExchangeRates/GetRates?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleGetExchangeRates] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Get exchange rate between two specific currencies
 */
export async function handleGetExchangeRate(fromCurrency, toCurrency, callback) {
    console.log('[handleGetExchangeRate] Getting rate from', fromCurrency, 'to', toCurrency);
    
    const data = {
        fromCurrency: fromCurrency,
        toCurrency: toCurrency
    };
    
    const url = `${baseURL}/ExchangeRates/GetRate?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleGetExchangeRate] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Convert an amount from one currency to another
 */
export async function handleConvertAmount(amount, fromCurrency, toCurrency, callback) {
    console.log('[handleConvertAmount] Converting', amount, fromCurrency, 'to', toCurrency);
    
    const data = {
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency
    };
    
    const url = `${baseURL}/ExchangeRates/Convert?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleConvertAmount] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Format currency amount for display
 */
export function formatCurrencyAmount(amount, currency, showSymbol = true) {
    const formatter = new Intl.NumberFormat('en-US', {
        style: showSymbol ? 'currency' : 'decimal',
        currency: currency,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });
    
    return formatter.format(amount);
}

/**
 * Get currency symbol for a currency code
 */
export function getCurrencySymbol(currencyCode) {
    const symbols = {
        'USD': '$',
        'EUR': '€',
        'GBP': '£',
        'JPY': '¥',
        'CNY': '¥',
        'INR': '₹',
        'CAD': 'C$',
        'AUD': 'A$',
        'CHF': 'Fr',
        'SEK': 'kr',
        'NOK': 'kr',
        'DKK': 'kr',
        'PLN': 'zł',
        'CZK': 'Kč',
        'HUF': 'Ft',
        'RUB': '₽',
        'BRL': 'R$',
        'MXN': '$',
        'ZAR': 'R',
        'KRW': '₩',
        'SGD': 'S$',
        'HKD': 'HK$',
        'NZD': 'NZ$'
    };
    
    return symbols[currencyCode] || currencyCode;
}

/**
 * Get list of major currency codes
 */
export function getMajorCurrencies() {
    return [
        { code: 'USD', name: 'US Dollar', symbol: '$' },
        { code: 'EUR', name: 'Euro', symbol: '€' },
        { code: 'GBP', name: 'British Pound', symbol: '£' },
        { code: 'JPY', name: 'Japanese Yen', symbol: '¥' },
        { code: 'CNY', name: 'Chinese Yuan', symbol: '¥' },
        { code: 'INR', name: 'Indian Rupee', symbol: '₹' },
        { code: 'CAD', name: 'Canadian Dollar', symbol: 'C$' },
        { code: 'AUD', name: 'Australian Dollar', symbol: 'A$' },
        { code: 'CHF', name: 'Swiss Franc', symbol: 'Fr' },
        { code: 'SEK', name: 'Swedish Krona', symbol: 'kr' },
        { code: 'NOK', name: 'Norwegian Krone', symbol: 'kr' },
        { code: 'DKK', name: 'Danish Krone', symbol: 'kr' },
        { code: 'PLN', name: 'Polish Zloty', symbol: 'zł' },
        { code: 'CZK', name: 'Czech Koruna', symbol: 'Kč' },
        { code: 'HUF', name: 'Hungarian Forint', symbol: 'Ft' },
        { code: 'RUB', name: 'Russian Ruble', symbol: '₽' },
        { code: 'BRL', name: 'Brazilian Real', symbol: 'R$' },
        { code: 'MXN', name: 'Mexican Peso', symbol: '$' },
        { code: 'ZAR', name: 'South African Rand', symbol: 'R' },
        { code: 'KRW', name: 'South Korean Won', symbol: '₩' },
        { code: 'SGD', name: 'Singapore Dollar', symbol: 'S$' },
        { code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK$' },
        { code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ$' }
    ];
}