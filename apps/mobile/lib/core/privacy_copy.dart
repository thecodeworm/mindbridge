// Single source for the privacy wording shown in onboarding, sign-up, log in
// and Settings. Mirrors apps/web/src/lib/privacyCopy.ts.
//
// DRAFT wording: it states what the code actually does today. Have it
// reviewed before wider release. No em or en dashes in user-facing copy.

const int kMinAge = 13;

/// Required checkbox on email sign-up.
const String kSignupConsentLabel =
    'I am $kMinAge or older. I understand that when I ask for a coping technique or a weekly summary, the text of my check-ins is sent to an AI service (Anthropic) to write it.';

/// One line under the Google button (no checkbox on that path).
const String kGoogleConsentNotice =
    'By continuing you confirm you are $kMinAge or older and that check-in text is sent to an AI service (Anthropic) when you ask for a technique or summary.';

const String kTrustHeadlineLead = 'Your entries are';
const String kTrustHeadlineMark = 'yours.';
const String kTrustSubline = 'Other people who use MindBridge can never see them.';

const String kTrustCardText =
    'Nobody else on MindBridge can read your mood logs or journal entries. When you ask for a coping technique or a weekly summary, the words from that check-in are sent to an AI service (Anthropic) so it can write one. Your entries are stored in a database that the MindBridge team can technically access to keep the app running. You can export or delete all of it in Settings.';

const List<String> kPrivacyPoints = [
  'Only your account can see your mood logs, journal entries and techniques. Other MindBridge users cannot.',
  'When you ask for a coping technique or weekly summary, the text of that check-in is sent to an AI service (Anthropic) to write it.',
  'The MindBridge team can technically access stored data to keep the app running.',
  'You can export everything, delete your data, or delete your whole account in Settings.',
  'MindBridge is for people aged 13 and older. It is self-help, not medical care. If you are in crisis, tap Help.',
];

/// Metadata stored on the auth user when consent is given.
Map<String, dynamic> consentMetadata([DateTime? now]) => {
      'age_confirmed_min': kMinAge,
      'consent_ai_processing_at': (now ?? DateTime.now().toUtc()).toIso8601String(),
    };
