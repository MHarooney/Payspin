import 'package:flutter/material.dart';

/// App strings for en / nl / de / ar. Loaded via [Localizations.of].
class PayspinLocalizations {
  const PayspinLocalizations(this.locale);

  final Locale locale;

  static PayspinLocalizations of(BuildContext context) {
    return Localizations.of<PayspinLocalizations>(context, PayspinLocalizations)!;
  }

  /// Null-safe lookup — returns `null` when no delegate is in the tree (e.g.
  /// widgets pumped in isolation by tests). Use for non-critical strings only.
  static PayspinLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<PayspinLocalizations>(context, PayspinLocalizations);
  }

  static const LocalizationsDelegate<PayspinLocalizations> delegate =
      _PayspinLocalizationsDelegate();

  String _pick(Map<String, String> values) =>
      values[locale.languageCode] ?? values['en']!;

  // —— Profile & settings ——
  String get preferences => _pick({
        'en': 'Preferences',
        'nl': 'Voorkeuren',
        'de': 'Einstellungen',
        'ar': 'التفضيلات',
      });

  String get quickSettingsTooltip => _pick({
        'en': 'Appearance & language',
        'nl': 'Weergave & taal',
        'de': 'Darstellung & Sprache',
        'ar': 'المظهر واللغة',
      });

  String themeModeLabel(String mode) => switch (mode) {
        'dark' => themeDark,
        'light' => themeLight,
        _ => themeSystem,
      };

  String get language => _pick({
        'en': 'Language',
        'nl': 'Taal',
        'de': 'Sprache',
        'ar': 'اللغة',
      });

  String get appearance => _pick({
        'en': 'Appearance',
        'nl': 'Weergave',
        'de': 'Darstellung',
        'ar': 'المظهر',
      });

  String get themeSystem => _pick({
        'en': 'System',
        'nl': 'Systeem',
        'de': 'System',
        'ar': 'النظام',
      });

  String get themeDark => _pick({
        'en': 'Dark',
        'nl': 'Donker',
        'de': 'Dunkel',
        'ar': 'داكن',
      });

  String get themeLight => _pick({
        'en': 'Light',
        'nl': 'Licht',
        'de': 'Hell',
        'ar': 'فاتح',
      });

  String languageName(String code) => switch (code) {
        'nl' => 'Nederlands',
        'de' => 'Deutsch',
        'ar' => 'العربية',
        _ => 'English',
      };

  // —— QR / payment links ——
  String get scanToPay => _pick({
        'en': 'Scan to pay',
        'nl': 'Scan om te betalen',
        'de': 'Zum Bezahlen scannen',
        'ar': 'امسح للدفع',
      });

  String viaPayspin(String amountLabel) => _pick({
        'en': '$amountLabel via Payspin',
        'nl': '$amountLabel via Payspin',
        'de': '$amountLabel über Payspin',
        'ar': '$amountLabel عبر Payspin',
      });

  String get shareAgain => _pick({
        'en': 'Share again',
        'nl': 'Opnieuw delen',
        'de': 'Erneut teilen',
        'ar': 'شارك مرة أخرى',
      });

  String get expired => _pick({
        'en': 'Expired',
        'nl': 'Verlopen',
        'de': 'Abgelaufen',
        'ar': 'منتهي',
      });

  String get validLessThanDay => _pick({
        'en': 'Valid for less than a day',
        'nl': 'Nog minder dan een dag geldig',
        'de': 'Noch weniger als ein Tag gültig',
        'ar': 'صالح لأقل من يوم',
      });

  String validForDays(int days) {
    if (days == 1) {
      return _pick({
        'en': 'Valid for 1 more day',
        'nl': 'Nog 1 dag geldig',
        'de': 'Noch 1 Tag gültig',
        'ar': 'صالح ليوم واحد آخر',
      });
    }
    return _pick({
      'en': 'Valid for $days more days',
      'nl': 'Nog $days dagen geldig',
      'de': 'Noch $days Tage gültig',
      'ar': 'صالح لـ $days أيام أخرى',
    });
  }

  String get qrSemanticsLabel => _pick({
        'en': 'Payspin payment QR code',
        'nl': 'Payspin-betaal QR-code',
        'de': 'Payspin-Zahlungs-QR-Code',
        'ar': 'رمز QR للدفع عبر Payspin',
      });

  // —— Link status ——
  String linkStatus(String status) => switch (status) {
        'ACTIVE' => _pick({
            'en': 'Active',
            'nl': 'Actief',
            'de': 'Aktiv',
            'ar': 'نشط',
          }),
        'COLLECTING' => _pick({
            'en': 'Collecting',
            'nl': 'Verzamelen',
            'de': 'Sammeln',
            'ar': 'قيد التحصيل',
          }),
        'SETTLED' => _pick({
            'en': 'Paid',
            'nl': 'Betaald',
            'de': 'Bezahlt',
            'ar': 'مدفوع',
          }),
        'EXPIRED' => expired,
        'CANCELLED' => _pick({
            'en': 'Cancelled',
            'nl': 'Geannuleerd',
            'de': 'Storniert',
            'ar': 'ملغى',
          }),
        _ => status,
      };

  String paidCount(int count) => _pick({
        'en': 'Paid ${count}x',
        'nl': '${count}x betaald',
        'de': '${count}x bezahlt',
        'ar': 'دُفع $count مرات',
      });

  // —— Welcome & auth ——
  String get tagline => _pick({
        'en': 'Send and request money.\nYour money, your community, your peace of mind.',
        'nl': 'Geld versturen en vragen.\nJouw geld, jouw community, jouw gemoedsrust.',
        'de': 'Geld senden und anfordern.\nDein Geld, deine Community, deine Ruhe.',
        'ar': 'أرسل واطلب الأموال.\nأموالك، مجتمعك، وراحة بالك.',
      });

  String get getStarted => _pick({
        'en': 'Get started',
        'nl': 'Aan de slag',
        'de': 'Loslegen',
        'ar': 'ابدأ',
      });

  String get alreadyHaveAccount => _pick({
        'en': 'Already have an account? ',
        'nl': 'Heb je al een account? ',
        'de': 'Bereits ein Konto? ',
        'ar': 'لديك حساب بالفعل؟ ',
      });

  String get logIn => _pick({
        'en': 'Log in',
        'nl': 'Inloggen',
        'de': 'Anmelden',
        'ar': 'تسجيل الدخول',
      });

  String get logInTitle => _pick({
        'en': 'Log In',
        'nl': 'Inloggen',
        'de': 'Anmelden',
        'ar': 'تسجيل الدخول',
      });

  String get logInSubtitle => _pick({
        'en': 'Use your email and password',
        'nl': 'Gebruik je e-mail en wachtwoord',
        'de': 'E-Mail und Passwort verwenden',
        'ar': 'استخدم بريدك الإلكتروني وكلمة المرور',
      });

  String get email => _pick({
        'en': 'Email',
        'nl': 'E-mail',
        'de': 'E-Mail',
        'ar': 'البريد الإلكتروني',
      });

  String get password => _pick({
        'en': 'Password',
        'nl': 'Wachtwoord',
        'de': 'Passwort',
        'ar': 'كلمة المرور',
      });

  String get signingIn => _pick({
        'en': 'Signing in…',
        'nl': 'Bezig met inloggen…',
        'de': 'Anmeldung…',
        'ar': 'جارٍ تسجيل الدخول…',
      });

  // —— Shell / home ——
  String get navHome => _pick({
        'en': 'Home',
        'nl': 'Home',
        'de': 'Start',
        'ar': 'الرئيسية',
      });

  String get navScanQr => _pick({
        'en': 'Scan QR',
        'nl': 'QR scannen',
        'de': 'QR scannen',
        'ar': 'مسح QR',
      });

  String get navProfile => _pick({
        'en': 'Profile',
        'nl': 'Profiel',
        'de': 'Profil',
        'ar': 'الملف الشخصي',
      });

  String get tabTikkies => _pick({
        'en': 'Tikkies',
        'nl': 'Tikkies',
        'de': 'Tikkies',
        'ar': 'تيكّي',
      });

  String get tabDeals => _pick({
        'en': 'Deals',
        'nl': 'Deals',
        'de': 'Deals',
        'ar': 'عروض',
      });

  String get tabGroepies => _pick({
        'en': 'Groepies',
        'nl': 'Groepies',
        'de': 'Groepies',
        'ar': 'مجموعات',
      });

  String get searchTikkies => _pick({
        'en': 'Search Tikkies…',
        'nl': 'Zoek Tikkies…',
        'de': 'Tikkies suchen…',
        'ar': 'ابحث في تيكّي…',
      });

  String get noSearchResults => _pick({
        'en': 'No Tikkies match your search.',
        'nl': 'Geen Tikkies gevonden voor je zoekopdracht.',
        'de': 'Keine Tikkies für deine Suche.',
        'ar': 'لا توجد تيكّي تطابق بحثك.',
      });

  String get errorTitle => _pick({
        'en': 'Something went wrong',
        'nl': 'Er ging iets mis',
        'de': 'Etwas ist schiefgelaufen',
        'ar': 'حدث خطأ ما',
      });

  String get tryAgain => _pick({
        'en': 'Try again',
        'nl': 'Opnieuw proberen',
        'de': 'Erneut versuchen',
        'ar': 'حاول مرة أخرى',
      });

  String get emptyTikkiesTitle => _pick({
        'en': 'Time for your first Tikkie',
        'nl': 'Tijd voor je eerste Tikkie',
        'de': 'Zeit für dein erstes Tikkie',
        'ar': 'حان وقت أول تيكّي',
      });

  String get emptyTikkiesSubtitle => _pick({
        'en': 'Request money from friends in seconds — they pay straight from their bank.',
        'nl': 'Vraag geld aan van vrienden — ze betalen direct vanuit hun bank.',
        'de': 'Fordere Geld von Freunden an — sie zahlen direkt von ihrer Bank.',
        'ar': 'اطلب المال من الأصدقاء — يدفعون مباشرة من بنكهم.',
      });

  String get createTikkie => _pick({
        'en': 'Create a Tikkie',
        'nl': 'Maak een Tikkie',
        'de': 'Tikkie erstellen',
        'ar': 'إنشاء تيكّي',
      });

  String get loading => _pick({
        'en': 'Loading',
        'nl': 'Laden',
        'de': 'Laden',
        'ar': 'جارٍ التحميل',
      });

  // —— Home dashboard ——
  String homeGreeting(int hour) {
    if (hour < 12) {
      return _pick({
        'en': 'Good morning',
        'nl': 'Goedemorgen',
        'de': 'Guten Morgen',
        'ar': 'صباح الخير',
      });
    }
    if (hour < 18) {
      return _pick({
        'en': 'Good afternoon',
        'nl': 'Goedemiddag',
        'de': 'Guten Tag',
        'ar': 'مساء الخير',
      });
    }
    return _pick({
      'en': 'Good evening',
      'nl': 'Goedenavond',
      'de': 'Guten Abend',
      'ar': 'مساء الخير',
    });
  }

  // Quick actions.
  String get quickActionNewLink => _pick({
        'en': 'New link',
        'nl': 'Nieuwe link',
        'de': 'Neuer Link',
        'ar': 'رابط جديد',
      });

  String get quickActionScan => _pick({
        'en': 'Scan',
        'nl': 'Scannen',
        'de': 'Scannen',
        'ar': 'مسح',
      });

  String get quickActionShareLast => _pick({
        'en': 'Share last',
        'nl': 'Laatste delen',
        'de': 'Letzten teilen',
        'ar': 'مشاركة الأخير',
      });

  String get quickActionShareLastHint => _pick({
        'en': 'No payable link to share yet',
        'nl': 'Nog geen betaalbare link om te delen',
        'de': 'Noch kein zahlbarer Link zum Teilen',
        'ar': 'لا يوجد رابط قابل للدفع للمشاركة بعد',
      });

  String get quickActionGroepies => _pick({
        'en': 'Groepies',
        'nl': 'Groepies',
        'de': 'Groepies',
        'ar': 'مجموعات',
      });

  // Section headers.
  String get sectionActiveRequest => _pick({
        'en': 'Active request',
        'nl': 'Actief verzoek',
        'de': 'Aktive Anfrage',
        'ar': 'طلب نشط',
      });

  String get sectionFavorites => _pick({
        'en': 'Favorites',
        'nl': 'Favorieten',
        'de': 'Favoriten',
        'ar': 'المفضلة',
      });

  String get sectionRecommended => _pick({
        'en': 'Recommended for you',
        'nl': 'Aanbevolen voor jou',
        'de': 'Für dich empfohlen',
        'ar': 'موصى به لك',
      });

  String get sectionRecentLinks => _pick({
        'en': 'Recent links',
        'nl': 'Recente links',
        'de': 'Letzte Links',
        'ar': 'الروابط الأخيرة',
      });

  /// "2 of 3 paid" progress for a capped MULTI link.
  String paidOfTotal(int paid, int total) => _pick({
        'en': '$paid of $total paid',
        'nl': '$paid van $total betaald',
        'de': '$paid von $total bezahlt',
        'ar': 'دُفع $paid من $total',
      });

  String receivedCount(int count) => _pick({
        'en': '$count received',
        'nl': '$count ontvangen',
        'de': '$count erhalten',
        'ar': 'تم استلام $count',
      });

  // Recommended cards.
  String get recRequestAgainTitle => _pick({
        'en': 'Request again',
        'nl': 'Opnieuw aanvragen',
        'de': 'Erneut anfordern',
        'ar': 'اطلب مرة أخرى',
      });

  String recRequestAgainSubtitle(String description) => _pick({
        'en': 'Start a similar request to "$description".',
        'nl': 'Start een vergelijkbaar verzoek voor "$description".',
        'de': 'Starte eine ähnliche Anfrage zu "$description".',
        'ar': 'ابدأ طلبًا مشابهًا لـ "$description".',
      });

  String get recGroepiesTitle => _pick({
        'en': 'Split with Groepies',
        'nl': 'Splitsen met Groepies',
        'de': 'Mit Groepies teilen',
        'ar': 'قسّم مع Groepies',
      });

  String get recGroepiesSubtitle => _pick({
        'en': 'Track shared expenses with friends.',
        'nl': 'Houd gedeelde kosten bij met vrienden.',
        'de': 'Behalte geteilte Ausgaben mit Freunden im Blick.',
        'ar': 'تتبّع المصاريف المشتركة مع الأصدقاء.',
      });

  String get recDinnerTitle => _pick({
        'en': 'Create a dinner split',
        'nl': 'Maak een dinersplit',
        'de': 'Rechnung fürs Essen teilen',
        'ar': 'أنشئ تقسيم عشاء',
      });

  String get recDinnerSubtitle => _pick({
        'en': 'Share one bill across the whole table.',
        'nl': 'Deel één rekening met de hele tafel.',
        'de': 'Teile eine Rechnung mit dem ganzen Tisch.',
        'ar': 'شارك فاتورة واحدة مع الطاولة كاملة.',
      });

  // Long-press / row power actions.
  String get addToFavorites => _pick({
        'en': 'Add to favorites',
        'nl': 'Aan favorieten toevoegen',
        'de': 'Zu Favoriten hinzufügen',
        'ar': 'أضف إلى المفضلة',
      });

  String get removeFromFavorites => _pick({
        'en': 'Remove from favorites',
        'nl': 'Uit favorieten verwijderen',
        'de': 'Aus Favoriten entfernen',
        'ar': 'إزالة من المفضلة',
      });

  String get copyLink => _pick({
        'en': 'Copy link',
        'nl': 'Link kopiëren',
        'de': 'Link kopieren',
        'ar': 'نسخ الرابط',
      });

  String get linkCopied => _pick({
        'en': 'Link copied',
        'nl': 'Link gekopieerd',
        'de': 'Link kopiert',
        'ar': 'تم نسخ الرابط',
      });

  String get shareLink => _pick({
        'en': 'Share link',
        'nl': 'Link delen',
        'de': 'Link teilen',
        'ar': 'مشاركة الرابط',
      });

  String get favoritesFull => _pick({
        'en': 'You can pin up to 8 favorites.',
        'nl': 'Je kunt maximaal 8 favorieten vastzetten.',
        'de': 'Du kannst bis zu 8 Favoriten anheften.',
        'ar': 'يمكنك تثبيت 8 مفضلات كحد أقصى.',
      });

  // —— Intro storyboard ——
  String get introSkip => _pick({
        'en': 'Skip',
        'nl': 'Overslaan',
        'de': 'Überspringen',
        'ar': 'تخطٍّ',
      });

  String get introNext => _pick({
        'en': 'Next',
        'nl': 'Volgende',
        'de': 'Weiter',
        'ar': 'التالي',
      });

  String get introGetStarted => _pick({
        'en': 'Get started',
        'nl': 'Aan de slag',
        'de': 'Loslegen',
        'ar': 'ابدأ',
      });

  String introSceneTitle(int i) => _pick(switch (i) {
        1 => {
            'en': 'Split bills without the friction',
            'nl': 'Reken af zonder gedoe',
            'de': 'Rechnungen teilen ohne Reibung',
            'ar': 'قسّم الفواتير بلا عناء',
          },
        2 => {
            'en': 'Request across borders',
            'nl': 'Vraag over de grens',
            'de': 'Fordere über Grenzen hinweg',
            'ar': 'اطلب عبر الحدود',
          },
        3 => {
            'en': 'Paid in one tap',
            'nl': 'Betaald met één tik',
            'de': 'Bezahlt mit einem Tipp',
            'ar': 'الدفع بلمسة واحدة',
          },
        4 => {
            'en': 'Easy. Quick. Free. All over Europe.',
            'nl': 'Makkelijk. Snel. Gratis. In heel Europa.',
            'de': 'Einfach. Schnell. Kostenlos. In ganz Europa.',
            'ar': 'سهل. سريع. مجاني. في كل أوروبا.',
          },
        _ => {
            'en': 'Built for everyone',
            'nl': 'Voor iedereen gemaakt',
            'de': 'Für alle gemacht',
            'ar': 'مصمم للجميع',
          },
      });

  String introSceneBody(int i) => _pick(switch (i) {
        1 => {
            'en': 'Turn any invoice into a payment link — free, instant, across Europe.',
            'nl': 'Maak van elke rekening een betaallink — gratis, direct, in heel Europa.',
            'de': 'Verwandle jede Rechnung in einen Zahlungslink — kostenlos, sofort, europaweit.',
            'ar': 'حوّل أي فاتورة إلى رابط دفع — مجانًا وفوريًا في أنحاء أوروبا.',
          },
        2 => {
            'en': 'Send from Germany. Get paid in the Netherlands, France, Spain, and more.',
            'nl': 'Verstuur vanuit Duitsland. Word betaald in Nederland, Frankrijk, Spanje en meer.',
            'de': 'Sende aus Deutschland. Werde in den Niederlanden, Frankreich, Spanien und mehr bezahlt.',
            'ar': 'أرسل من ألمانيا. واحصل على أموالك في هولندا وفرنسا وإسبانيا وغيرها.',
          },
        3 => {
            'en': 'Recipients pay from their own bank — no app install, no signup.',
            'nl': 'Ontvangers betalen vanuit hun eigen bank — geen app, geen account.',
            'de': 'Empfänger zahlen von ihrer eigenen Bank — ohne App, ohne Registrierung.',
            'ar': 'يدفع المستلمون من بنكهم — دون تطبيق ودون تسجيل.',
          },
        4 => {
            'en': 'The simplest way to settle small debts.',
            'nl': 'De simpelste manier om kleine schulden te vereffenen.',
            'de': 'Der einfachste Weg, kleine Schulden zu begleichen.',
            'ar': 'أبسط طريقة لتسوية الديون الصغيرة.',
          },
        _ => {
            'en': 'Photographers, tradespeople, freelancers — anyone who needs to get paid.',
            'nl': 'Fotografen, vakmensen, freelancers — iedereen die betaald moet worden.',
            'de': 'Fotografen, Handwerker, Freelancer — alle, die bezahlt werden müssen.',
            'ar': 'مصورون، حرفيون، مستقلون — كل من يحتاج إلى أن يُدفع له.',
          },
      });

  String introValueWord(int i) => _pick(switch (i) {
        0 => {'en': 'Easy', 'nl': 'Makkelijk', 'de': 'Einfach', 'ar': 'سهل'},
        1 => {'en': 'Quick', 'nl': 'Snel', 'de': 'Schnell', 'ar': 'سريع'},
        2 => {'en': 'Free', 'nl': 'Gratis', 'de': 'Kostenlos', 'ar': 'مجاني'},
        _ => {'en': 'All over Europe', 'nl': 'Heel Europa', 'de': 'Ganz Europa', 'ar': 'كل أوروبا'},
      });

  // —— Notifications ——
  String get notificationsTitle => _pick({
        'en': 'Notifications',
        'nl': 'Meldingen',
        'de': 'Benachrichtigungen',
        'ar': 'الإشعارات',
      });

  String get markAllRead => _pick({
        'en': 'Mark all read',
        'nl': 'Alles als gelezen',
        'de': 'Alle als gelesen',
        'ar': 'تعليم الكل كمقروء',
      });

  String get noNotifications => _pick({
        'en': 'No notifications yet',
        'nl': 'Nog geen meldingen',
        'de': 'Noch keine Benachrichtigungen',
        'ar': 'لا توجد إشعارات بعد',
      });

  // —— Send flow ——
  String get sendAmountQuestion => _pick({
        'en': "What's the amount?",
        'nl': 'Wat is het bedrag?',
        'de': 'Wie hoch ist der Betrag?',
        'ar': 'ما هو المبلغ؟',
      });

  String get sendMaxHint => _pick({
        'en': 'You can request back a maximum of €950.',
        'nl': 'Je kunt maximaal €950 terugvragen.',
        'de': 'Du kannst maximal €950 zurückfordern.',
        'ar': 'يمكنك طلب 950 يورو كحد أقصى.',
      });

  String get sendOpenAmountToggle => _pick({
        'en': 'Payer may choose amount',
        'nl': 'Betaler mag bedrag kiezen',
        'de': 'Zahler kann Betrag wählen',
        'ar': 'يمكن للدافع اختيار المبلغ',
      });

  String get sendOpenAmount => _pick({
        'en': 'Open amount',
        'nl': 'Open bedrag',
        'de': 'Offener Betrag',
        'ar': 'مبلغ مفتوح',
      });

  String get sendWhatFor => _pick({
        'en': 'What is it for?',
        'nl': 'Waarvoor is het?',
        'de': 'Wofür ist es?',
        'ar': 'لأجل ماذا؟',
      });

  String sendRequesting(String amountLabel) => _pick({
        'en': 'Requesting $amountLabel',
        'nl': '$amountLabel aanvragen',
        'de': 'Fordere $amountLabel an',
        'ar': 'طلب $amountLabel',
      });

  String get sendForHint => _pick({
        'en': 'E.g. Dinner',
        'nl': 'Bijv. Diner',
        'de': 'z. B. Abendessen',
        'ar': 'مثال: العشاء',
      });

  String sendCharsLeft(int count) => _pick({
        'en': '$count left',
        'nl': '$count over',
        'de': 'noch $count',
        'ar': 'بقي $count',
      });

  String get sendViaWhatsApp => _pick({
        'en': 'Share via WhatsApp',
        'nl': 'Deel via WhatsApp',
        'de': 'Über WhatsApp teilen',
        'ar': 'مشاركة عبر واتساب',
      });

  String get payInto => _pick({
        'en': 'Pay into',
        'nl': 'Betaal naar',
        'de': 'Zahlung an',
        'ar': 'الدفع إلى',
      });

  String get change => _pick({
        'en': 'Change',
        'nl': 'Wijzig',
        'de': 'Ändern',
        'ar': 'تغيير',
      });

  // —— Scan ——
  String get scanTitle => _pick({
        'en': 'Scan QR',
        'nl': 'QR scannen',
        'de': 'QR scannen',
        'ar': 'مسح رمز QR',
      });

  String get scanHint => _pick({
        'en': 'Point your camera at a Payspin QR code',
        'nl': 'Richt je camera op een Payspin QR-code',
        'de': 'Richte die Kamera auf einen Payspin-QR-Code',
        'ar': 'وجّه الكاميرا نحو رمز QR الخاص بـ Payspin',
      });

  String get scanCardTitle => _pick({
        'en': 'Scan a Payspin QR code',
        'nl': 'Scan een Payspin QR-code',
        'de': 'Scanne einen Payspin-QR-Code',
        'ar': 'امسح رمز QR الخاص بـ Payspin',
      });

  String get scanCardBody => _pick({
        'en': 'Pay your friends without sending links, and more.',
        'nl': 'Betaal vrienden zonder links te sturen, en meer.',
        'de': 'Bezahle Freunde ohne Links zu senden, und mehr.',
        'ar': 'ادفع لأصدقائك دون إرسال روابط، والمزيد.',
      });

  String get scanOk => _pick({
        'en': 'OK, nice!',
        'nl': 'Oké, mooi!',
        'de': 'Alles klar!',
        'ar': 'حسنًا، رائع!',
      });

  // —— Lock screen ——
  String get lockTitle => _pick({
        'en': 'Enter your passcode',
        'nl': 'Voer je toegangscode in',
        'de': 'Gib deinen Code ein',
        'ar': 'أدخل رمز المرور',
      });

  String get lockWrong => _pick({
        'en': 'Wrong passcode, try again',
        'nl': 'Verkeerde code, probeer opnieuw',
        'de': 'Falscher Code, versuche es erneut',
        'ar': 'رمز خاطئ، حاول مرة أخرى',
      });

  // —— Profile ——
  String get helpSupport => _pick({
        'en': 'Help & support',
        'nl': 'Help & ondersteuning',
        'de': 'Hilfe & Support',
        'ar': 'المساعدة والدعم',
      });

  String get version => _pick({
        'en': 'Version',
        'nl': 'Versie',
        'de': 'Version',
        'ar': 'الإصدار',
      });

  // —— Support ——
  String get supportTitle => _pick({
        'en': 'Help & support',
        'nl': 'Help & ondersteuning',
        'de': 'Hilfe & Support',
        'ar': 'المساعدة والدعم',
      });

  String get supportNewRequest => _pick({
        'en': 'New request',
        'nl': 'Nieuw verzoek',
        'de': 'Neue Anfrage',
        'ar': 'طلب جديد',
      });

  String get supportContactSupport => _pick({
        'en': 'Contact support',
        'nl': 'Contact opnemen',
        'de': 'Support kontaktieren',
        'ar': 'تواصل مع الدعم',
      });

  String get supportEmptyTitle => _pick({
        'en': 'How can we help?',
        'nl': 'Hoe kunnen we helpen?',
        'de': 'Wie können wir helfen?',
        'ar': 'كيف يمكننا المساعدة؟',
      });

  String get supportEmptySubtitle => _pick({
        'en': 'Start a conversation and our team will get back to you.',
        'nl': 'Begin een gesprek en ons team neemt contact met je op.',
        'de': 'Starte ein Gespräch und unser Team meldet sich bei dir.',
        'ar': 'ابدأ محادثة وسيقوم فريقنا بالرد عليك.',
      });

  String get supportSlaHint => _pick({
        'en': 'We typically reply within a few hours.',
        'nl': 'We reageren meestal binnen een paar uur.',
        'de': 'Wir antworten in der Regel innerhalb weniger Stunden.',
        'ar': 'نرد عادةً خلال بضع ساعات.',
      });

  String get supportTopicQuestion => _pick({
        'en': 'What do you need help with?',
        'nl': 'Waar heb je hulp bij nodig?',
        'de': 'Wobei brauchst du Hilfe?',
        'ar': 'بماذا تحتاج المساعدة؟',
      });

  String get supportMessageHint => _pick({
        'en': 'Describe your issue…',
        'nl': 'Beschrijf je probleem…',
        'de': 'Beschreibe dein Anliegen…',
        'ar': 'صف مشكلتك…',
      });

  String get supportReplyHint => _pick({
        'en': 'Type a message…',
        'nl': 'Typ een bericht…',
        'de': 'Nachricht schreiben…',
        'ar': 'اكتب رسالة…',
      });

  String get supportSend => _pick({
        'en': 'Send',
        'nl': 'Versturen',
        'de': 'Senden',
        'ar': 'إرسال',
      });

  String get supportSendMessage => _pick({
        'en': 'Send message',
        'nl': 'Bericht versturen',
        'de': 'Nachricht senden',
        'ar': 'إرسال الرسالة',
      });

  String get supportResolvedBanner => _pick({
        'en': 'This request was marked resolved.',
        'nl': 'Dit verzoek is opgelost.',
        'de': 'Diese Anfrage wurde als gelöst markiert.',
        'ar': 'تم وضع علامة على هذا الطلب كمحلول.',
      });

  String get supportSendAnother => _pick({
        'en': 'Send another message',
        'nl': 'Nog een bericht sturen',
        'de': 'Weitere Nachricht senden',
        'ar': 'إرسال رسالة أخرى',
      });

  String get supportNeedHelp => _pick({
        'en': 'Need help with this link?',
        'nl': 'Hulp nodig met deze link?',
        'de': 'Brauchst du Hilfe mit diesem Link?',
        'ar': 'هل تحتاج مساعدة بخصوص هذا الرابط؟',
      });

  String get supportTeam => _pick({
        'en': 'Support',
        'nl': 'Support',
        'de': 'Support',
        'ar': 'الدعم',
      });

  String supportCategory(String category) => switch (category) {
        'PAYMENT' => _pick({'en': 'Payment issue', 'nl': 'Betaalprobleem', 'de': 'Zahlungsproblem', 'ar': 'مشكلة دفع'}),
        'ACCOUNT' => _pick({'en': 'Account', 'nl': 'Account', 'de': 'Konto', 'ar': 'الحساب'}),
        'CIRCLE' => _pick({'en': 'Circle', 'nl': 'Circle', 'de': 'Circle', 'ar': 'الدائرة'}),
        _ => _pick({'en': 'Other', 'nl': 'Overig', 'de': 'Sonstiges', 'ar': 'أخرى'}),
      };
}

class _PayspinLocalizationsDelegate
    extends LocalizationsDelegate<PayspinLocalizations> {
  const _PayspinLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'nl', 'de', 'ar'].contains(locale.languageCode);

  @override
  Future<PayspinLocalizations> load(Locale locale) async {
    return PayspinLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<PayspinLocalizations> old) =>
      false;
}

extension PayspinL10nContext on BuildContext {
  PayspinLocalizations get l10n => PayspinLocalizations.of(this);
}
