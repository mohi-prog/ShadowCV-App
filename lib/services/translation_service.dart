import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

class AppTranslation {
  static String currentLang = 'English';

  static final Map<String, Map<String, String>> texts = {
    // --- Allgemeine Wörter ---
    'Email': {
      'English': 'Email',
      'Deutsch': 'E-Mail',
      'Español': 'Correo electrónico',
    },
    'Password': {
      'English': 'Password',
      'Deutsch': 'Passwort',
      'Español': 'Contraseña',
    },
    'or': {'English': 'or', 'Deutsch': 'oder', 'Español': 'o'},
    'Continue': {
      'English': 'Continue',
      'Deutsch': 'Weiter',
      'Español': 'Continuar',
    },
    'Cancel': {
      'English': 'Cancel',
      'Deutsch': 'Abbrechen',
      'Español': 'Cancelar',
    },

    // --- Onboarding ---
    'Skip': {'English': 'Skip', 'Deutsch': 'Überspringen', 'Español': 'Omitir'},
    'Get Started': {
      'English': 'Get Started',
      'Deutsch': 'Loslegen',
      'Español': 'Empezar',
    },
    'Select Language': {
      'English': 'Select Language',
      'Deutsch': 'Sprache wählen',
      'Español': 'Seleccionar idioma',
    },
    'Why Your Application Fails': {
      'English': 'Why Your Application Fails',
      'Deutsch': 'Warum deine Bewerbung scheitert',
      'Español': 'Por qué falla tu solicitud',
    },
    '75% of applications are automatically rejected – because of name, age, university, gaps. No one tells you why.': {
      'English':
          '75% of applications are automatically rejected – because of name, age, university, gaps. No one tells you why.',
      'Deutsch':
          '75% der Bewerbungen werden abgelehnt – wegen Name, Alter, Lücken. Niemand sagt dir warum.',
      'Español':
          'El 75% de las solicitudes son rechazadas por nombre, edad, vacíos. Nadie te dice por qué.',
    },
    'ShadowCV Analyzes Your CV': {
      'English': 'ShadowCV Analyzes Your CV',
      'Deutsch': 'ShadowCV analysiert deinen CV',
      'Español': 'ShadowCV analiza tu CV',
    },
    'Upload your CV. AI checks it against 50+ ATS algorithms and shows exactly what needs improvement.': {
      'English':
          'Upload your CV. AI checks it against 50+ ATS algorithms and shows exactly what needs improvement.',
      'Deutsch':
          'Lade deinen CV hoch. Die KI prüft ihn wie echte Firmen-Software und zeigt Fehler.',
      'Español':
          'Sube tu CV. La IA lo revisa contra algoritmos ATS y te muestra qué mejorar.',
    },
    'Optimize & Land Jobs': {
      'English': 'Optimize & Land Jobs',
      'Deutsch': 'Optimieren & Jobs bekommen',
      'Español': 'Optimizar y conseguir empleo',
    },
    'Get an AI-optimized CV without changing facts, share your score, and boost your career opportunities.': {
      'English':
          'Get an AI-optimized CV without changing facts, share your score, and boost your career opportunities.',
      'Deutsch':
          'Erhalte einen KI-optimierten Lebenslauf (ohne Lügen) und maximiere deine Chancen.',
      'Español':
          'Obtén un CV optimizado por IA sin cambiar hechos y mejora tus oportunidades.',
    },

    // --- Auth Screens ---
    'Welcome Back': {
      'English': 'Welcome Back',
      'Deutsch': 'Willkommen zurück',
      'Español': 'Bienvenido de nuevo',
    },
    'Sign in to continue': {
      'English': 'Sign in to continue',
      'Deutsch': 'Melde dich an, um fortzufahren',
      'Español': 'Inicia sesión para continuar',
    },
    'Forgot Password?': {
      'English': 'Forgot Password?',
      'Deutsch': 'Passwort vergessen?',
      'Español': '¿Olvidaste tu contraseña?',
    },
    'Login': {
      'English': 'Login',
      'Deutsch': 'Anmelden',
      'Español': 'Iniciar sesión',
    },
    'Continue with Google': {
      'English': 'Continue with Google',
      'Deutsch': 'Weiter mit Google',
      'Español': 'Continuar con Google',
    },
    "Don't have an account? ": {
      'English': "Don't have an account? ",
      'Deutsch': "Noch kein Konto? ",
      'Español': "¿No tienes una cuenta? ",
    },
    'Sign Up': {
      'English': 'Sign Up',
      'Deutsch': 'Registrieren',
      'Español': 'Regístrate',
    },
    'Create Account': {
      'English': 'Create Account',
      'Deutsch': 'Konto erstellen',
      'Español': 'Crear cuenta',
    },
    'Join thousands optimizing their CVs': {
      'English': 'Join thousands optimizing their CVs',
      'Deutsch': 'Werde Teil von Tausenden, die ihren CV optimieren',
      'Español': 'Únete a miles que optimizan su CV',
    },
    'Confirm Password': {
      'English': 'Confirm Password',
      'Deutsch': 'Passwort bestätigen',
      'Español': 'Confirmar contraseña',
    },
    'I agree to Terms & Conditions': {
      'English': 'I agree to Terms & Conditions',
      'Deutsch': 'Ich stimme den AGB zu',
      'Español': 'Acepto los Términos y Condiciones',
    },
    'Already have an account? ': {
      'English': 'Already have an account? ',
      'Deutsch': 'Du hast bereits ein Konto? ',
      'Español': '¿Ya tienes una cuenta? ',
    },
    'Log in': {
      'English': 'Log in',
      'Deutsch': 'Anmelden',
      'Español': 'Iniciar sesión',
    },

    // --- Kennlernphase ---
    "What's your name?": {
      'English': "What's your name?",
      'Deutsch': 'Wie heißt du?',
      'Español': '¿Cómo te llamas?',
    },
    'Let us get to know you better': {
      'English': 'Let us get to know you better',
      'Deutsch': 'Lass uns dich besser kennenlernen',
      'Español': 'Déjanos conocerte mejor',
    },
    'Enter your name': {
      'English': 'Enter your name',
      'Deutsch': 'Gib deinen Namen ein',
      'Español': 'Introduce tu nombre',
    },
    "What's your job title?": {
      'English': "What's your job title?",
      'Deutsch': 'Was ist dein Beruf?',
      'Español': '¿Cuál es tu profesión?',
    },
    'This helps us personalize your experience': {
      'English': 'This helps us personalize your experience',
      'Deutsch': 'Das hilft uns, deine Erfahrung zu personalisieren',
      'Español': 'Esto ayuda a personalizar tu experiencia',
    },
    'e.g. Software Developer': {
      'English': 'e.g. Software Developer',
      'Deutsch': 'z.B. Softwareentwickler',
      'Español': 'ej. Desarrollador de Software',
    },
    "What's your goal?": {
      'English': "What's your goal?",
      'Deutsch': 'Was ist dein Ziel?',
      'Español': '¿Cuál es tu objetivo?',
    },
    'Choose what you want to achieve': {
      'English': 'Choose what you want to achieve',
      'Deutsch': 'Wähle, was du erreichen möchtest',
      'Español': 'Elige lo que quieres lograr',
    },
    'Find a new job': {
      'English': 'Find a new job',
      'Deutsch': 'Einen neuen Job finden',
      'Español': 'Encontrar un nuevo trabajo',
    },
    'Improve my CV': {
      'English': 'Improve my CV',
      'Deutsch': 'Meinen Lebenslauf verbessern',
      'Español': 'Mejorar mi CV',
    },
    'Career change': {
      'English': 'Career change',
      'Deutsch': 'Beruflicher Neustart',
      'Español': 'Cambio de carrera',
    },
    'Get promotions': {
      'English': 'Get promotions',
      'Deutsch': 'Beförderung bekommen',
      'Español': 'Conseguir un ascenso',
    },
    'Just exploring': {
      'English': 'Just exploring',
      'Deutsch': 'Nur mal umschauen',
      'Español': 'Solo explorando',
    },
    "You're all set,": {
      'English': "You're all set,",
      'Deutsch': 'Alles bereit,',
      'Español': 'Todo listo,',
    },
    "Together with ShadowCV, you'll uncover hidden opportunities and land your dream job. Let's make it happen! 🚀": {
      'English':
          "Together with ShadowCV, you'll uncover hidden opportunities and land your dream job. Let's make it happen! 🚀",
      'Deutsch':
          "Mit ShadowCV entdeckst du neue Chancen und bekommst deinen Traumjob. Lass es uns anpacken! 🚀",
      'Español':
          "Con ShadowCV descubrirás oportunidades ocultas y conseguirás tu trabajo ideal. ¡Hagámoslo realidad! 🚀",
    },
    'Name': {'English': 'Name', 'Deutsch': 'Name', 'Español': 'Nombre'},
    'Job': {'English': 'Job', 'Deutsch': 'Beruf', 'Español': 'Profesión'},
    'Goal': {'English': 'Goal', 'Deutsch': 'Ziel', 'Español': 'Objetivo'},
    "Let's Go!": {
      'English': "Let's Go!",
      'Deutsch': "Los geht's!",
      'Español': '¡Vamos!',
    },

    // --- Home Screen ---
    'Professional CV Analysis': {
      'English': 'Professional CV Analysis',
      'Deutsch': 'Professionelle CV-Analyse',
      'Español': 'Análisis profesional de CV',
    },
    'Upload CV': {
      'English': 'Upload CV',
      'Deutsch': 'CV hochladen',
      'Español': 'Subir CV',
    },
    'Choose an option': {
      'English': 'Choose an option',
      'Deutsch': 'Wähle eine Option',
      'Español': 'Elige una opción',
    },
    'PDF from files': {
      'English': 'PDF from files',
      'Deutsch': 'PDF aus Dateien',
      'Español': 'PDF desde archivos',
    },
    'Select a PDF file': {
      'English': 'Select a PDF file',
      'Deutsch': 'Wähle eine PDF-Datei aus',
      'Español': 'Selecciona un archivo PDF',
    },
    'From Gallery': {
      'English': 'From Gallery',
      'Deutsch': 'Aus Galerie',
      'Español': 'Desde la galería',
    },
    'Select up to 3 photos': {
      'English': 'Select up to 3 photos',
      'Deutsch': 'Bis zu 3 Fotos auswählen',
      'Español': 'Selecciona hasta 3 fotos',
    },
    'From Google Drive': {
      'English': 'From Google Drive',
      'Deutsch': 'Aus Google Drive',
      'Español': 'Desde Google Drive',
    },
    'Coming soon': {
      'English': 'Coming soon',
      'Deutsch': 'Kommt bald',
      'Español': 'Próximamente',
    },
    'Word Document': {
      'English': 'Word Document',
      'Deutsch': 'Word Dokument',
      'Español': 'Documento de Word',
    },
    'Analyze Your CV': {
      'English': 'Analyze Your CV',
      'Deutsch': 'Lebenslauf analysieren',
      'Español': 'Analiza tu CV',
    },
    'Upload & discover hidden biases': {
      'English': 'Upload & discover hidden biases',
      'Deutsch': 'Hochladen & Feedback erhalten',
      'Español': 'Sube y obtén feedback',
    },
    'Quick Actions': {
      'English': 'Quick Actions',
      'Deutsch': 'Schnellzugriff',
      'Español': 'Acciones rápidas',
    },
    'My Analyses': {
      'English': 'My Analyses',
      'Deutsch': 'Meine Analysen',
      'Español': 'Mis análisis',
    },
    'View past CV scans': {
      'English': 'View past CV scans',
      'Deutsch': 'Vergangene Analysen ansehen',
      'Español': 'Ver escaneos anteriores',
    },
    'AI Optimizer': {
      'English': 'AI Optimizer',
      'Deutsch': 'KI-Optimierer',
      'Español': 'Optimizador IA',
    },
    'Get AI-powered CV improvements': {
      'English': 'Get AI-powered CV improvements',
      'Deutsch': 'KI-gestützte Verbesserungen erhalten',
      'Español': 'Obtén mejoras impulsadas por IA',
    },
    'Chat with AI': {
      'English': 'Chat with AI',
      'Deutsch': 'Mit KI chatten',
      'Español': 'Chatear con IA',
    },
    'Ask questions about your CV': {
      'English': 'Ask questions about your CV',
      'Deutsch': 'Stelle Fragen zu deinem CV',
      'Español': 'Haz preguntas sobre tu CV',
    },
    'Upgrade to Premium': {
      'English': 'Upgrade to Premium',
      'Deutsch': 'Auf Premium upgraden',
      'Español': 'Mejorar a Premium',
    },
    'Unlock all features - €19.99': {
      'English': 'Unlock all features - €19.99',
      'Deutsch': 'Alle Funktionen freischalten - 19,99 €',
      'Español': 'Desbloquea todas las funciones - 19,99 €',
    },
    'Welcome, ': {
      'English': 'Welcome, ',
      'Deutsch': 'Willkommen, ',
      'Español': 'Bienvenido, ',
    },
    'Welcome back, ': {
      'English': 'Welcome back, ',
      'Deutsch': 'Willkommen zurück, ',
      'Español': 'Bienvenido de nuevo, ',
    },
    "Let's optimize your career together": {
      'English': "Let's optimize your career together",
      'Deutsch': 'Lass uns zusammen deine Karriere optimieren',
      'Español': 'Optimicemos tu carrera juntos',
    },
    'Ready to enhance your CV?': {
      'English': 'Ready to enhance your CV?',
      'Deutsch': 'Bereit, deinen CV zu verbessern?',
      'Español': '¿Listo para mejorar tu CV?',
    },
    'Reading CV': {
      'English': 'Reading CV',
      'Deutsch': 'Lese CV',
      'Español': 'Leyendo CV',
    },
    'Extracting text...': {
      'English': 'Extracting text...',
      'Deutsch': 'Extrahiere Text...',
      'Español': 'Extrayendo texto...',
    },
    'Uploading': {
      'English': 'Uploading',
      'Deutsch': 'Hochladen',
      'Español': 'Subiendo',
    },
    'Secure cloud storage...': {
      'English': 'Secure cloud storage...',
      'Deutsch': 'Sicherer Cloud-Speicher...',
      'Español': 'Almacenamiento seguro en la nube...',
    },
    'AI Analysis': {
      'English': 'AI Analysis',
      'Deutsch': 'KI-Analyse',
      'Español': 'Análisis IA',
    },
    'Detecting bias...': {
      'English': 'Detecting bias...',
      'Deutsch': 'Analysiere Details...',
      'Español': 'Analizando detalles...',
    },
    'Saving': {
      'English': 'Saving',
      'Deutsch': 'Speichern',
      'Español': 'Guardando',
    },
    'Almost done...': {
      'English': 'Almost done...',
      'Deutsch': 'Fast fertig...',
      'Español': 'Casi listo...',
    },

    // --- Profil & Dialoge ---
    'Profile': {'English': 'Profile', 'Deutsch': 'Profil', 'Español': 'Perfil'},
    'Account Settings': {
      'English': 'Account Settings',
      'Deutsch': 'Kontoeinstellungen',
      'Español': 'Ajustes de cuenta',
    },
    'Personal Information': {
      'English': 'Personal Information',
      'Deutsch': 'Persönliche Daten',
      'Español': 'Datos personales',
    },
    'Language': {
      'English': 'Language',
      'Deutsch': 'Sprache',
      'Español': 'Idioma',
    },
    'Delete Account': {
      'English': 'Delete Account',
      'Deutsch': 'Konto löschen',
      'Español': 'Borrar cuenta',
    },
    'Permanently delete all data': {
      'English': 'Permanently delete all data',
      'Deutsch': 'Alle Daten dauerhaft löschen',
      'Español': 'Borrar todos los datos',
    },
    'Support & Info': {
      'English': 'Support & Info',
      'Deutsch': 'Hilfe & Info',
      'Español': 'Soporte e Info',
    },
    'FAQ & Help': {
      'English': 'FAQ & Help',
      'Deutsch': 'FAQ & Hilfe',
      'Español': 'Preguntas y ayuda',
    },
    'Privacy & Terms': {
      'English': 'Privacy & Terms',
      'Deutsch': 'Datenschutz & AGB',
      'Español': 'Privacidad y términos',
    },
    'Sign Out': {
      'English': 'Sign Out',
      'Deutsch': 'Abmelden',
      'Español': 'Cerrar sesión',
    },
    'Current Plan': {
      'English': 'Current Plan',
      'Deutsch': 'Aktueller Tarif',
      'Español': 'Plan actual',
    },
    'Free': {'English': 'Free', 'Deutsch': 'Kostenlos', 'Español': 'Gratis'},
    'Ready for the next step?': {
      'English': 'Ready for the next step?',
      'Deutsch': 'Bereit für den nächsten Schritt?',
      'Español': '¿Listo para el siguiente paso?',
    },
    'Unlock AI Optimization and unlimited analyses.': {
      'English': 'Unlock AI Optimization...',
      'Deutsch': 'Schalte KI-Optimierung frei...',
      'Español': 'Desbloquea optimización IA...',
    },
    'Upgrade Now - from €19.99': {
      'English': 'Upgrade Now - from €19.99',
      'Deutsch': 'Jetzt upgraden - ab 19,99 €',
      'Español': 'Actualizar ahora - desde 19,99 €',
    },

    // --- Die vergessenen Dialog-Texte ---
    'Are you sure you want to sign out?': {
      'English': 'Are you sure you want to sign out?',
      'Deutsch': 'Möchtest du dich wirklich abmelden?',
      'Español': '¿Seguro que quieres cerrar sesión?',
    },
    'Delete Forever': {
      'English': 'Delete Forever',
      'Deutsch': 'Dauerhaft löschen',
      'Español': 'Borrar para siempre',
    },
    'This will permanently delete:': {
      'English': 'This will permanently delete:',
      'Deutsch': 'Dies löscht dauerhaft:',
      'Español': 'Esto borrará permanentemente:',
    },
    '• All CV analyses': {
      'English': '• All CV analyses',
      'Deutsch': '• Alle CV-Analysen',
      'Español': '• Todos los análisis de CV',
    },
    '• All chat history': {
      'English': '• All chat history',
      'Deutsch': '• Alle Chat-Verläufe',
      'Español': '• Todo el historial de chat',
    },
    '• Your account': {
      'English': '• Your account',
      'Deutsch': '• Dein Konto',
      'Español': '• Tu cuenta',
    },
    'This cannot be undone!': {
      'English': 'This cannot be undone!',
      'Deutsch': 'Das kann nicht rückgängig gemacht werden!',
      'Español': '¡Esto no se puede deshacer!',
    },
    // --- Fehlermeldungen & Loading ---
    'Please fill in all fields': {
      'English': 'Please fill in all fields',
      'Deutsch': 'Bitte alle Felder ausfüllen',
      'Español': 'Por favor completa todos los campos',
    },
    'Please fill in all fields and accept terms': {
      'English': 'Please fill in all fields and accept terms',
      'Deutsch': 'Bitte alle Felder ausfüllen und AGB akzeptieren',
      'Español': 'Completa todos los campos y acepta los términos',
    },
    'Passwords do not match': {
      'English': 'Passwords do not match',
      'Deutsch': 'Passwörter stimmen nicht überein',
      'Español': 'Las contraseñas no coinciden',
    },
    'Password must be at least 6 characters': {
      'English': 'Password must be at least 6 characters',
      'Deutsch': 'Passwort muss mindestens 6 Zeichen haben',
      'Español': 'La contraseña debe tener al menos 6 caracteres',
    },
    'Email already exists': {
      'English': 'Email already exists',
      'Deutsch': 'E-Mail existiert bereits',
      'Español': 'El correo ya existe',
    },
    'Invalid email': {
      'English': 'Invalid email',
      'Deutsch': 'Ungültige E-Mail',
      'Español': 'Correo inválido',
    },
    'Password too weak': {
      'English': 'Password too weak',
      'Deutsch': 'Passwort zu schwach',
      'Español': 'Contraseña muy débil',
    },
    'Sign up failed': {
      'English': 'Sign up failed',
      'Deutsch': 'Registrierung fehlgeschlagen',
      'Español': 'Registro fallido',
    },
    'No account found': {
      'English': 'No account found',
      'Deutsch': 'Kein Konto gefunden',
      'Español': 'No se encontró cuenta',
    },
    'Incorrect password': {
      'English': 'Incorrect password',
      'Deutsch': 'Falsches Passwort',
      'Español': 'Contraseña incorrecta',
    },
    'Login failed': {
      'English': 'Login failed',
      'Deutsch': 'Anmeldung fehlgeschlagen',
      'Español': 'Inicio de sesión fallido',
    },
    'Google login failed': {
      'English': 'Google login failed',
      'Deutsch': 'Google-Anmeldung fehlgeschlagen',
      'Español': 'Inicio con Google fallido',
    },
    'Not logged in': {
      'English': 'Not logged in',
      'Deutsch': 'Nicht angemeldet',
      'Español': 'No has iniciado sesión',
    },
    'Please enter your name': {
      'English': 'Please enter your name',
      'Deutsch': 'Bitte gib deinen Namen ein',
      'Español': 'Por favor ingresa tu nombre',
    },
    'Please enter your job title': {
      'English': 'Please enter your job title',
      'Deutsch': 'Bitte gib deinen Beruf ein',
      'Español': 'Por favor ingresa tu profesión',
    },
    'Please select a goal': {
      'English': 'Please select a goal',
      'Deutsch': 'Bitte wähle ein Ziel',
      'Español': 'Por favor selecciona un objetivo',
    },

    // --- Analyse ---
    'No analyses yet': {
      'English': 'No analyses yet',
      'Deutsch': 'Noch keine Analysen',
      'Español': 'Aún no hay análisis',
    },
    'Upload your first CV to start building your analysis history.': {
      'English':
          'Upload your first CV to start building your analysis history.',
      'Deutsch':
          'Lade deinen ersten CV hoch, um deine Analyse-Historie zu starten.',
      'Español': 'Sube tu primer CV para empezar tu historial de análisis.',
    },
    'Analysis Report': {
      'English': 'Analysis Report',
      'Deutsch': 'Analysebericht',
      'Español': 'Informe de análisis',
    },
    'No CV Detected': {
      'English': 'No CV Detected',
      'Deutsch': 'Kein CV erkannt',
      'Español': 'No se detectó CV',
    },
    'Please upload a valid resume PDF.': {
      'English': 'Please upload a valid resume PDF.',
      'Deutsch': 'Bitte lade eine gültige Lebenslauf-PDF hoch.',
      'Español': 'Por favor sube un PDF de CV válido.',
    },
    'Analysis Mode': {
      'English': 'Analysis Mode',
      'Deutsch': 'Analyse-Modus',
      'Español': 'Modo de análisis',
    },
    'How should we analyze your CV?': {
      'English': 'How should we analyze your CV?',
      'Deutsch': 'Wie sollen wir deinen CV analysieren?',
      'Español': '¿Cómo analizamos tu CV?',
    },
    'General Review': {
      'English': 'General Review',
      'Deutsch': 'Allgemeine Bewertung',
      'Español': 'Revisión general',
    },
    'Full CV analysis – structure, content, language & overall impression.': {
      'English':
          'Full CV analysis – structure, content, language & overall impression.',
      'Deutsch':
          'Komplette CV-Analyse – Struktur, Inhalt, Sprache & Gesamteindruck.',
      'Español':
          'Análisis completo – estructura, contenido, idioma e impresión general.',
    },
    'ATS Optimization': {
      'English': 'ATS Optimization',
      'Deutsch': 'ATS-Optimierung',
      'Español': 'Optimización ATS',
    },
    'Check if your CV passes Applicant Tracking Systems.': {
      'English': 'Check if your CV passes Applicant Tracking Systems.',
      'Deutsch': 'Prüfe, ob dein CV durch ATS-Systeme kommt.',
      'Español': 'Verifica si tu CV pasa los sistemas ATS.',
    },
    'Job-Specific Feedback': {
      'English': 'Job-Specific Feedback',
      'Deutsch': 'Jobspezifisches Feedback',
      'Español': 'Feedback específico',
    },
    "Tailored analysis for a specific job you're targeting.": {
      'English': "Tailored analysis for a specific job you're targeting.",
      'Deutsch': 'Maßgeschneiderte Analyse für einen bestimmten Job.',
      'Español': 'Análisis personalizado para un puesto específico.',
    },
    'Custom Prompt': {
      'English': 'Custom Prompt',
      'Deutsch': 'Eigene Frage',
      'Español': 'Pregunta personalizada',
    },
    'Ask the AI anything specific about your CV.': {
      'English': 'Ask the AI anything specific about your CV.',
      'Deutsch': 'Frag die KI alles über deinen CV.',
      'Español': 'Pregúntale a la IA lo que quieras sobre tu CV.',
    },
    'Start Analysis': {
      'English': 'Start Analysis',
      'Deutsch': 'Analyse starten',
      'Español': 'Iniciar análisis',
    },
    'Select a Mode': {
      'English': 'Select a Mode',
      'Deutsch': 'Modus wählen',
      'Español': 'Selecciona un modo',
    },
    'Target Job Title': {
      'English': 'Target Job Title',
      'Deutsch': 'Ziel-Jobtitel',
      'Español': 'Puesto objetivo',
    },
    'Your Question': {
      'English': 'Your Question',
      'Deutsch': 'Deine Frage',
      'Español': 'Tu pregunta',
    },
    'e.g. Senior Flutter Developer': {
      'English': 'e.g. Senior Flutter Developer',
      'Deutsch': 'z.B. Senior Flutter Entwickler',
      'Español': 'ej. Senior Flutter Developer',
    },
    'e.g. Is my CV suitable for a career change?': {
      'English': 'e.g. Is my CV suitable for a career change?',
      'Deutsch': 'z.B. Ist mein CV geeignet für einen Karrierewechsel?',
      'Español': 'ej. ¿Mi CV es adecuado para un cambio de carrera?',
    },
    'Please enter the target job title.': {
      'English': 'Please enter the target job title.',
      'Deutsch': 'Bitte gib den Ziel-Jobtitel ein.',
      'Español': 'Por favor ingresa el puesto objetivo.',
    },
    'Please enter your question or request.': {
      'English': 'Please enter your question or request.',
      'Deutsch': 'Bitte gib deine Frage ein.',
      'Español': 'Por favor ingresa tu pregunta.',
    },
    // --- Rewrite ---
    'Rewrite CV': {
      'English': 'Rewrite CV',
      'Deutsch': 'CV umschreiben',
      'Español': 'Reescribir CV',
    },
    'Rewritten CV': {
      'English': 'Rewritten CV',
      'Deutsch': 'Umgeschriebener CV',
      'Español': 'CV reescrito',
    },
    'Rewriting your CV...': {
      'English': 'Rewriting your CV...',
      'Deutsch': 'Schreibe deinen CV um...',
      'Español': 'Reescribiendo tu CV...',
    },
    'This may take a moment': {
      'English': 'This may take a moment',
      'Deutsch': 'Das kann einen Moment dauern',
      'Español': 'Esto puede tardar un momento',
    },
    'Copy Text': {
      'English': 'Copy Text',
      'Deutsch': 'Text kopieren',
      'Español': 'Copiar texto',
    },
    'Copied to clipboard!': {
      'English': 'Copied to clipboard!',
      'Deutsch': 'In die Zwischenablage kopiert!',
      'Español': '¡Copiado al portapapeles!',
    },
    'Look for [placeholders] and fill in your details.': {
      'English': 'Look for [placeholders] and fill in your details.',
      'Deutsch': 'Suche nach [Platzhaltern] und ergänze deine Details.',
      'Español': 'Busca los [marcadores] y completa tus detalles.',
    },

    // --- Error Messages ---
    'Error': {'English': 'Error', 'Deutsch': 'Fehler', 'Español': 'Error'},
    'PDF Error': {
      'English': 'PDF Error',
      'Deutsch': 'PDF-Fehler',
      'Español': 'Error de PDF',
    },
    'Error updating profile': {
      'English': 'Error updating profile',
      'Deutsch': 'Fehler beim Aktualisieren des Profils',
      'Español': 'Error al actualizar el perfil',
    },

    // --- Analysis Result Screen ---
    'No CV text available for rewrite.': {
      'English': 'No CV text available for rewrite.',
      'Deutsch': 'Kein CV-Text zum Umschreiben verfügbar.',
      'Español': 'No hay texto de CV disponible para reescribir.',
    },
    '/ 100 Quality Score': {
      'English': '/ 100 Quality Score',
      'Deutsch': '/ 100 Qualitäts-Score',
      'Español': '/ 100 Puntuación de calidad',
    },
    'SUMMARY': {
      'English': 'SUMMARY',
      'Deutsch': 'ZUSAMMENFASSUNG',
      'Español': 'RESUMEN',
    },
    'TOP PRIORITIES': {
      'English': 'TOP PRIORITIES',
      'Deutsch': 'WICHTIGSTE PRIORITÄTEN',
      'Español': 'PRIORIDADES PRINCIPALES',
    },
    'STRENGTHS': {
      'English': 'STRENGTHS',
      'Deutsch': 'STÄRKEN',
      'Español': 'FORTALEZAS',
    },
    'WEAKNESSES': {
      'English': 'WEAKNESSES',
      'Deutsch': 'SCHWÄCHEN',
      'Español': 'DEBILIDADES',
    },
    'DETAILED SUGGESTIONS': {
      'English': 'DETAILED SUGGESTIONS',
      'Deutsch': 'DETAILLIERTE VORSCHLÄGE',
      'Español': 'SUGERENCIAS DETALLADAS',
    },
    'Suggestion': {
      'English': 'Suggestion',
      'Deutsch': 'Vorschlag',
      'Español': 'Sugerencia',
    },

    // --- My Analyses Screen ---
    'Unknown file': {
      'English': 'Unknown file',
      'Deutsch': 'Unbekannte Datei',
      'Español': 'Archivo desconocido',
    },
    'Unknown': {
      'English': 'Unknown',
      'Deutsch': 'Unbekannt',
      'Español': 'Desconocido',
    },
    'Unknown date': {
      'English': 'Unknown date',
      'Deutsch': 'Unbekanntes Datum',
      'Español': 'Fecha desconocida',
    },
    'NOT A CV': {
      'English': 'NOT A CV',
      'Deutsch': 'KEIN CV',
      'Español': 'NO ES UN CV',
    },
    'This file was not recognized as a CV.': {
      'English': 'This file was not recognized as a CV.',
      'Deutsch': 'Diese Datei wurde nicht als CV erkannt.',
      'Español': 'Este archivo no fue reconocido como CV.',
    },

    // --- Edit Profile Screen ---
    'Edit Profile': {
      'English': 'Edit Profile',
      'Deutsch': 'Profil bearbeiten',
      'Español': 'Editar perfil',
    },
    'Full Name': {
      'English': 'Full Name',
      'Deutsch': 'Vollständiger Name',
      'Español': 'Nombre completo',
    },
    'Job Title': {
      'English': 'Job Title',
      'Deutsch': 'Berufsbezeichnung',
      'Español': 'Título profesional',
    },
    'Career Goal': {
      'English': 'Career Goal',
      'Deutsch': 'Karriereziel',
      'Español': 'Objetivo profesional',
    },
    'Profile updated successfully': {
      'English': 'Profile updated successfully',
      'Deutsch': 'Profil erfolgreich aktualisiert',
      'Español': 'Perfil actualizado con éxito',
    },
    'Please enter your': {
      'English': 'Please enter your',
      'Deutsch': 'Bitte gib dein(e)',
      'Español': 'Por favor ingresa tu',
    },

    // --- Forgot Password Screen ---
    'Please enter your email': {
      'English': 'Please enter your email',
      'Deutsch': 'Bitte gib deine E-Mail ein',
      'Español': 'Por favor ingresa tu correo',
    },
    'Password reset link sent! Check your email': {
      'English': 'Password reset link sent! Check your email',
      'Deutsch': 'Passwort-Reset-Link gesendet! Prüfe deine E-Mails',
      'Español': '¡Enlace de restablecimiento enviado! Revisa tu correo',
    },
    'No account found with this email': {
      'English': 'No account found with this email',
      'Deutsch': 'Kein Konto mit dieser E-Mail gefunden',
      'Español': 'No se encontró cuenta con este correo',
    },
    'Invalid email format': {
      'English': 'Invalid email format',
      'Deutsch': 'Ungültiges E-Mail-Format',
      'Español': 'Formato de correo inválido',
    },
    'Failed to send reset email': {
      'English': 'Failed to send reset email',
      'Deutsch': 'Fehler beim Senden der Reset-E-Mail',
      'Español': 'Error al enviar el correo de restablecimiento',
    },
    "Don't worry! Enter your email and we'll send you a reset link": {
      'English':
          "Don't worry! Enter your email and we'll send you a reset link",
      'Deutsch':
          'Keine Sorge! Gib deine E-Mail ein und wir senden dir einen Reset-Link',
      'Español':
          '¡No te preocupes! Ingresa tu correo y te enviaremos un enlace',
    },
    'Enter your email': {
      'English': 'Enter your email',
      'Deutsch': 'E-Mail eingeben',
      'Español': 'Ingresa tu correo',
    },
    'Send Reset Link': {
      'English': 'Send Reset Link',
      'Deutsch': 'Reset-Link senden',
      'Español': 'Enviar enlace de restablecimiento',
    },

    // --- Profile Screen ---
    'All Premium features unlocked!': {
      'English': 'All Premium features unlocked!',
      'Deutsch': 'Alle Premium-Funktionen freigeschaltet!',
      'Español': '¡Todas las funciones Premium desbloqueadas!',
    },
    'You are using ShadowCV with maximum power.': {
      'English': 'You are using ShadowCV with maximum power.',
      'Deutsch': 'Du nutzt ShadowCV mit voller Power.',
      'Español': 'Estás usando ShadowCV con máximo poder.',
    },
    'User': {'English': 'User', 'Deutsch': 'Benutzer', 'Español': 'Usuario'},
    'No Email': {
      'English': 'No Email',
      'Deutsch': 'Keine E-Mail',
      'Español': 'Sin correo',
    },
    'Job Seeker': {
      'English': 'Job Seeker',
      'Deutsch': 'Jobsuchender',
      'Español': 'Buscador de empleo',
    },
    // Splash screen
    'Uncover Your Hidden Potential': {
      'English': 'Uncover Your Hidden Potential',
      'Deutsch': 'Entdecke dein verborgenes Potenzial',
      'Español': 'Descubre tu potencial oculto',
    },
    // --- Result Screen Dynamic Modes ---
    'ATS Parsing Results': {
      'English': 'ATS Parsing Results',
      'Deutsch': 'ATS Parsing-Ergebnisse',
      'Español': 'Resultados de análisis ATS',
    },
    'ATS Passed': {
      'English': 'ATS Passed',
      'Deutsch': 'ATS Bestanden',
      'Español': 'ATS Aprobado',
    },
    'ATS Errors & Red Flags': {
      'English': 'ATS Errors & Red Flags',
      'Deutsch': 'ATS Fehler & Warnungen',
      'Español': 'Errores ATS y advertencias',
    },
    'Formatting Fixes': {
      'English': 'Formatting Fixes',
      'Deutsch': 'Formatierungs-Tipps',
      'Español': 'Correcciones de formato',
    },

    'Role Fit Analysis': {
      'English': 'Role Fit Analysis',
      'Deutsch': 'Job-Passgenauigkeit',
      'Español': 'Análisis de ajuste al rol',
    },
    'Matching Skills': {
      'English': 'Matching Skills',
      'Deutsch': 'Passende Fähigkeiten',
      'Español': 'Habilidades coincidentes',
    },
    'Missing Keywords': {
      'English': 'Missing Keywords',
      'Deutsch': 'Fehlende Keywords',
      'Español': 'Palabras clave faltantes',
    },
    'Tailoring Advice': {
      'English': 'Tailoring Advice',
      'Deutsch': 'Tipps zur Anpassung',
      'Español': 'Consejos de adaptación',
    },

    'Direct Answer': {
      'English': 'Direct Answer',
      'Deutsch': 'Direkte Antwort',
      'Español': 'Respuesta directa',
    },
    'What works well': {
      'English': 'What works well',
      'Deutsch': 'Was gut funktioniert',
      'Español': 'Lo que funciona bien',
    },
    'What to change': {
      'English': 'What to change',
      'Deutsch': 'Was du ändern solltest',
      'Español': 'Qué cambiar',
    },
    'Specific Advice': {
      'English': 'Specific Advice',
      'Deutsch': 'Spezifischer Rat',
      'Español': 'Consejo específico',
    },

    // --- Modus Namen für Result Badge ---
    'generalReview': {
      'English': 'General Review',
      'Deutsch': 'Allgemeine Analyse',
      'Español': 'Revisión General',
    },
    'atsOptimization': {
      'English': 'ATS Check',
      'Deutsch': 'ATS Check',
      'Español': 'Verificación ATS',
    },
    'jobSpecific': {
      'English': 'Job Fit',
      'Deutsch': 'Job Fit',
      'Español': 'Ajuste al Empleo',
    },
    'customPrompt': {
      'English': 'Custom Analysis',
      'Deutsch': 'Eigene Analyse',
      'Español': 'Análisis Personalizado',
    },
    'Detected': {
      'English': 'Detected',
      'Deutsch': 'Erkannt',
      'Español': 'Detectado',
    },
    'Tip': {'English': 'Tip', 'Deutsch': 'Tipp', 'Español': 'Consejo'},
    'Upload a PDF that contains your work experience, education and skills for the best results.': {
      'English':
          'Upload a PDF that contains your work experience, education and skills for the best results.',
      'Deutsch':
          'Lade eine PDF hoch, die deine Berufserfahrung, Ausbildung und Fähigkeiten enthält – für die besten Ergebnisse.',
      'Español':
          'Sube un PDF con tu experiencia laboral, educación y habilidades para obtener los mejores resultados.',
    },
    // --- AI Chat ---
    'CV Assistant': {
      'English': 'CV Assistant',
      'Deutsch': 'CV Assistent',
      'Español': 'Asistente de CV',
    },
    'Ask me anything about your CV': {
      'English': 'Ask me anything about your CV',
      'Deutsch': 'Frag mich alles über deinen CV',
      'Español': 'Pregúntame lo que quieras sobre tu CV',
    },
    'Hi! I have analyzed your CV. Ask me anything about it!': {
      'English': 'Hi! I have analyzed your CV. Ask me anything about it!',
      'Deutsch':
          'Hallo! Ich habe deinen CV analysiert. Frag mich alles darüber!',
      'Español': '¡Hola! He analizado tu CV. ¡Pregúntame lo que quieras!',
    },
    'Quick questions:': {
      'English': 'Quick questions:',
      'Deutsch': 'Schnellfragen:',
      'Español': 'Preguntas rápidas:',
    },
    'What is my biggest weakness?': {
      'English': 'What is my biggest weakness?',
      'Deutsch': 'Was ist meine größte Schwäche?',
      'Español': '¿Cuál es mi mayor debilidad?',
    },
    'How can I improve my summary?': {
      'English': 'How can I improve my summary?',
      'Deutsch': 'Wie kann ich meine Zusammenfassung verbessern?',
      'Español': '¿Cómo puedo mejorar mi resumen?',
    },
    'What should I fix first?': {
      'English': 'What should I fix first?',
      'Deutsch': 'Was soll ich zuerst beheben?',
      'Español': '¿Qué debo corregir primero?',
    },
    'Which keywords am I missing?': {
      'English': 'Which keywords am I missing?',
      'Deutsch': 'Welche Keywords fehlen mir?',
      'Español': '¿Qué palabras clave me faltan?',
    },
    'How do I fix ATS formatting?': {
      'English': 'How do I fix ATS formatting?',
      'Deutsch': 'Wie behebe ich ATS-Formatierungsfehler?',
      'Español': '¿Cómo corrijo el formato ATS?',
    },
    'What section titles should I use?': {
      'English': 'What section titles should I use?',
      'Deutsch': 'Welche Abschnittstitel soll ich verwenden?',
      'Español': '¿Qué títulos de sección debo usar?',
    },
    'How do I tailor my experience better?': {
      'English': 'How do I tailor my experience better?',
      'Deutsch': 'Wie passe ich meine Erfahrung besser an?',
      'Español': '¿Cómo adapto mejor mi experiencia?',
    },
    'What skills should I highlight?': {
      'English': 'What skills should I highlight?',
      'Deutsch': 'Welche Fähigkeiten soll ich hervorheben?',
      'Español': '¿Qué habilidades debo destacar?',
    },
    'How do I rewrite my summary for this job?': {
      'English': 'How do I rewrite my summary for this job?',
      'Deutsch': 'Wie schreibe ich meine Zusammenfassung für diesen Job um?',
      'Español': '¿Cómo reescribo mi resumen para este trabajo?',
    },
    'Ask about your CV...': {
      'English': 'Ask about your CV...',
      'Deutsch': 'Frag über deinen CV...',
      'Español': 'Pregunta sobre tu CV...',
    },
    'Ask AI': {
      'English': 'Ask AI',
      'Deutsch': 'KI fragen',
      'Español': 'Preguntar IA',
    },
    // --- Premium ---
    'Unlock ShadowCV Premium': {
      'English': 'Unlock ShadowCV Premium',
      'Deutsch': 'ShadowCV Premium freischalten',
      'Español': 'Desbloquear ShadowCV Premium',
    },
    'Get hired faster with AI-powered tools': {
      'English': 'Get hired faster with AI-powered tools',
      'Deutsch': 'Schneller eingestellt werden mit KI-Tools',
      'Español': 'Consigue trabajo más rápido con herramientas IA',
    },
    'Unlimited CV Analyses': {
      'English': 'Unlimited CV Analyses',
      'Deutsch': 'Unbegrenzte CV-Analysen',
      'Español': 'Análisis ilimitados de CV',
    },
    'AI Chat with your CV': {
      'English': 'AI Chat with your CV',
      'Deutsch': 'KI-Chat mit deinem CV',
      'Español': 'Chat IA con tu CV',
    },
    'AI CV Rewriter': {
      'English': 'AI CV Rewriter',
      'Deutsch': 'KI CV-Umschreiber',
      'Español': 'Reescritor de CV con IA',
    },
    'All Analysis Modes (ATS, Job-Specific, Custom)': {
      'English': 'All Analysis Modes',
      'Deutsch': 'Alle Analyse-Modi',
      'Español': 'Todos los modos de análisis',
    },
    'PDF Export': {
      'English': 'PDF Export',
      'Deutsch': 'PDF Export',
      'Español': 'Exportar PDF',
    },
    'Priority AI Processing': {
      'English': 'Priority AI Processing',
      'Deutsch': 'Priorisierte KI-Verarbeitung',
      'Español': 'Procesamiento IA prioritario',
    },
    'Monthly': {
      'English': 'Monthly',
      'Deutsch': 'Monatlich',
      'Español': 'Mensual',
    },
    'Lifetime': {
      'English': 'Lifetime',
      'Deutsch': 'Einmalig',
      'Español': 'De por vida',
    },
    '/ month': {'English': '/ month', 'Deutsch': '/ Monat', 'Español': '/ mes'},
    'one time': {
      'English': 'one time',
      'Deutsch': 'einmalig',
      'Español': 'una vez',
    },
    'Cancel anytime': {
      'English': 'Cancel anytime',
      'Deutsch': 'Jederzeit kündbar',
      'Español': 'Cancela cuando quieras',
    },
    'Pay once, use forever': {
      'English': 'Pay once, use forever',
      'Deutsch': 'Einmal zahlen, für immer nutzen',
      'Español': 'Paga una vez, úsalo siempre',
    },
    'Best Value': {
      'English': 'Best Value',
      'Deutsch': 'Bestes Angebot',
      'Español': 'Mejor valor',
    },
    'Start for €4.99 / month': {
      'English': 'Start for €4.99 / month',
      'Deutsch': 'Starten für 4,99 € / Monat',
      'Español': 'Empezar por 4,99 € / mes',
    },
    'Get Lifetime for €19.99': {
      'English': 'Get Lifetime for €19.99',
      'Deutsch': 'Einmalig für 19,99 €',
      'Español': 'Obtener de por vida por 19,99 €',
    },
    'Restore Purchases': {
      'English': 'Restore Purchases',
      'Deutsch': 'Käufe wiederherstellen',
      'Español': 'Restaurar compras',
    },
    'Secure payment via App Store / Google Play': {
      'English': 'Secure payment via App Store / Google Play',
      'Deutsch': 'Sichere Zahlung über App Store / Google Play',
      'Español': 'Pago seguro vía App Store / Google Play',
    },
    'Purchases restored!': {
      'English': 'Purchases restored!',
      'Deutsch': 'Käufe wiederhergestellt!',
      'Español': '¡Compras restauradas!',
    },
    'Premium activated! (Dev Mode)': {
      'English': 'Premium activated! (Dev Mode)',
      'Deutsch': 'Premium aktiviert! (Dev-Modus)',
      'Español': '¡Premium activado! (Modo dev)',
    },
    'Remaining': {
      'English': 'Remaining',
      'Deutsch': 'Verbleibend',
      'Español': 'Restante',
    },
    'Analyses': {
      'English': 'Analyses',
      'Deutsch': 'Analysen',
      'Español': 'Mis análisis',
    },
    'No free analyses left – Upgrade now': {
      'English': 'No free analyses left – Upgrade now',
      'Deutsch': 'Keine Analysen übrig - Upgrade jetzt',
      'Español': 'No quedan análisis gratuitos: actualice ahora',
    },
    'AI Ready': {
      'English': 'AI Ready',
      'Deutsch': 'KI-fähig',
      'Español': 'Listo para IA',
    },
    'Free analyses remaining': {
      'English': 'Free analyses remaining',
      'Deutsch': 'Freie Analysen übrig',
      'Español': 'Análisis gratuitos restantes',
    },
    'Upload & get AI-powered feedback': {
      'English': 'Upload & get AI-powered feedback',
      'Deutsch': 'Lade hoch und erhalte KI-gestützte Rückmeldung',
      'Español': 'Sube y obtén retroalimentación impulsada por IA',
    },
    'CV Analyses': {
      'English': 'CV Analyses',
      'Deutsch': 'CV-Analysen',
      'Español': 'Análisis de CV',
    },
    'Analysis Modes': {
      'English': 'Analyses Modes',
      'Deutsch': 'Analysen-Modi',
      'Español': 'Modos de análisis',
    },
    'AI Chat': {
      'English': 'AI Chat',
      'Deutsch': 'KI-Chat',
      'Español': 'Chat IA',
    },
    'CV Rewrite': {
      'English': 'CV Rewrite',
      'Deutsch': 'CV umschreiben',
      'Español': 'Reescribir CV',
    },
    'Priority Processing': {
      'English': 'Priority Processing',
      'Deutsch': 'Prioritätsverarbeitung',
      'Español': 'Procesamiento prioritario',
    },
    'General only': {
      'English': 'General only',
      'Deutsch': 'Nur allgemein',
      'Español': 'Solo general',
    },
    'All 4': {'English': 'All 4', 'Deutsch': 'Alle 4', 'Español': 'Todos 4'},
    // ==================== INTERVIEW PREP ====================
    'Interview Prep': {
      'English': 'Interview Prep',
      'Deutsch': 'Interview-Vorbereitung',
      'Español': 'Preparación para entrevistas',
    },
    '10 Q\'s': {
      'English': '10 Q\'s',
      'Deutsch': '10 Fragen',
      'Español': '10 Preguntas',
    },
    'AI Personalized': {
      'English': 'AI Personalized',
      'Deutsch': 'KI-personalisiert',
      'Español': 'Personalizado por IA',
    },
    'personalized questions based on your CV': {
      'English': 'personalized questions based on your CV',
      'Deutsch': 'personalisierte Fragen basierend auf deinem CV',
      'Español': 'preguntas personalizadas basadas en tu CV',
    },
    'Behavioral': {
      'English': 'Behavioral',
      'Deutsch': 'Verhalten',
      'Español': 'Conductual',
    },
    'Technical': {
      'English': 'Technical',
      'Deutsch': 'Technisch',
      'Español': 'Técnico',
    },
    'Motivational': {
      'English': 'Motivational',
      'Deutsch': 'Motivational',
      'Español': 'Motivacional',
    },
    'Situational': {
      'English': 'Situational',
      'Deutsch': 'Situativ',
      'Español': 'Situacional',
    },
    'Why interviewers ask this': {
      'English': 'Why interviewers ask this',
      'Deutsch': 'Warum Interviewer das fragen',
      'Español': 'Por qué los entrevistadores preguntan esto',
    },
    'Example Answer': {
      'English': 'Example Answer',
      'Deutsch': 'Beispielantwort',
      'Español': 'Respuesta de ejemplo',
    },
    'Pro Tip': {
      'English': 'Pro Tip',
      'Deutsch': 'Profi-Tipp',
      'Español': 'Consejo profesional',
    },
    'Which role are you interviewing for?': {
      'English': 'Which role are you interviewing for?',
      'Deutsch': 'Für welche Stelle bewirbst du dich?',
      'Español': '¿Para qué puesto te entrevistas?',
    },
    'e.g. Senior Flutter Developer at Google': {
      'English': 'e.g. Senior Flutter Developer at Google',
      'Deutsch': 'z.B. Senior Flutter Entwickler bei Google',
      'Español': 'ej. Senior Flutter Developer en Google',
    },
    'Generate': {
      'English': 'Generate',
      'Deutsch': 'Generieren',
      'Español': 'Generar',
    },

    // ==================== COVER LETTER ====================
    'Cover Letter': {
      'English': 'Cover Letter',
      'Deutsch': 'Anschreiben',
      'Español': 'Carta de presentación',
    },
    'AI Generated • Ready to use': {
      'English': 'AI Generated • Ready to use',
      'Deutsch': 'KI-generiert • Einsatzbereit',
      'Español': 'Generado por IA • Listo para usar',
    },
    'YOUR COVER LETTER': {
      'English': 'YOUR COVER LETTER',
      'Deutsch': 'DEIN ANSCHREIBEN',
      'Español': 'TU CARTA DE PRESENTACIÓN',
    },
    'Copied!': {
      'English': 'Copied!',
      'Deutsch': 'Kopiert!',
      'Español': '¡Copiado!',
    },
    'Professional': {
      'English': 'Professional',
      'Deutsch': 'Professionell',
      'Español': 'Profesional',
    },
    'Formal': {'English': 'Formal', 'Deutsch': 'Formell', 'Español': 'Formal'},
    'Creative': {
      'English': 'Creative',
      'Deutsch': 'Kreativ',
      'Español': 'Creativo',
    },
    'Tone': {'English': 'Tone', 'Deutsch': 'Ton', 'Español': 'Tono'},
    'e.g. Product Manager at Apple': {
      'English': 'e.g. Product Manager at Apple',
      'Deutsch': 'z.B. Produktmanager bei Apple',
      'Español': 'ej. Product Manager en Apple',
    },
    'AI-generated cover letter': {
      'English': 'AI-generated cover letter',
      'Deutsch': 'KI-generiertes Anschreiben',
      'Español': 'Carta de presentación generada por IA',
    },
    'AI-powered interview questions': {
      'English': 'AI-powered interview questions',
      'Deutsch': 'KI-gestützte Interviewfragen',
      'Español': 'Preguntas de entrevista con IA',
    },
    // ==================== SALARY INSIGHTS ====================
    'Salary Insights': {
      'English': 'Salary Insights',
      'Deutsch': 'Gehaltsanalyse',
      'Español': 'Análisis salarial',
    },
    'Salary Boosters': {
      'English': 'Salary Boosters',
      'Deutsch': 'Gehalts-Booster',
      'Español': 'Potenciadores de salario',
    },
    'Salary Limiters': {
      'English': 'Salary Limiters',
      'Deutsch': 'Gehaltsbegrenzer',
      'Español': 'Limitadores de salario',
    },
    'How to Earn More': {
      'English': 'How to Earn More',
      'Deutsch': 'Wie du mehr verdienst',
      'Español': 'Cómo ganar más',
    },
    'SALARY RANGE': {
      'English': 'SALARY RANGE',
      'Deutsch': 'GEHALTSSPANNE',
      'Español': 'RANGO SALARIAL',
    },
    'Min': {'English': 'Min', 'Deutsch': 'Min', 'Español': 'Mín'},
    'You': {'English': 'You', 'Deutsch': 'Du', 'Español': 'Tú'},
    'Max': {'English': 'Max', 'Deutsch': 'Max', 'Español': 'Máx'},
    'Market avg': {
      'English': 'Market avg',
      'Deutsch': 'Marktdurchschnitt',
      'Español': 'Promedio del mercado',
    },
    'above market': {
      'English': 'Above market',
      'Deutsch': 'Über Markt',
      'Español': 'Sobre el mercado',
    },
    'below market': {
      'English': 'Below market',
      'Deutsch': 'Unter Markt',
      'Español': 'Bajo el mercado',
    },
    'at market': {
      'English': 'At market',
      'Deutsch': 'Im Markt',
      'Español': 'En el mercado',
    },
    'yrs exp': {
      'English': 'yrs exp',
      'Deutsch': 'Jahre Erf.',
      'Español': 'años exp',
    },
    'Country': {'English': 'Country', 'Deutsch': 'Land', 'Español': 'País'},
    'e.g. Senior Developer': {
      'English': 'e.g. Senior Developer',
      'Deutsch': 'z.B. Senior Entwickler',
      'Español': 'ej. Desarrollador Senior',
    },
    'e.g. Germany, USA, UK': {
      'English': 'e.g. Germany, USA, UK',
      'Deutsch': 'z.B. Deutschland, USA, UK',
      'Español': 'ej. Alemania, EE.UU., UK',
    },
    'Analyze': {
      'English': 'Analyze',
      'Deutsch': 'Analysieren',
      'Español': 'Analizar',
    },
    'AI salary estimation for your profile': {
      'English': 'AI salary estimation for your profile',
      'Deutsch': 'KI-Gehaltsschätzung für dein Profil',
      'Español': 'Estimación salarial IA para tu perfil',
    },
    // ==================== INTERVIEW SIMULATION ====================
    'Interview Simulation': {
      'English': 'Interview Simulation',
      'Deutsch': 'Interview-Simulation',
      'Español': 'Simulación de Entrevista',
    },
    'Start Interview Simulation': {
      'English': 'Start Interview Simulation',
      'Deutsch': 'Interview-Simulation starten',
      'Español': 'Iniciar Simulación de Entrevista',
    },
    'Interviewer': {
      'English': 'Interviewer',
      'Deutsch': 'Interviewer',
      'Español': 'Entrevistador',
    },
    'AI Feedback': {
      'English': 'AI Feedback',
      'Deutsch': 'KI-Feedback',
      'Español': 'Feedback de IA',
    },
    'See Results': {
      'English': 'See Results',
      'Deutsch': 'Ergebnisse ansehen',
      'Español': 'Ver Resultados',
    },
    'Next Question': {
      'English': 'Next Question',
      'Deutsch': 'Nächste Frage',
      'Español': 'Siguiente Pregunta',
    },
    'Type your answer as you would say it': {
      'English': 'Type your answer as you would say it',
      'Deutsch': 'Tippe deine Antwort wie du sie sagen würdest',
      'Español': 'Escribe tu respuesta como la dirías',
    },
    'Your answer...': {
      'English': 'Your answer...',
      'Deutsch': 'Deine Antwort...',
      'Español': 'Tu respuesta...',
    },
    'Simulation Complete!': {
      'English': 'Simulation Complete!',
      'Deutsch': 'Simulation abgeschlossen!',
      'Español': '¡Simulación Completada!',
    },
    'Average Score': {
      'English': 'Average Score',
      'Deutsch': 'Durchschnittspunktzahl',
      'Español': 'Puntuación Promedio',
    },
    'Question Scores': {
      'English': 'Question Scores',
      'Deutsch': 'Fragen-Punktzahlen',
      'Español': 'Puntuaciones por Pregunta',
    },
    'Overall Feedback': {
      'English': 'Overall Feedback',
      'Deutsch': 'Gesamtfeedback',
      'Español': 'Feedback General',
    },
    'Back to Questions': {
      'English': 'Back to Questions',
      'Deutsch': 'Zurück zu den Fragen',
      'Español': 'Volver a Preguntas',
    },
    'Reading': {
      'English': 'Reading',
      'Deutsch': 'Lesen',
      'Español': 'Leyendo',
    },
    'Thinking...': {
      'English': 'Thinking...',
      'Deutsch': 'Denken...',
      'Español': 'Pensando...',
    },
    'Sending to AI': {
      'English': 'Sending to AI',
      'Deutsch': 'Senden an KI',
      'Español': 'Enviando a IA',
    },
    'Analyzing': {
      'English': 'Analyzing',
      'Deutsch': 'Analysieren',
      'Español': 'Analizando',
    },
    
  };

  static String t(String key) {
    return texts[key]?[currentLang] ?? key;
  }

  static Future<void> initLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedLang = prefs.getString('app_lang');

    if (savedLang != null) {
      currentLang = savedLang;
    } else {
      final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
      if (deviceLang == 'de') {
        currentLang = 'Deutsch';
      } else if (deviceLang == 'es') {
        currentLang = 'Español';
      } else {
        currentLang = 'English';
      }
    }
  }

  static Future<void> setLanguage(String lang) async {
    currentLang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
  }
}
