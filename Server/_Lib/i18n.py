"""
Internationalization (i18n) Support for NiceTradersApp
Handles multi-language support, locale-specific formatting, and translations
"""

# Supported languages and locales
SUPPORTED_LANGUAGES = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'ja': '日本語',
    'zh': '中文',
    'ru': 'Русский',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'sk': 'Slovenčina'  # For your Slovak todo
}

# Date format patterns by locale
DATE_FORMATS = {
    'en': '%m/%d/%Y',
    'es': '%d/%m/%Y',
    'fr': '%d/%m/%Y',
    'de': '%d.%m.%Y',
    'pt': '%d/%m/%Y',
    'ja': '%Y年%m月%d日',
    'zh': '%Y年%m月%d日',
    'ru': '%d.%m.%Y',
    'ar': '%d/%m/%Y',
    'hi': '%d/%m/%Y',
    'sk': '%d.%m.%Y'
}

# Time format patterns by locale
TIME_FORMATS = {
    'en': '%I:%M %p',      # 2:30 PM
    'es': '%H:%M',         # 14:30
    'fr': '%H:%M',         # 14:30
    'de': '%H:%M',         # 14:30
    'pt': '%H:%M',         # 14:30
    'ja': '%H:%M',         # 14:30
    'zh': '%H:%M',         # 14:30
    'ru': '%H:%M',         # 14:30
    'ar': '%H:%M',         # 14:30
    'hi': '%H:%M',         # 14:30
    'sk': '%H:%M'          # 14:30
}

# Currency symbols by code with locale-specific formatting
CURRENCY_FORMATTING = {
    'USD': {'symbol': '$', 'position': 'prefix', 'separator': ''},
    'EUR': {'symbol': '€', 'position': 'suffix', 'separator': ' '},
    'GBP': {'symbol': '£', 'position': 'prefix', 'separator': ''},
    'JPY': {'symbol': '¥', 'position': 'prefix', 'separator': ''},
    'CNY': {'symbol': '¥', 'position': 'prefix', 'separator': ''},
    'INR': {'symbol': '₹', 'position': 'prefix', 'separator': ''},
    'RUB': {'symbol': '₽', 'position': 'suffix', 'separator': ' '},
    'SAR': {'symbol': 'ر.س', 'position': 'suffix', 'separator': ' '},
    'SKK': {'symbol': 'Sk', 'position': 'suffix', 'separator': ' '},  # Slovak koruna
    'AED': {'symbol': 'د.إ', 'position': 'suffix', 'separator': ' '},  # UAE Dirham
}

# Decimal and thousands separators by locale
NUMBER_FORMATTING = {
    'en': {'decimal': '.', 'thousands': ','},
    'es': {'decimal': ',', 'thousands': '.'},
    'fr': {'decimal': ',', 'thousands': ' '},
    'de': {'decimal': ',', 'thousands': '.'},
    'pt': {'decimal': ',', 'thousands': '.'},
    'ja': {'decimal': '.', 'thousands': ','},
    'zh': {'decimal': '.', 'thousands': ','},
    'ru': {'decimal': ',', 'thousands': ' '},
    'ar': {'decimal': ',', 'thousands': '.'},
    'hi': {'decimal': '.', 'thousands': ','},
    'sk': {'decimal': ',', 'thousands': ' '}
}

# Text direction by language
TEXT_DIRECTION = {
    'en': 'ltr',
    'es': 'ltr',
    'fr': 'ltr',
    'de': 'ltr',
    'pt': 'ltr',
    'ja': 'ltr',
    'zh': 'ltr',
    'ru': 'ltr',
    'ar': 'rtl',  # Right-to-left
    'hi': 'ltr',
    'sk': 'ltr'
}

# Common translations
TRANSLATIONS = {
    'en': {
        'payment_received': 'Payment Received',
        'meeting_proposed': 'Meeting Proposed',
        'new_message': 'New Message',
        'listing_flagged': 'Your listing has been flagged',
        'rating_received': 'You received a new rating',
        'from': 'from',
        'at': 'at',
        'meeting_proposed_text': 'proposed a meeting at',
        'message_from': 'sent you a message',
        'cancel': 'Cancel',
        'send': 'Send',
        'back': 'Back',
        'edit': 'Edit',
        'delete': 'Delete',
        'save': 'Save',
        'loading': 'Loading...',
        'error': 'Error',
        'success': 'Success',
        'search': 'Search',
        'filter': 'Filter',
        'sort': 'Sort',
        'no_results': 'No results found',
        'confirmation': 'Are you sure?',
    },
    'es': {
        'payment_received': 'Pago Recibido',
        'meeting_proposed': 'Reunión Propuesta',
        'new_message': 'Nuevo Mensaje',
        'listing_flagged': 'Tu anuncio ha sido marcado',
        'rating_received': 'Recibiste una nueva calificación',
        'from': 'de',
        'at': 'a',
        'meeting_proposed_text': 'propuso una reunión a',
        'message_from': 'te envió un mensaje',
        'cancel': 'Cancelar',
        'send': 'Enviar',
        'back': 'Atrás',
        'edit': 'Editar',
        'delete': 'Eliminar',
        'save': 'Guardar',
        'loading': 'Cargando...',
        'error': 'Error',
        'success': 'Éxito',
        'search': 'Buscar',
        'filter': 'Filtro',
        'sort': 'Ordenar',
        'no_results': 'Sin resultados',
        'confirmation': '¿Estás seguro?',
    },
    'fr': {
        'payment_received': 'Paiement Reçu',
        'meeting_proposed': 'Réunion Proposée',
        'new_message': 'Nouveau Message',
        'listing_flagged': 'Votre annonce a été signalée',
        'rating_received': 'Vous avez reçu une nouvelle évaluation',
        'from': 'de',
        'at': 'à',
        'meeting_proposed_text': 'a proposé une réunion à',
        'message_from': 'vous a envoyé un message',
        'cancel': 'Annuler',
        'send': 'Envoyer',
        'back': 'Retour',
        'edit': 'Modifier',
        'delete': 'Supprimer',
        'save': 'Enregistrer',
        'loading': 'Chargement...',
        'error': 'Erreur',
        'success': 'Succès',
        'search': 'Rechercher',
        'filter': 'Filtre',
        'sort': 'Trier',
        'no_results': 'Aucun résultat',
        'confirmation': 'Êtes-vous sûr?',
    },
    'de': {
        'payment_received': 'Zahlung Erhalten',
        'meeting_proposed': 'Treffen Vorgeschlagen',
        'new_message': 'Neue Nachricht',
        'listing_flagged': 'Ihre Anzeige wurde gekennzeichnet',
        'rating_received': 'Sie haben eine neue Bewertung erhalten',
        'from': 'von',
        'at': 'um',
        'meeting_proposed_text': 'schlug ein Treffen um vor',
        'message_from': 'hat Ihnen eine Nachricht gesendet',
        'cancel': 'Abbrechen',
        'send': 'Senden',
        'back': 'Zurück',
        'edit': 'Bearbeiten',
        'delete': 'Löschen',
        'save': 'Speichern',
        'loading': 'Wird geladen...',
        'error': 'Fehler',
        'success': 'Erfolg',
        'search': 'Suche',
        'filter': 'Filter',
        'sort': 'Sortieren',
        'no_results': 'Keine Ergebnisse',
        'confirmation': 'Bist du sicher?',
    },
    'pt': {
        'payment_received': 'Pagamento Recebido',
        'meeting_proposed': 'Reunião Proposta',
        'new_message': 'Nova Mensagem',
        'listing_flagged': 'Seu anúncio foi sinalizado',
        'rating_received': 'Você recebeu uma nova avaliação',
        'from': 'de',
        'at': 'em',
        'meeting_proposed_text': 'propôs uma reunião em',
        'message_from': 'enviou-lhe uma mensagem',
        'cancel': 'Cancelar',
        'send': 'Enviar',
        'back': 'Voltar',
        'edit': 'Editar',
        'delete': 'Excluir',
        'save': 'Guardar',
        'loading': 'Carregando...',
        'error': 'Erro',
        'success': 'Sucesso',
        'search': 'Pesquisar',
        'filter': 'Filtro',
        'sort': 'Ordenar',
        'no_results': 'Nenhum resultado',
        'confirmation': 'Você tem certeza?',
    },
    'ja': {
        'payment_received': '支払いを受け取りました',
        'meeting_proposed': 'ミーティングが提案されました',
        'new_message': '新しいメッセージ',
        'listing_flagged': 'あなたのリスティングがフラグされました',
        'rating_received': '新しい評価を受け取りました',
        'from': 'から',
        'at': 'で',
        'meeting_proposed_text': 'がミーティングを提案しました',
        'message_from': 'があなたにメッセージを送信しました',
        'cancel': 'キャンセル',
        'send': '送信',
        'back': '戻る',
        'edit': '編集',
        'delete': '削除',
        'save': '保存',
        'loading': '読み込み中...',
        'error': 'エラー',
        'success': '成功',
        'search': '検索',
        'filter': 'フィルター',
        'sort': 'ソート',
        'no_results': '結果なし',
        'confirmation': 'よろしいですか？',
    },
    'sk': {
        'payment_received': 'Platba Prijatá',
        'meeting_proposed': 'Stretnutie Navrhnuté',
        'new_message': 'Nová Správa',
        'listing_flagged': 'Vaš inzerát bol označený',
        'rating_received': 'Dostali ste nové hodnotenie',
        'from': 'od',
        'at': 'o',
        'meeting_proposed_text': 'navrhol stretnutie o',
        'message_from': 'vám poslal správu',
        'cancel': 'Zrušiť',
        'send': 'Poslať',
        'back': 'Späť',
        'edit': 'Upraviť',
        'delete': 'Vymazať',
        'save': 'Uložiť',
        'loading': 'Načítava sa...',
        'error': 'Chyba',
        'success': 'Úspech',
        'search': 'Hľadať',
        'filter': 'Filter',
        'sort': 'Triedenie',
        'no_results': 'Žiadne výsledky',
        'confirmation': 'Ste si istí?',
    }
}


def get_translation(language_code: str, key: str, default: str = None) -> str:
    """
    Get a translated string for the given language and key
    
    Args:
        language_code: Language code (e.g., 'en', 'es', 'fr')
        key: Translation key
        default: Default value if translation not found
    
    Returns:
        Translated string or default
    """
    if language_code not in TRANSLATIONS:
        language_code = 'en'  # Fallback to English
    
    return TRANSLATIONS[language_code].get(key, default or key)


def format_currency(amount: float, currency_code: str, language_code: str = 'en') -> str:
    """
    Format a currency amount for display in the given language
    
    Args:
        amount: The numeric amount
        currency_code: Currency code (e.g., 'USD', 'EUR')
        language_code: Language for formatting
    
    Returns:
        Formatted currency string
    """
    if currency_code not in CURRENCY_FORMATTING:
        return f"{amount:.2f} {currency_code}"
    
    # Get formatting rules
    fmt = CURRENCY_FORMATTING[currency_code]
    num_fmt = NUMBER_FORMATTING.get(language_code, NUMBER_FORMATTING['en'])
    
    # Format the number
    formatted_num = format_number(amount, language_code, decimal_places=2)
    
    # Apply currency formatting
    symbol = fmt['symbol']
    separator = fmt.get('separator', '')
    
    if fmt['position'] == 'prefix':
        return f"{symbol}{separator}{formatted_num}"
    else:
        return f"{formatted_num}{separator}{symbol}"


def format_number(number: float, language_code: str = 'en', decimal_places: int = 2) -> str:
    """
    Format a number according to locale rules
    
    Args:
        number: The number to format
        language_code: Language for formatting
        decimal_places: Number of decimal places
    
    Returns:
        Formatted number string
    """
    num_fmt = NUMBER_FORMATTING.get(language_code, NUMBER_FORMATTING['en'])
    
    # Format with decimal places
    formatted = f"{number:.{decimal_places}f}"
    
    # Split into integer and decimal parts
    parts = formatted.split('.')
    integer_part = parts[0]
    decimal_part = parts[1] if len(parts) > 1 else None
    
    # Add thousands separator
    thousands_sep = num_fmt['thousands']
    integer_with_sep = ''
    for i, digit in enumerate(reversed(integer_part)):
        if i > 0 and i % 3 == 0:
            integer_with_sep = thousands_sep + integer_with_sep
        integer_with_sep = digit + integer_with_sep
    
    # Combine with decimal separator
    decimal_sep = num_fmt['decimal']
    if decimal_part:
        return f"{integer_with_sep}{decimal_sep}{decimal_part}"
    return integer_with_sep


def format_date(date_obj, language_code: str = 'en') -> str:
    """
    Format a date according to locale
    
    Args:
        date_obj: datetime object or string
        language_code: Language for formatting
    
    Returns:
        Formatted date string
    """
    from datetime import datetime
    
    if isinstance(date_obj, str):
        date_obj = datetime.fromisoformat(date_obj)
    
    date_format = DATE_FORMATS.get(language_code, DATE_FORMATS['en'])
    return date_obj.strftime(date_format)


def format_time(time_obj, language_code: str = 'en') -> str:
    """
    Format a time according to locale
    
    Args:
        time_obj: datetime object or string
        language_code: Language for formatting
    
    Returns:
        Formatted time string
    """
    from datetime import datetime
    
    if isinstance(time_obj, str):
        time_obj = datetime.fromisoformat(time_obj)
    
    time_format = TIME_FORMATS.get(language_code, TIME_FORMATS['en'])
    return time_obj.strftime(time_format)


def format_datetime(datetime_obj, language_code: str = 'en') -> str:
    """
    Format a datetime according to locale
    
    Args:
        datetime_obj: datetime object or string
        language_code: Language for formatting
    
    Returns:
        Formatted datetime string (date + time)
    """
    from datetime import datetime
    
    if isinstance(datetime_obj, str):
        datetime_obj = datetime.fromisoformat(datetime_obj)
    
    date_str = format_date(datetime_obj, language_code)
    time_str = format_time(datetime_obj, language_code)
    return f"{date_str} {time_str}"


def get_text_direction(language_code: str = 'en') -> str:
    """Get text direction (ltr or rtl) for a language"""
    return TEXT_DIRECTION.get(language_code, 'ltr')
