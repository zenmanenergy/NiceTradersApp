#!/usr/bin/env python3
import pymysql
import pymysql.cursors

# Database connection
db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

# Translation keys and values for location proposal feature
translations = [
    # English
    ("PROPOSE_LOCATION", "en", "Propose Location"),
    ("CONFIRM_LOCATION_PROPOSAL", "en", "Confirm Location Proposal"),
    ("PROPOSED_LOCATION", "en", "Proposed Location"),
    ("ACCEPT_LOCATION", "en", "Accept Location"),
    ("REJECT_LOCATION", "en", "Reject Location"),
    ("COUNTER_PROPOSE_LOCATION", "en", "Counter Propose Location"),
    ("LOCATION_PROPOSED", "en", "Location Proposed"),
    ("AWAITING_LOCATION_RESPONSE", "en", "Awaiting Location Response"),
    ("LOCATION_ACCEPTED", "en", "Location Accepted"),
    
    # Japanese
    ("PROPOSE_LOCATION", "ja", "場所を提案"),
    ("CONFIRM_LOCATION_PROPOSAL", "ja", "場所の提案を確認"),
    ("PROPOSED_LOCATION", "ja", "提案された場所"),
    ("ACCEPT_LOCATION", "ja", "場所を受け入れる"),
    ("REJECT_LOCATION", "ja", "場所を拒否"),
    ("COUNTER_PROPOSE_LOCATION", "ja", "別の場所を提案"),
    ("LOCATION_PROPOSED", "ja", "場所が提案されました"),
    ("AWAITING_LOCATION_RESPONSE", "ja", "場所の応答を待機中"),
    ("LOCATION_ACCEPTED", "ja", "場所が受け入れられました"),
    
    # Spanish
    ("PROPOSE_LOCATION", "es", "Proponer Ubicación"),
    ("CONFIRM_LOCATION_PROPOSAL", "es", "Confirmar Propuesta de Ubicación"),
    ("PROPOSED_LOCATION", "es", "Ubicación Propuesta"),
    ("ACCEPT_LOCATION", "es", "Aceptar Ubicación"),
    ("REJECT_LOCATION", "es", "Rechazar Ubicación"),
    ("COUNTER_PROPOSE_LOCATION", "es", "Contraproponer Ubicación"),
    ("LOCATION_PROPOSED", "es", "Ubicación Propuesta"),
    ("AWAITING_LOCATION_RESPONSE", "es", "Esperando Respuesta de Ubicación"),
    ("LOCATION_ACCEPTED", "es", "Ubicación Aceptada"),
    
    # French
    ("PROPOSE_LOCATION", "fr", "Proposer un Lieu"),
    ("CONFIRM_LOCATION_PROPOSAL", "fr", "Confirmer la Proposition de Lieu"),
    ("PROPOSED_LOCATION", "fr", "Lieu Proposé"),
    ("ACCEPT_LOCATION", "fr", "Accepter le Lieu"),
    ("REJECT_LOCATION", "fr", "Refuser le Lieu"),
    ("COUNTER_PROPOSE_LOCATION", "fr", "Contre-Proposer un Lieu"),
    ("LOCATION_PROPOSED", "fr", "Lieu Proposé"),
    ("AWAITING_LOCATION_RESPONSE", "fr", "En Attente de Réponse de Lieu"),
    ("LOCATION_ACCEPTED", "fr", "Lieu Accepté"),
    
    # German
    ("PROPOSE_LOCATION", "de", "Ort Vorschlagen"),
    ("CONFIRM_LOCATION_PROPOSAL", "de", "Ortsvorschlag Bestätigen"),
    ("PROPOSED_LOCATION", "de", "Vorgeschlagener Ort"),
    ("ACCEPT_LOCATION", "de", "Ort Akzeptieren"),
    ("REJECT_LOCATION", "de", "Ort Ablehnen"),
    ("COUNTER_PROPOSE_LOCATION", "de", "Gegenvorschlag machen"),
    ("LOCATION_PROPOSED", "de", "Ort Vorgeschlagen"),
    ("AWAITING_LOCATION_RESPONSE", "de", "Warte auf Ortantwort"),
    ("LOCATION_ACCEPTED", "de", "Ort Akzeptiert"),
    
    # Arabic
    ("PROPOSE_LOCATION", "ar", "اقتراح موقع"),
    ("CONFIRM_LOCATION_PROPOSAL", "ar", "تأكيد اقتراح الموقع"),
    ("PROPOSED_LOCATION", "ar", "الموقع المقترح"),
    ("ACCEPT_LOCATION", "ar", "قبول الموقع"),
    ("REJECT_LOCATION", "ar", "رفض الموقع"),
    ("COUNTER_PROPOSE_LOCATION", "ar", "اقتراح موقع بديل"),
    ("LOCATION_PROPOSED", "ar", "تم اقتراح الموقع"),
    ("AWAITING_LOCATION_RESPONSE", "ar", "في انتظار رد الموقع"),
    ("LOCATION_ACCEPTED", "ar", "تم قبول الموقع"),
    
    # Hindi
    ("PROPOSE_LOCATION", "hi", "स्थान का सुझाव दें"),
    ("CONFIRM_LOCATION_PROPOSAL", "hi", "स्थान प्रस्ताव की पुष्टि करें"),
    ("PROPOSED_LOCATION", "hi", "प्रस्तावित स्थान"),
    ("ACCEPT_LOCATION", "hi", "स्थान स्वीकार करें"),
    ("REJECT_LOCATION", "hi", "स्थान अस्वीकार करें"),
    ("COUNTER_PROPOSE_LOCATION", "hi", "वैकल्पिक स्थान का सुझाव दें"),
    ("LOCATION_PROPOSED", "hi", "स्थान का सुझाव दिया गया"),
    ("AWAITING_LOCATION_RESPONSE", "hi", "स्थान प्रतिक्रिया की प्रतीक्षा"),
    ("LOCATION_ACCEPTED", "hi", "स्थान स्वीकृत"),
    
    # Portuguese
    ("PROPOSE_LOCATION", "pt", "Propor Local"),
    ("CONFIRM_LOCATION_PROPOSAL", "pt", "Confirmar Proposta de Local"),
    ("PROPOSED_LOCATION", "pt", "Local Proposto"),
    ("ACCEPT_LOCATION", "pt", "Aceitar Local"),
    ("REJECT_LOCATION", "pt", "Rejeitar Local"),
    ("COUNTER_PROPOSE_LOCATION", "pt", "Contrapropor Local"),
    ("LOCATION_PROPOSED", "pt", "Local Proposto"),
    ("AWAITING_LOCATION_RESPONSE", "pt", "Aguardando Resposta do Local"),
    ("LOCATION_ACCEPTED", "pt", "Local Aceito"),
    
    # Russian
    ("PROPOSE_LOCATION", "ru", "Предложить Место"),
    ("CONFIRM_LOCATION_PROPOSAL", "ru", "Подтвердить Предложение Места"),
    ("PROPOSED_LOCATION", "ru", "Предложенное Место"),
    ("ACCEPT_LOCATION", "ru", "Принять Место"),
    ("REJECT_LOCATION", "ru", "Отклонить Место"),
    ("COUNTER_PROPOSE_LOCATION", "ru", "Предложить Альтернативное Место"),
    ("LOCATION_PROPOSED", "ru", "Место Предложено"),
    ("AWAITING_LOCATION_RESPONSE", "ru", "Ожидание Ответа о Месте"),
    ("LOCATION_ACCEPTED", "ru", "Место Принято"),
    
    # Slovak
    ("PROPOSE_LOCATION", "sk", "Navrhnúť Miesto"),
    ("CONFIRM_LOCATION_PROPOSAL", "sk", "Potvrdiť Návrh Miesta"),
    ("PROPOSED_LOCATION", "sk", "Navrhnuté Miesto"),
    ("ACCEPT_LOCATION", "sk", "Prijať Miesto"),
    ("REJECT_LOCATION", "sk", "Odmietnuť Miesto"),
    ("COUNTER_PROPOSE_LOCATION", "sk", "Navrhnúť Iné Miesto"),
    ("LOCATION_PROPOSED", "sk", "Miesto Navrhnuté"),
    ("AWAITING_LOCATION_RESPONSE", "sk", "Čakanie na Odpoveď Miesta"),
    ("LOCATION_ACCEPTED", "sk", "Miesto Prijaté"),
    
    # Chinese
    ("PROPOSE_LOCATION", "zh", "提议地点"),
    ("CONFIRM_LOCATION_PROPOSAL", "zh", "确认地点提议"),
    ("PROPOSED_LOCATION", "zh", "建议的地点"),
    ("ACCEPT_LOCATION", "zh", "接受地点"),
    ("REJECT_LOCATION", "zh", "拒绝地点"),
    ("COUNTER_PROPOSE_LOCATION", "zh", "反向提议地点"),
    ("LOCATION_PROPOSED", "zh", "地点已提议"),
    ("AWAITING_LOCATION_RESPONSE", "zh", "等待地点响应"),
    ("LOCATION_ACCEPTED", "zh", "地点已接受"),
]

# Insert translations
for key, lang, value in translations:
    cursor.execute("""
        INSERT INTO translations (translation_key, language_code, translation_value) 
        VALUES (%s, %s, %s) 
        ON DUPLICATE KEY UPDATE translation_value = %s
    """, (key, lang, value, value))

db.commit()
db.close()

print(f"✓ Added {len(translations)} translations for location proposal feature")
