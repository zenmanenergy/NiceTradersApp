#!/usr/bin/env python3
"""
Migration script to add LearnMoreView localization keys for all languages.
This adds all hardcoded English strings from LearnMoreView.swift as localization keys.
"""

import sys
from datetime import datetime

sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Define all strings to add with translations for all 11 languages
LEARN_MORE_STRINGS = {
    "HOW_NICE_TRADERS_WORKS": {
        "en": "How Nice Traders Works",
        "es": "Cómo funciona Nice Traders",
        "fr": "Comment fonctionne Nice Traders",
        "de": "So funktioniert Nice Traders",
        "pt": "Como funciona o Nice Traders",
        "ja": "Nice Tradersの仕組み",
        "zh": "Nice Traders如何运作",
        "ru": "Как работает Nice Traders",
        "ar": "كيف يعمل Nice Traders",
        "hi": "Nice Traders कैसे काम करता है",
        "sk": "Ako funguje Nice Traders"
    },
    "SMART_WAY_EXCHANGE_LOCALLY": {
        "en": "The smart way to exchange currency locally",
        "es": "La forma inteligente de cambiar divisas localmente",
        "fr": "Le moyen intelligent d'échanger des devises localement",
        "de": "Die intelligente Art, Währungen lokal auszutauschen",
        "pt": "A maneira inteligente de trocar moedas localmente",
        "ja": "地元で通貨を交換するスマートな方法",
        "zh": "在本地交换货币的聪明方法",
        "ru": "Умный способ обмена валюты на месте",
        "ar": "الطريقة الذكية لتبديل العملات محليًا",
        "hi": "स्थानीय रूप से मुद्रा विनिमय का स्मार्ट तरीका",
        "sk": "Inteligentný spôsob výmeny mien lokálne"
    },
    "WHAT_IS_NICE_TRADERS": {
        "en": "What is Nice Traders?",
        "es": "¿Qué es Nice Traders?",
        "fr": "Qu'est-ce que Nice Traders?",
        "de": "Was ist Nice Traders?",
        "pt": "O que é Nice Traders?",
        "ja": "Nice Tradersとは何ですか？",
        "zh": "什么是Nice Traders？",
        "ru": "Что такое Nice Traders?",
        "ar": "ما هو Nice Traders؟",
        "hi": "Nice Traders क्या है?",
        "sk": "Čo je Nice Traders?"
    },
    "NICE_TRADERS_DESCRIPTION": {
        "en": "Nice Traders is a peer-to-peer platform that connects travelers and locals who want to exchange foreign currency. Instead of paying high fees at banks or exchange kiosks, you can find someone in your neighborhood who has the currency you need and wants what you have.",
        "es": "Nice Traders es una plataforma entre pares que conecta a viajeros y locales que desean cambiar moneda extranjera. En lugar de pagar altas comisiones en bancos o casas de cambio, puede encontrar a alguien en su vecindario que tenga la moneda que necesita y desee lo que usted tiene.",
        "fr": "Nice Traders est une plateforme pair-à-pair qui connecte les voyageurs et les locaux qui souhaitent échanger des devises étrangères. Au lieu de payer des frais élevés dans les banques ou les bureaux de change, vous pouvez trouver quelqu'un dans votre quartier qui a la devise dont vous avez besoin et veut ce que vous avez.",
        "de": "Nice Traders ist eine Peer-to-Peer-Plattform, die Reisende und Einheimische verbindet, die Fremdwährungen austauschen möchten. Anstatt hohe Gebühren in Banken oder Wechselstuben zu zahlen, können Sie jemanden in Ihrer Nachbarschaft finden, der die Währung hat, die Sie benötigen, und möchte, was Sie haben.",
        "pt": "Nice Traders é uma plataforma peer-to-peer que conecta viajantes e locais que desejam trocar moeda estrangeira. Em vez de pagar altas taxas em bancos ou casas de câmbio, você pode encontrar alguém em seu bairro que tenha a moeda que você precisa e queira o que você tem.",
        "ja": "Nice Tradersは、外国通貨を交換したい旅行者と地元の人々を結ぶピアツーピアプラットフォームです。銀行や両替所で高い手数料を支払う代わりに、近所で必要な通貨を持ち、あなたが持っているものを欲しい誰かを見つけることができます。",
        "zh": "Nice Traders是一个点对点平台，连接想要交换外币的旅客和本地人。与其在银行或兑换亭支付高额费用，不如在您的社区中找到拥有您需要的货币并想要您拥有的东西的人。",
        "ru": "Nice Traders - это платформа P2P, которая соединяет путешественников и местных жителей, которые хотят обменять иностранную валюту. Вместо того чтобы платить высокие комиссии в банках или пунктах обмена, вы можете найти в своем районе человека, у которого есть нужная вам валюта и который хочет то, что у вас есть.",
        "ar": "Nice Traders هي منصة نظير إلى نظير تربط المسافرين والسكان المحليين الذين يريدون تبديل العملات الأجنبية. بدلاً من دفع رسوم عالية في البنوك أو أكشاك الصرف، يمكنك العثور على شخص في حيك يمتلك العملة التي تحتاجها ويريد ما لديك.",
        "hi": "Nice Traders एक पीयर-टू-पीयर प्लेटफॉर्म है जो यात्रियों और स्थानीय लोगों को जोड़ता है जो विदेशी मुद्रा का आदान-प्रदान करना चाहते हैं। बैंकों या विनिमय कियोस्क में उच्च शुल्क का भुगतान करने के बजाय, आप अपने पड़ोस में किसी को ढूंढ सकते हैं जिसके पास आपको आवश्यक मुद्रा है और जो आपके पास है उसे चाहता है।",
        "sk": "Nice Traders je platforma peer-to-peer, ktorá spája cestovateľov a miestnych, ktorí chcú vymeniť cudzí menový. Namiesto platenia vysokých poplatkov v bankách alebo zmenárnach môžete nájsť v svojom okolí niekoho, kto má menu, ktorú potrebujete, a chce to, čo máte."
    },
    "HOW_IT_WORKS": {
        "en": "How It Works",
        "es": "Cómo Funciona",
        "fr": "Comment Ça Marche",
        "de": "Wie es funktioniert",
        "pt": "Como Funciona",
        "ja": "仕組み",
        "zh": "它如何工作",
        "ru": "Как это работает",
        "ar": "كيف يعمل",
        "hi": "यह कैसे काम करता है",
        "sk": "Ako to funguje"
    },
    "CREATE_YOUR_LISTING": {
        "en": "Create Your Listing",
        "es": "Crea tu anuncio",
        "fr": "Créez votre annonce",
        "de": "Erstellen Sie Ihr Inserat",
        "pt": "Crie seu anúncio",
        "ja": "あなたのリストを作成",
        "zh": "创建您的列表",
        "ru": "Создайте свое объявление",
        "ar": "إنشاء قائمتك",
        "hi": "अपनी सूची बनाएँ",
        "sk": "Vytvorte svoj zoznam"
    },
    "CREATE_LISTING_DESCRIPTION": {
        "en": "Post the currency you have and what you want to exchange it for. Set your location and preferred meeting places.",
        "es": "Publica la moneda que tienes y por qué deseas cambiarla. Establece tu ubicación y lugares de encuentro preferidos.",
        "fr": "Publiez la devise que vous avez et celle que vous souhaitez échanger. Définissez votre localisation et les lieux de rendez-vous préférés.",
        "de": "Veröffentlichen Sie die Währung, die Sie haben, und wofür Sie diese austauschen möchten. Legen Sie Ihren Standort und bevorzugte Treffpunkte fest.",
        "pt": "Poste a moeda que você tem e por que deseja trocá-la. Defina seu local e locais de encontro preferidos.",
        "ja": "あなたが持っている通貨と交換したいものを投稿してください。あなたの場所と好みの会議場所を設定してください。",
        "zh": "发布您拥有的货币以及您想要交换的货币。设置您的位置和首选会面地点。",
        "ru": "Опубликуйте валюту, которая у вас есть, и то, на что вы хотите ее обменять. Установите ваше местоположение и предпочтительные места встречи.",
        "ar": "انشر العملة التي لديك وما تريد تبديلها. اضبط موقعك وأماكن الاجتماع المفضلة.",
        "hi": "वह मुद्रा पोस्ट करें जो आपके पास है और आप इसके लिए क्या विनिमय करना चाहते हैं। अपना स्थान और पसंदीदा मिलने की जगहें सेट करें।",
        "sk": "Zverejnite menu, ktorú máte, a na čo ju chcete vymeniť. Nastavte svoju polohu a preferované miesta stretávania."
    },
    "SEARCH_AND_MATCH": {
        "en": "Search & Match",
        "es": "Buscar y Coincidir",
        "fr": "Rechercher et Correspondre",
        "de": "Suchen und Abgleichen",
        "pt": "Pesquisar e Combinar",
        "ja": "検索して一致させる",
        "zh": "搜索和匹配",
        "ru": "Поиск и совпадение",
        "ar": "البحث والمطابقة",
        "hi": "खोजें और मेल खाएं",
        "sk": "Vyhľadávanie a zhoda"
    },
    "SEARCH_LISTING_DESCRIPTION": {
        "en": "Browse listings from people nearby who have what you need. Filter by currency, location, and amount.",
        "es": "Examina los anuncios de personas cercanas que tienen lo que necesitas. Filtra por moneda, ubicación y cantidad.",
        "fr": "Parcourez les annonces des personnes à proximité qui ont ce dont vous avez besoin. Filtrez par devise, localisation et montant.",
        "de": "Durchsuchen Sie Inserate von Menschen in Ihrer Nähe, die das haben, was Sie brauchen. Filtern Sie nach Währung, Standort und Menge.",
        "pt": "Procure anúncios de pessoas próximas que possuem o que você precisa. Filtre por moeda, local e valor.",
        "ja": "あなたが必要とするものを持っている近くの人々のリストを閲覧してください。通貨、場所、および金額でフィルタリングしてください。",
        "zh": "浏览附近拥有您需要的东西的人的列表。按货币、位置和金额过滤。",
        "ru": "Просмотрите объявления от людей поблизости, у которых есть то, что вам нужно. Фильтруйте по валюте, местоположению и сумме.",
        "ar": "استعرض قوائم الأشخاص بالقرب منك الذين لديهم ما تحتاجه. قم بالتصفية حسب العملة والموقع والمبلغ.",
        "hi": "उन लोगों की सूचियों को ब्राउज़ करें जो आपके पास हैं जिनके पास आपको चाहिए। मुद्रा, स्थान और राशि से फ़िल्टर करें।",
        "sk": "Prezerajte zoznamy ľudí v blízkosti, ktorí majú to, čo potrebujete. Filtruujte podľa meny, polohy a sumy."
    },
    "CONNECT_SECURELY": {
        "en": "Connect Securely",
        "es": "Conectar de manera segura",
        "fr": "Connectez-vous en toute sécurité",
        "de": "Sicher verbinden",
        "pt": "Conectar com segurança",
        "ja": "安全に接続",
        "zh": "安全连接",
        "ru": "Безопасное подключение",
        "ar": "الاتصال بأمان",
        "hi": "सुरक्षित रूप से कनेक्ट करें",
        "sk": "Bezpečne sa pripojte"
    },
    "CONNECT_DESCRIPTION": {
        "en": "Contact other users through our secure messaging system. Discuss exchange rates, amounts, and meeting details.",
        "es": "Contacta a otros usuarios a través de nuestro sistema de mensajería segura. Discute tasas de cambio, cantidades y detalles de encuentro.",
        "fr": "Contactez d'autres utilisateurs via notre système de messagerie sécurisé. Discutez des taux de change, des montants et des détails de la réunion.",
        "de": "Kontaktieren Sie andere Benutzer über unser sicheres Messaging-System. Diskutieren Sie Wechselkurse, Beträge und Treffpunktdetails.",
        "pt": "Entre em contato com outros usuários através do nosso sistema de mensagens seguro. Discuta taxas de câmbio, valores e detalhes de encontro.",
        "ja": "セキュアなメッセージング システムを通じて他のユーザーに連絡してください。為替レート、金額、会議の詳細について説明してください。",
        "zh": "通过我们的安全消息传递系统与其他用户联系。讨论汇率、金额和会议详情。",
        "ru": "Свяжитесь с другими пользователями через нашу защищенную систему обмена сообщениями. Обсудите курсы обмена, суммы и детали встречи.",
        "ar": "تواصل مع المستخدمين الآخرين من خلال نظام المراسلة الآمن لدينا. ناقش أسعار الصرف والمبالغ وتفاصيل الاجتماع.",
        "hi": "हमारी सुरक्षित मैसेजिंग सिस्टम के माध्यम से अन्य उपयोगकर्ताओं से संपर्क करें। विनिमय दरों, राशियों और मीटिंग विवरण पर चर्चा करें।",
        "sk": "Kontaktujte ďalších používateľov prostredníctvom nášho bezpečného systému zasielania správ. Diskutujte o výmenných kurzoch, sumách a podrobnostiach stretávania."
    },
    "MEET_AND_EXCHANGE": {
        "en": "Meet & Exchange",
        "es": "Conocer e Intercambiar",
        "fr": "Rencontrer et Échanger",
        "de": "Treffen und Austausch",
        "pt": "Encontrar e Trocar",
        "ja": "会う＆交換",
        "zh": "见面和交换",
        "ru": "Встретиться и обменяться",
        "ar": "الالتقاء والتبادل",
        "hi": "मिलें और विनिमय करें",
        "sk": "Stretnutie a výmena"
    },
    "MEET_DESCRIPTION": {
        "en": "Meet in a safe, public location like a coffee shop or bank lobby. Exchange your currency face-to-face.",
        "es": "Reúnete en un lugar público seguro como una cafetería o el vestíbulo de un banco. Cambia tu moneda cara a cara.",
        "fr": "Rencontrez-vous dans un lieu public sûr comme un café ou le hall d'une banque. Échangez votre devise en personne.",
        "de": "Treffen Sie sich an einem sicheren, öffentlichen Ort wie einem Café oder einer Banklobby. Tauschen Sie Ihre Währung persönlich aus.",
        "pt": "Encontre-se em um local público seguro, como uma cafeteria ou saguão de um banco. Troque sua moeda pessoalmente.",
        "ja": "カフェやバンクロビーなどの安全な公共の場所で会いましょう。あなたの通貨を直接交換してください。",
        "zh": "在咖啡馆或银行大厅等安全的公共场所见面。面对面交换您的货币。",
        "ru": "Встречайтесь в безопасном общественном месте, таком как кофейня или вестибюль банка. Обменяйте вашу валюту лично.",
        "ar": "التقِ في مكان عام آمن مثل مقهى أو بهو البنك. تبادل عملتك وجهاً لوجه.",
        "hi": "कैफे या बैंक लॉबी जैसी सुरक्षित सार्वजनिक जगह पर मिलें। आमने-सामने अपनी मुद्रा का आदान-प्रदान करें।",
        "sk": "Stretnite sa na bezpečnom verejnom mieste, ako je kaviareň alebo hala banky. Vymeňte si menu tvárou v tvár."
    },
    "RATE_AND_REVIEW": {
        "en": "Rate & Review",
        "es": "Calificar y Comentar",
        "fr": "Noter et Commenter",
        "de": "Bewerten und Kommentieren",
        "pt": "Avaliar e Comentar",
        "ja": "評価とレビュー",
        "zh": "评级和审查",
        "ru": "Оценить и рецензировать",
        "ar": "التقييم والمراجعة",
        "hi": "रेट और समीक्षा करें",
        "sk": "Ohodnoťte a skúmajte"
    },
    "RATE_DESCRIPTION": {
        "en": "Rate your exchange partner to help build trust in the community and guide future users.",
        "es": "Califica a tu compañero de intercambio para ayudar a construir confianza en la comunidad y guiar a futuros usuarios.",
        "fr": "Notez votre partenaire d'échange pour aider à renforcer la confiance dans la communauté et guider les utilisateurs futurs.",
        "de": "Bewerten Sie Ihren Austauschegenossen, um Vertrauen in der Gemeinschaft aufzubauen und zukünftige Benutzer zu leiten.",
        "pt": "Avalie seu parceiro de troca para ajudar a construir confiança na comunidade e guiar usuários futuros.",
        "ja": "交換パートナーを評価して、コミュニティの信頼を構築し、将来のユーザーをガイドするのに役立ちます。",
        "zh": "对您的交换合作伙伴进行评分，以帮助建立社区信任并指导未来用户。",
        "ru": "Оцените вашего партнера по обмену, чтобы помочь укрепить доверие в сообществе и направить будущих пользователей.",
        "ar": "قيّم شريكك في التبادل لمساعدتك على بناء الثقة في المجتمع وتوجيه المستخدمين في المستقبل.",
        "hi": "अपने विनिमय भागीदार को रेट करें ताकि समुदाय में विश्वास बनाने और भविष्य के उपयोगकर्ताओं को मार्गदर्शन करने में मदद मिले।",
        "sk": "Ohodnoťte svojho partnera na výmenu, aby ste pomohli vybudovať dôveru v komunite a viesť budúcich používateľov."
    },
    "WHY_CHOOSE_NICE_TRADERS": {
        "en": "Why Choose Nice Traders?",
        "es": "¿Por qué elegir Nice Traders?",
        "fr": "Pourquoi choisir Nice Traders?",
        "de": "Warum Nice Traders wählen?",
        "pt": "Por que escolher Nice Traders?",
        "ja": "Nice Tradersを選ぶ理由は何ですか？",
        "zh": "为什么选择Nice Traders？",
        "ru": "Почему выбрать Nice Traders?",
        "ar": "لماذا تختار Nice Traders؟",
        "hi": "Nice Traders को क्यों चुनें?",
        "sk": "Prečo si vybrať Nice Traders?"
    },
    "SAVE_MONEY": {
        "en": "Save Money",
        "es": "Ahorrar dinero",
        "fr": "Économiser de l'argent",
        "de": "Sparen Sie Geld",
        "pt": "Economize dinheiro",
        "ja": "お金を節約",
        "zh": "省钱",
        "ru": "Сэкономить деньги",
        "ar": "توفير المال",
        "hi": "पैसा बचाएं",
        "sk": "Ušetrite peniaze"
    },
    "SAVE_MONEY_DESCRIPTION": {
        "en": "Banks and airport kiosks charge 5-15% in fees and markups. With Nice Traders, negotiate rates that work for both parties.",
        "es": "Los bancos y los quioscos del aeropuerto cobran comisiones y recargos del 5-15%. Con Nice Traders, negocia tasas que funcionen para ambas partes.",
        "fr": "Les banques et les kiosques aéroportuaires facturent des frais et des majorations de 5 à 15%. Avec Nice Traders, négociez des tarifs qui conviennent aux deux parties.",
        "de": "Banken und Flughafenkioske berechnen 5-15% an Gebühren und Aufschlägen. Mit Nice Traders verhandeln Sie Tarife, die für beide Seiten funktionieren.",
        "pt": "Bancos e quiosques de aeroporto cobram taxas de 5-15% e margens. Com Nice Traders, negocie taxas que funcionem para ambas as partes.",
        "ja": "銀行と空港のキオスクは手数料とマークアップで5～15％を請求します。Nice Tradersでは、両当事者に対応する料金を交渉してください。",
        "zh": "银行和机场亭收取5-15%的费用和加价。使用Nice Traders，协商对双方都有效的费率。",
        "ru": "Банки и аэропортовые киоски берут комиссионные и наценки в размере 5-15%. С Nice Traders вы можете договориться о ставках, которые будут работать для обеих сторон.",
        "ar": "تفرض البنوك وأكشاك المطارات رسوم وزيادات بنسبة 5-15٪. مع Nice Traders، تفاوض على أسعار تعمل لكلا الطرفين.",
        "hi": "बैंक और हवाई अड्डे की कियोस्क 5-15% शुल्क और मार्कअप लेते हैं। Nice Traders के साथ, उन दरों पर बातचीत करें जो दोनों पक्षों के लिए काम करती हैं।",
        "sk": "Banky a letiskové kinosky si účtujú poplatky a prirážky 5-15%. S Nice Traders vyjednajte sadzby, ktoré budú fungovať pre obe strany."
    },
    "FAST_AND_CONVENIENT": {
        "en": "Fast & Convenient",
        "es": "Rápido y Conveniente",
        "fr": "Rapide et Pratique",
        "de": "Schnell und Bequem",
        "pt": "Rápido e Conveniente",
        "ja": "高速で便利",
        "zh": "快速方便",
        "ru": "Быстро и удобно",
        "ar": "سريع وملائم",
        "hi": "तेजी से और सुविधाजनक",
        "sk": "Rýchle a pohodlné"
    },
    "FAST_DESCRIPTION": {
        "en": "Find currency exchanges happening near you right now. No need to drive to the bank or wait in line at the airport.",
        "es": "Encuentra cambios de divisas sucediendo cerca de ti ahora mismo. No necesitas ir al banco ni esperar en la fila del aeropuerto.",
        "fr": "Trouvez les échanges de devises qui se produisent près de vous maintenant. Pas besoin d'aller à la banque ou d'attendre à la queue de l'aéroport.",
        "de": "Finden Sie Währungsumtausche, die gerade in Ihrer Nähe stattfinden. Keine Notwendigkeit, zur Bank zu fahren oder am Flughafen Schlange zu stehen.",
        "pt": "Encontre trocas de moedas acontecendo perto de você agora. Não há necessidade de ir ao banco ou esperar na fila do aeroporto.",
        "ja": "今あなたの近くで行われている通貨交換を見つけてください。銀行に行ったり、空港で列に並んだりする必要はありません。",
        "zh": "找到现在在您附近发生的货币交换。无需驾驶到银行或在机场排队。",
        "ru": "Найдите обмены валют, которые происходят рядом с вами прямо сейчас. Не нужно ехать в банк или ждать в очереди в аэропорту.",
        "ar": "ابحث عن عمليات تبديل العملات التي تحدث بالقرب منك الآن. لا حاجة للذهاب إلى البنك أو الانتظار في الطابور في المطار.",
        "hi": "अभी आपके पास हो रहे मुद्रा विनिमय को खोजें। बैंक जाने या हवाई अड्डे पर कतार में प्रतीक्षा करने की आवश्यकता नहीं है।",
        "sk": "Nájdite výmeny mien, ktoré sa práve teraz dejú blízko vás. Nie je potrebné jazdiť do banky alebo čakať v rade na letisku."
    },
    "SUPPORT_YOUR_COMMUNITY": {
        "en": "Support Your Community",
        "es": "Apoya tu comunidad",
        "fr": "Soutenir votre communauté",
        "de": "Unterstützen Sie Ihre Gemeinde",
        "pt": "Apoie sua comunidade",
        "ja": "あなたのコミュニティをサポート",
        "zh": "支持你的社区",
        "ru": "Поддержите вашу общину",
        "ar": "ادعم مجتمعك",
        "hi": "अपने समुदाय का समर्थन करें",
        "sk": "Podporte svoju komunitu"
    },
    "COMMUNITY_DESCRIPTION": {
        "en": "Help fellow travelers while getting the currency you need. Build connections with people in your neighborhood.",
        "es": "Ayuda a otros viajeros mientras obtienes la moneda que necesitas. Construye conexiones con personas en tu barrio.",
        "fr": "Aidez vos compagnons de voyage tout en obtenant la devise dont vous avez besoin. Construisez des connexions avec les gens de votre quartier.",
        "de": "Helfen Sie anderen Reisenden, während Sie die benötigte Währung erhalten. Bauen Sie Verbindungen zu Menschen in Ihrer Nachbarschaft auf.",
        "pt": "Ajude colegas viajantes enquanto obtém a moeda de que precisa. Crie conexões com pessoas em seu bairro.",
        "ja": "必要な通貨を取得しながら他の旅行者を支援してください。あなたの近所の人々とのつながりを構築してください。",
        "zh": "在获得所需货币的同时帮助其他旅行者。与您所在社区的人建立联系。",
        "ru": "Помогите другим путешественникам, получая необходимую вам валюту. Установите связи с людьми в вашем районе.",
        "ar": "ساعد زملائك المسافرين بينما تحصل على العملة التي تحتاجها. بناء اتصالات مع الناس في حيك.",
        "hi": "आवश्यक मुद्रा प्राप्त करते समय अन्य यात्रियों को मदद करें। अपने पड़ोस में लोगों के साथ संबंध बनाएं।",
        "sk": "Pomôžte spoluputujúcim cestovateľom, keď získate potrebnú menu. Budujte spojenia s ľuďmi v komisáte."
    },
    "SAFE_AND_TRANSPARENT": {
        "en": "Safe & Transparent",
        "es": "Seguro y Transparente",
        "fr": "Sûr et Transparent",
        "de": "Sicher und transparent",
        "pt": "Seguro e Transparente",
        "ja": "安全で透明",
        "zh": "安全和透明",
        "ru": "Безопасно и прозрачно",
        "ar": "آمن وشفاف",
        "hi": "सुरक्षित और पारदर्शी",
        "sk": "Bezpečné a transparentné"
    },
    "SAFE_DESCRIPTION": {
        "en": "View user ratings, meet in public places, and communicate through our secure platform. Safety is our priority.",
        "es": "Ver calificaciones de usuarios, encontrarse en lugares públicos y comunicarse a través de nuestra plataforma segura. La seguridad es nuestra prioridad.",
        "fr": "Consultez les évaluations des utilisateurs, rencontrez-vous dans des lieux publics et communiquez via notre plateforme sécurisée. La sécurité est notre priorité.",
        "de": "Sehen Sie sich Benutzerbewertungen an, treffen Sie sich an öffentlichen Orten und kommunizieren Sie über unsere sichere Plattform. Sicherheit ist unsere Priorität.",
        "pt": "Visualize classificações de usuários, reúna-se em locais públicos e comunique-se através de nossa plataforma segura. A segurança é nossa prioridade.",
        "ja": "ユーザー評価を表示し、公共の場所で会い、当社のセキュアなプラットフォームで通信します。安全は私たちの優先事項です。",
        "zh": "查看用户评分，在公共场所见面，通过我们的安全平台进行通信。安全是我们的优先事项。",
        "ru": "Просмотрите рейтинги пользователей, встречайтесь в общественных местах и общайтесь через нашу безопасную платформу. Безопасность - наш приоритет.",
        "ar": "عرض تقييمات المستخدمين والالتقاء في الأماكن العامة والتواصل عبر منصتنا الآمنة. السلامة هي أولويتنا.",
        "hi": "उपयोगकर्ता रेटिंग देखें, सार्वजनिक स्थानों पर मिलें, और हमारे सुरक्षित प्लेटफॉर्म के माध्यम से संवाद करें। सुरक्षा हमारी प्राथमिकता है।",
        "sk": "Zobraziť hodnotenia používateľov, stretnúť sa na verejných miestach a komunikovať prostredníctvom našej bezpečnej platformy. Bezpečnosť je naša priorita."
    },
    "SAFETY_FIRST": {
        "en": "Safety First",
        "es": "La Seguridad Primero",
        "fr": "La Sécurité D'abord",
        "de": "Sicherheit An Erster Stelle",
        "pt": "Segurança em Primeiro Lugar",
        "ja": "安全第一",
        "zh": "安全第一",
        "ru": "Безопасность в первую очередь",
        "ar": "السلامة أولاً",
        "hi": "सुरक्षा पहले",
        "sk": "Bezpečnosť na prvom mieste"
    },
    "MEET_PUBLIC_PLACES": {
        "en": "Always meet in well-lit public places like coffee shops, bank lobbies, or shopping centers",
        "es": "Siempre reúnete en lugares públicos bien iluminados como cafeterías, vestíbulos de bancos o centros comerciales",
        "fr": "Rencontrez-vous toujours dans des lieux publics bien éclairés comme des cafés, des halls de banque ou des centres commerciaux",
        "de": "Treffen Sie sich immer an gut beleuchteten öffentlichen Orten wie Cafés, Bankhallen oder Einkaufszentren",
        "pt": "Sempre se reúna em locais públicos bem iluminados, como cafeterías, saguões de bancos ou shoppings",
        "ja": "カフェ、銀行ホール、ショッピングセンターなどの明るい公開場所で必ず会いましょう",
        "zh": "始终在咖啡馆、银行大堂或购物中心等照明良好的公共场所见面",
        "ru": "Всегда встречайтесь в хорошо освещенных общественных местах, таких как кофейни, вестибюли банков или торговые центры",
        "ar": "التقِ دائمًا في أماكن عامة مضاءة جيدًا مثل المقاهي وقاعات البنك أو مراكز التسوق",
        "hi": "कैफे, बैंक लॉबी या शॉपिंग सेंटर जैसी अच्छी तरह से रोशन सार्वजनिक जगहों पर हमेशा मिलें",
        "sk": "Vždy sa stretávajte na dobre osvetlených verejných miestach, ako sú kaviarne, banky alebo nákupné strediská"
    },
    "BRING_A_FRIEND": {
        "en": "Bring a friend if possible, especially for larger exchanges",
        "es": "Trae a un amigo si es posible, especialmente para cambios más grandes",
        "fr": "Apportez un ami si possible, surtout pour les échanges plus importants",
        "de": "Bringen Sie wenn möglich einen Freund mit, besonders bei größeren Austauschen",
        "pt": "Traga um amigo se possível, especialmente para trocas maiores",
        "ja": "可能であれば友人を持ってきてください。特に大きな交換の場合",
        "zh": "如果可能，请带上朋友，尤其是对于大型交易",
        "ru": "Если возможно, приведите друга, особенно для крупных обменов",
        "ar": "احضر صديقًا إن أمكن، خاصة بالنسبة للتبادلات الأكبر",
        "hi": "यदि संभव हो तो एक दोस्त को लाएं, विशेषकर बड़ी विनिमय के लिए",
        "sk": "Ak je to možné, doneste si priateľa, najmä pri väčších výmenách"
    },
    "VERIFY_CURRENCY": {
        "en": "Verify the authenticity of currency before completing the exchange",
        "es": "Verifica la autenticidad de la moneda antes de completar el cambio",
        "fr": "Vérifiez l'authenticité de la devise avant de terminer l'échange",
        "de": "Überprüfen Sie die Authentizität der Währung, bevor Sie den Austausch abschließen",
        "pt": "Verifique a autenticidade da moeda antes de concluir a troca",
        "ja": "交換を完了する前に通貨の真正性を確認してください",
        "zh": "在完成交易前验证货币的真实性",
        "ru": "Проверьте подлинность валюты перед завершением обмена",
        "ar": "تحقق من أصالة العملة قبل إكمال التبادل",
        "hi": "विनिमय को पूरा करने से पहले मुद्रा की प्रामाणिकता की जांच करें",
        "sk": "Pred dokončením výmeny skontrolujte pravosť meny"
    },
    "KEEP_COMMUNICATION": {
        "en": "Keep communication on our platform until you've successfully met",
        "es": "Mantén la comunicación en nuestra plataforma hasta que te hayas encontrado con éxito",
        "fr": "Gardez la communication sur notre plateforme jusqu'à ce que vous vous soyez rencontrés avec succès",
        "de": "Halten Sie die Kommunikation auf unserer Plattform, bis Sie sich erfolgreich getroffen haben",
        "pt": "Mantenha a comunicação em nossa plataforma até que você se tenha encontrado com sucesso",
        "ja": "正常に会うまでプラットフォームでのコミュニケーションを保ってください",
        "zh": "在成功会面之前，请在我们的平台上保持沟通",
        "ru": "Сохраняйте общение на нашей платформе до успешной встречи",
        "ar": "حافظ على التواصل على منصتنا حتى تلتقي بنجاح",
        "hi": "सफलतापूर्वक मिलने तक हमारे प्लेटफॉर्म पर संचार रखें",
        "sk": "Udržujte komunikáciu na našej platforme, kým sa neuvidia"
    },
    "MEET_DAYLIGHT": {
        "en": "Meet during daylight hours when possible",
        "es": "Reúnete durante las horas de luz cuando sea posible",
        "fr": "Rencontrez-vous pendant les heures de clarté quand possible",
        "de": "Treffen Sie sich wenn möglich während der Tageslichtstunden",
        "pt": "Reúna-se durante as horas de luz quando possível",
        "ja": "可能であれば昼間に会いましょう",
        "zh": "如果可能，在白天见面",
        "ru": "Встречайтесь в светлое время суток, когда это возможно",
        "ar": "التقِ خلال ساعات النهار عندما يكون ذلك ممكنًا",
        "hi": "जब संभव हो दिन के समय मिलें",
        "sk": "Ak je to možné, stretávajte sa v denných hodinách"
    },
    "NO_FINANCIAL_INFO": {
        "en": "Never share personal financial information or send money in advance",
        "es": "Nunca compartas información financiera personal ni envíes dinero por adelantado",
        "fr": "Ne partagez jamais vos informations financières personnelles ni n'envoyez d'argent à l'avance",
        "de": "Geben Sie niemals persönliche Finanzinformationen frei oder senden Sie Geld im Voraus",
        "pt": "Nunca compartilhe informações financeiras pessoais ou envie dinheiro antecipadamente",
        "ja": "個人の財務情報を共有したり、事前にお金を送ったりしないでください",
        "zh": "永远不要分享个人财务信息或提前汇款",
        "ru": "Никогда не делитесь личной финансовой информацией и не отправляйте деньги авансом",
        "ar": "لا تشارك أبدًا معلومات مالية شخصية أو تحول أموالًا مقدمًا",
        "hi": "कभी भी व्यक्तिगत वित्तीय जानकारी साझा न करें या पहले से पैसे न भेजें",
        "sk": "Nikdy nezdieľajte osobné finančné informácie ani neposielajte peniaze vopred"
    },
    "HOW_MUCH_DOES_IT_COST": {
        "en": "How Much Does It Cost?",
        "es": "¿Cuánto cuesta?",
        "fr": "Combien ça coûte?",
        "de": "Was kostet das?",
        "pt": "Quanto custa?",
        "ja": "いくらですか？",
        "zh": "费用是多少？",
        "ru": "Сколько это стоит?",
        "ar": "كم يكلف؟",
        "hi": "यह कितना खर्च करता है?",
        "sk": "Koľko to stojí?"
    },
    "CREATING_LISTINGS": {
        "en": "Creating Listings",
        "es": "Crear anuncios",
        "fr": "Créer des annonces",
        "de": "Erstellen von Anzeigen",
        "pt": "Criação de Anúncios",
        "ja": "リスティングの作成",
        "zh": "创建列表",
        "ru": "Создание объявлений",
        "ar": "إنشاء القوائم",
        "hi": "सूचियां बनाना",
        "sk": "Vytvorenie zoznamov"
    },
    "SEARCHING_LISTINGS": {
        "en": "Searching Listings",
        "es": "Búsqueda de anuncios",
        "fr": "Recherche d'annonces",
        "de": "Anzeigensuche",
        "pt": "Pesquisa de Anúncios",
        "ja": "リスティングを検索",
        "zh": "搜索列表",
        "ru": "Поиск объявлений",
        "ar": "البحث عن القوائم",
        "hi": "सूचियां खोजना",
        "sk": "Vyhľadávanie zoznamov"
    },
    "FREE": {
        "en": "Free",
        "es": "Gratis",
        "fr": "Gratuit",
        "de": "Kostenlos",
        "pt": "Gratuito",
        "ja": "無料",
        "zh": "免费",
        "ru": "Бесплатно",
        "ar": "مجاني",
        "hi": "मुफ़्त",
        "sk": "Bezplatne"
    },
    "CONTACT_ACCESS_FEE": {
        "en": "Contact Access Fee",
        "es": "Tarifa de Acceso de Contacto",
        "fr": "Frais d'Accès de Contact",
        "de": "Kontaktzugriffsgebühr",
        "pt": "Taxa de Acesso de Contato",
        "ja": "連絡先アクセス手数料",
        "zh": "联系方式访问费",
        "ru": "Плата за доступ к контактам",
        "ar": "رسوم الوصول المتصل",
        "hi": "संपर्क पहुंच शुल्क",
        "sk": "Poplatok za prístup ku kontaktom"
    },
    "CONTACT_FEE_PRICE": {
        "en": "$2.00",
        "es": "$2.00",
        "fr": "$2.00",
        "de": "$2.00",
        "pt": "$2.00",
        "ja": "$2.00",
        "zh": "$2.00",
        "ru": "$2.00",
        "ar": "$2.00",
        "hi": "$2.00",
        "sk": "$2.00"
    },
    "CONTACT_FEE_DESCRIPTION": {
        "en": "One-time fee to unlock contact info for each listing",
        "es": "Tarifa única para desbloquear la información de contacto de cada anuncio",
        "fr": "Frais uniques pour déverrouiller les informations de contact de chaque annonce",
        "de": "Einmalige Gebühr zum Entsperren von Kontaktinformationen für jede Anzeige",
        "pt": "Taxa única para desbloquear informações de contato para cada anúncio",
        "ja": "各リストの連絡先情報を確認するための1回限りの料金",
        "zh": "一次性费用以解锁每个列表的联系信息",
        "ru": "Единовременная плата за разблокировку контактной информации для каждого объявления",
        "ar": "رسم لمرة واحدة لفتح معلومات الاتصال لكل قائمة",
        "hi": "प्रत्येक सूची के लिए संपर्क जानकारी को अनलॉक करने के लिए एकबारी शुल्क",
        "sk": "Jednorazový poplatok za odomknutie kontaktných informácií pre každý zoznam"
    },
    "CONTACT_FEE_EXPLANATION": {
        "en": "The $2.00 contact fee helps prevent spam and ensures serious exchanges. Once paid, you have unlimited messaging with that person.",
        "es": "La tarifa de contacto de $2.00 ayuda a prevenir spam y garantiza cambios serios. Una vez pagada, tiene mensajería ilimitada con esa persona.",
        "fr": "Les frais de contact de 2,00 $ aident à prévenir le spam et assurent des échanges sérieux. Une fois payé, vous avez une messagerie illimitée avec cette personne.",
        "de": "Die Kontaktgebühr von 2,00 $ hilft, Spam zu verhindern und sicherzustellen, dass es sich um ernsthaften Austausch handelt. Nach Bezahlung haben Sie unbegrenzte Nachrichten mit dieser Person.",
        "pt": "A taxa de contato de $2.00 ajuda a prevenir spam e garante trocas sérias. Uma vez paga, você tem mensagens ilimitadas com essa pessoa.",
        "ja": "$2.00の連絡先料金はスパムを防止し、真摯な交換を保証します。支払い後、その人と無制限のメッセージングが可能になります。",
        "zh": "$2.00的联系费用有助于防止垃圾邮件并确保认真的交易。一旦支付，您可以与该人进行无限制的消息传递。",
        "ru": "Плата за контакт в размере 2,00 долл. США помогает предотвратить спам и обеспечить серьезный обмен. После оплаты у вас будет неограниченный обмен сообщениями с этим человеком.",
        "ar": "تساعد رسوم الاتصال البالغة 2.00 دولار على منع الرسائل غير المرغوب فيها وضمان التبادلات الجادة. بمجرد الدفع، يكون لديك رسائل غير محدودة مع هذا الشخص.",
        "hi": "$2.00 संपर्क शुल्क स्पैम को रोकने और गंभीर विनिमय सुनिश्चित करने में मदद करता है। एक बार भुगतान करने के बाद, आपके पास उस व्यक्ति के साथ असीमित मैसेजिंग है।",
        "sk": "Poplatok za kontakt 2,00 USD pomáha zabrániť spamu a zabezpečuje vážne výmeny. Po zaplatení máte neobmedzené posielanie správ s touto osobou."
    },
    "GET_STARTED": {
        "en": "Get Started",
        "es": "Empezar",
        "fr": "Commencer",
        "de": "Anfangen",
        "pt": "Começar",
        "ja": "始めましょう",
        "zh": "开始使用",
        "ru": "Начать",
        "ar": "ابدأ",
        "hi": "शुरू करो",
        "sk": "Začať"
    },
    "CTA_TAGLINE": {
        "en": "Join thousands of smart travelers saving money on currency exchange",
        "es": "Únete a miles de viajeros inteligentes que ahorran dinero en cambio de divisas",
        "fr": "Rejoignez des milliers de voyageurs intelligents qui économisent de l'argent sur l'échange de devises",
        "de": "Gesellen Sie sich Tausenden von klugen Reisenden an, die beim Währungsumtausch Geld sparen",
        "pt": "Junte-se a milhares de viajantes inteligentes que economizam dinheiro em câmbio de moedas",
        "ja": "通貨交換でお金を節約する何千人もの賢い旅行者に参加してください",
        "zh": "加入数千名聪明的旅行者，在货币兑换中节省资金",
        "ru": "Присоединяйтесь к тысячам умных путешественников, экономящих деньги при обмене валюты",
        "ar": "انضم إلى آلاف المسافرين الأذكياء الذين يوفرون أموالهم على صرف العملات الأجنبية",
        "hi": "मुद्रा विनिमय पर पैसा बचाने वाले हजारों स्मार्ट यात्रियों में शामिल हों",
        "sk": "Присоединитесь к tisícom inteligentných cestovateľov, ktorí ušetria peniaze na výmene meny"
    }
}

def main():
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        print("=== LEARN MORE VIEW KEYS MIGRATION ===\n")
        
        # Extract English translations first
        english_translations = {key: translations.get('en', '') for key, translations in LEARN_MORE_STRINGS.items()}
        
        # English
        english_count = 0
        for key, value in english_translations.items():
            cursor.execute("""
                INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s)
            """, (key, 'en', value, datetime.now(), datetime.now()))
            if cursor.rowcount > 0:
                english_count += 1
        connection.commit()
        print(f"✅ English: {english_count} keys inserted\n")
        
        # Other languages
        language_map = {
            'es': 'Spanish',
            'fr': 'French',
            'de': 'German',
            'pt': 'Portuguese',
            'ja': 'Japanese',
            'zh': 'Simplified Chinese',
            'ru': 'Russian',
            'ar': 'Arabic',
            'hi': 'Hindi',
            'sk': 'Slovak'
        }
        
        language_results = {}
        for lang_code in ['es', 'fr', 'de', 'pt', 'ja', 'zh', 'ru', 'ar', 'hi', 'sk']:
            inserted_count = 0
            for key, translations in LEARN_MORE_STRINGS.items():
                value = translations.get(lang_code, '')
                if value:
                    cursor.execute("""
                        INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (key, lang_code, value, datetime.now(), datetime.now()))
                    if cursor.rowcount > 0:
                        inserted_count += 1
            connection.commit()
            if inserted_count > 0:
                print(f"✅ {lang_code}: {inserted_count} keys inserted")
        
        print("\n✅ Migration completed!")
        return 0
        
    except Exception as e:
        print(f"❌ Error: {e}")
        connection.rollback()
        return 1
    finally:
        cursor.close()
        connection.close()

if __name__ == "__main__":
    sys.exit(main())
