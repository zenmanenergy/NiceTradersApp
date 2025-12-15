-- Remove exchange history related translations
DELETE FROM translations WHERE translation_key IN (
    'EXCHANGE_HISTORY',
    'VIEW_EXCHANGE_HISTORY',
    'LOADING_EXCHANGE_HISTORY'
);
