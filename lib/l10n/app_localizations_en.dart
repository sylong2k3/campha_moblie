// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cam Pha GIS';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonSave => 'Save changes';

  @override
  String get errorNetwork => 'No network connection';

  @override
  String get errorValidation => 'Invalid data';

  @override
  String get errorUnauthorized => 'Your session has expired';

  @override
  String get errorForbidden => 'You do not have permission for this action';

  @override
  String get errorPasswordChangeRequired => 'Change your password to continue';

  @override
  String get errorNotFound => 'Data not found';

  @override
  String get errorPayloadTooLarge => 'The file exceeds the allowed size';

  @override
  String get errorRateLimit => 'Too many attempts. Please try again later';

  @override
  String get errorServer => 'System error. Please try again later';

  @override
  String get errorUnknown => 'Something went wrong';

  @override
  String get roleSystemAdmin => 'System administrator';

  @override
  String get roleSoTnmt =>
      'Department of Natural Resources and Environment officer';

  @override
  String get roleSoXd => 'Department of Construction officer';

  @override
  String get roleUbndTp => 'City People\'s Committee officer';

  @override
  String get roleCitizen => 'Local citizen';

  @override
  String get roleGuest => 'Guest';

  @override
  String get roleSystemAdminShort => 'Admin';

  @override
  String get roleSoTnmtShort => 'DONRE';

  @override
  String get roleSoXdShort => 'DOC';

  @override
  String get roleUbndTpShort => 'City PC';

  @override
  String get roleCitizenShort => 'Citizen';

  @override
  String get roleGuestShort => 'Guest';

  @override
  String get navMap => 'Map';

  @override
  String get navReports => 'Field';

  @override
  String get navNews => 'News';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navProfile => 'Profile';

  @override
  String get splashTitle => 'Cam Pha digital space';

  @override
  String get splashSubtitle =>
      'Maps, city information and field services in one app';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to access services for your account.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginAction => 'Sign in';

  @override
  String get forgotPasswordAction => 'Forgot password?';

  @override
  String get noAccount => 'No account yet?';

  @override
  String get registerAction => 'Register';

  @override
  String get registerTitle => 'Create a citizen account';

  @override
  String get registerSubtitle =>
      'One account for field reports and city services.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get phoneLabel => 'Phone number (optional)';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get privacyConsent =>
      'I agree to provide this information to use Cam Pha GIS services.';

  @override
  String get alreadyAccount => 'Already have an account?';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get verificationTitle => 'Check your inbox';

  @override
  String verificationBody(String email) {
    return 'A verification link was sent to $email. Verify your email before signing in.';
  }

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get forgotTitle => 'Recover password';

  @override
  String get forgotSubtitle =>
      'Enter your email. If the account exists, recovery instructions will be sent securely.';

  @override
  String get sendInstructionAction => 'Send instructions';

  @override
  String get forgotSuccessTitle => 'Request received';

  @override
  String get backToLogin => 'Back to sign in';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordSubtitle =>
      'Use 8–128 characters and a password different from the current one.';

  @override
  String get oldPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get changePasswordAction => 'Update password';

  @override
  String get changePasswordSuccess => 'Password changed. Sign in again.';

  @override
  String get profileGuestTitle => 'Explore as a guest';

  @override
  String get profileGuestBody =>
      'Sign in to submit field reports, save drawings and access role-based content.';

  @override
  String get profileAccount => 'Account';

  @override
  String get profilePreferences => 'App experience';

  @override
  String get profileSecurity => 'Security';

  @override
  String get logoutAction => 'Sign out';

  @override
  String get logoutConfirmTitle => 'Sign out from this device?';

  @override
  String get logoutConfirmBody =>
      'Your session and private data on this device will be removed.';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeLabel => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get versionLabel => 'Version';

  @override
  String get mapWelcomeTitle => 'Cam Pha city map';

  @override
  String get mapWelcomeBody => 'Explore the city through an interactive map.';

  @override
  String get mapLoading => 'Loading basemap…';

  @override
  String get mapConfigMissing =>
      'The map is not configured in this environment.';

  @override
  String featureUpcomingTitle(String title) {
    return '$title is being completed';
  }

  @override
  String get featureUpcomingBody =>
      'Foundation and navigation are ready. Live data will be connected in its scheduled Sprint without mock content.';

  @override
  String get reportsIntro =>
      'Track and submit field information across the city.';

  @override
  String get newsIntro => 'Official updates from Cam Pha systems.';

  @override
  String get documentsIntro =>
      'Search documents, reports and PDF maps by access level.';

  @override
  String get cmsDateUnknown => 'Date unavailable';

  @override
  String get cmsClearSearch => 'Clear search';

  @override
  String get cmsStaleData =>
      'Showing previously loaded data; refresh is unavailable.';

  @override
  String get cmsNoSearchResult => 'No results found';

  @override
  String get cmsTryAnotherSearch => 'Try a shorter or different search term.';

  @override
  String get cmsLoadMoreRetry => 'Load next page';

  @override
  String get newsOfficialSource => 'Official Cam Pha news';

  @override
  String get newsSearchHint => 'Search news titles';

  @override
  String get newsOfficialBadge => 'OFFICIAL NEWS';

  @override
  String get newsReadMore => 'Read article';

  @override
  String get newsEmptyTitle => 'No news yet';

  @override
  String get newsEmptyBody => 'Public news will appear here once published.';

  @override
  String get newsDetailTitle => 'News article';

  @override
  String get newsContentEmpty => 'This article has no detailed content yet.';

  @override
  String get cmsShare => 'Share';

  @override
  String get commentsTitle => 'Community comments';

  @override
  String get commentsEmpty => 'No approved comments yet.';

  @override
  String get commentWriteTitle => 'Share feedback';

  @override
  String get commentHint => '1–2000 characters';

  @override
  String get commentLoginBody =>
      'Sign in to comment. You will return to this article afterward.';

  @override
  String get commentSend => 'Send comment';

  @override
  String get commentInvalid => 'Use 1–2000 characters without HTML tags.';

  @override
  String get commentPending =>
      'Your comment was sent and is awaiting moderation.';

  @override
  String get commentSent => 'Your comment was sent.';

  @override
  String get documentsVerifiedSource => 'Verified data library';

  @override
  String get documentsSegment => 'Documents';

  @override
  String get pdfMapsSegment => 'PDF maps';

  @override
  String get documentsSearchHint => 'Search title or document code';

  @override
  String get pdfSearchHint => 'Search PDF map title';

  @override
  String get documentsEmptyTitle => 'No documents yet';

  @override
  String get documentsEmptyBody =>
      'Documents allowed for your account will appear here.';

  @override
  String get pdfEmptyTitle => 'No PDF maps yet';

  @override
  String get pdfEmptyBody => 'Public PDF maps will appear here.';

  @override
  String get documentDetailTitle => 'Document details';

  @override
  String get pdfDetailTitle => 'PDF map details';

  @override
  String get cmsDescription => 'Description';

  @override
  String get documentCodeLabel => 'Document code';

  @override
  String get issuingAgencyLabel => 'Issuing agency';

  @override
  String get issuedDateLabel => 'Issue date';

  @override
  String get scaleLabel => 'Scale';

  @override
  String get mapYearLabel => 'Map year';

  @override
  String get preparingAgencyLabel => 'Preparing agency';

  @override
  String get cmsOpenFile => 'Open with an app on this device';

  @override
  String get cmsShareFile => 'Share temporary link';

  @override
  String get cmsSecureLinkNotice =>
      'A secure link is created only on action and expires automatically.';

  @override
  String get cmsNoFileViewer => 'No compatible file viewer is installed.';

  @override
  String get cmsVisibilityAll => 'All';

  @override
  String get cmsVisibilityPublic => 'Public';

  @override
  String get cmsVisibilityInternal => 'Internal';

  @override
  String get cmsInternalBadge => 'Internal';

  @override
  String get cmsInternalAccessDeniedTitle => 'Internal document';

  @override
  String get cmsInternalAccessDeniedBody =>
      'This content is restricted to authorized staff. Contact an administrator if you need access.';

  @override
  String get mapLayersTitle => 'Map data layers';

  @override
  String mapActiveLayers(int count) {
    return '$count active layers';
  }

  @override
  String get mapDisableAll => 'Disable all';

  @override
  String get mapLayerSearchHint => 'Search data layers';

  @override
  String get mapCatalogStale => 'Using loaded catalog; refresh is unavailable.';

  @override
  String get mapNoLayersFound => 'No matching layers';

  @override
  String get mapBasemapTitle => 'Basemap';

  @override
  String get mapBasemapEmpty => 'No system basemap is available.';

  @override
  String get mapLegendAction => 'View legend';

  @override
  String get mapLegendEmpty => 'This layer has no configured legend.';

  @override
  String get mapSearchTitle => 'Search the map';

  @override
  String get mapSearchHint => 'Find a place or feature';

  @override
  String get mapSearchPrompt =>
      'Enter at least 2 characters to search allowed layers.';

  @override
  String get mapSearchEmpty => 'No matching features found.';

  @override
  String get mapFeatureTitle => 'Feature information';

  @override
  String get mapFeatureId => 'Feature ID';

  @override
  String get mapAttributesTitle => 'Attributes';

  @override
  String get mapAttributesEmpty => 'No attributes are allowed for display.';

  @override
  String get mapGeometryTitle => 'Geometry';

  @override
  String mapGeometryPoints(int count) {
    return '$count coordinate points';
  }

  @override
  String mapLayerRenderError(String name) {
    return 'Unable to display $name.';
  }

  @override
  String get mapTileError => 'A map layer could not load';

  @override
  String get mapRecenter => 'Return to Cam Pha';

  @override
  String get mapGpsAction => 'My location';

  @override
  String mapLayersCount(int count) {
    return 'Data layers ($count)';
  }

  @override
  String get mapInfoAction => 'Identify feature';

  @override
  String get mapTapInfoHint =>
      'Tap a rendered feature to open its information.';

  @override
  String get fieldToolsTitle => 'Field tools';

  @override
  String get fieldToolsSubtitle => 'Location, measurement and GIS analysis';

  @override
  String get locationWeatherTitle => 'Location & weather';

  @override
  String get locationPrimer =>
      'Location is requested only when you continue. No background tracking is used.';

  @override
  String get locationStart => 'Locate me';

  @override
  String get locationServiceOff => 'Location services are disabled.';

  @override
  String get locationDenied => 'Location permission was not granted.';

  @override
  String get locationDeniedForever =>
      'Location permission is blocked. Open settings to enable it.';

  @override
  String get locationOpenSettings => 'Open settings';

  @override
  String get locationOutsideBounds =>
      'Location is outside the supported Cam Pha area.';

  @override
  String locationAccuracy(String meters) {
    return 'Accuracy ±$meters m';
  }

  @override
  String locationAccuracyLow(String meters) {
    return 'Low accuracy · ±$meters m uncertainty';
  }

  @override
  String get locationAccuracyUnavailable =>
      'Accuracy information is unavailable.';

  @override
  String get weatherUnavailable => 'Weather is unavailable right now.';

  @override
  String get weatherTemperature => 'Temperature';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherObserved => 'Observed';

  @override
  String get nearbyTitle => 'Nearby features';

  @override
  String get nearbyEmpty => 'No features were found within the current radius.';

  @override
  String nearbyDistance(String meters) {
    return '$meters m away';
  }

  @override
  String get measureTitle => 'Measure';

  @override
  String get measureDistance => 'Distance';

  @override
  String get measureArea => 'Area';

  @override
  String get measureTapHint => 'Tap the map to add measurement points';

  @override
  String measurePointCount(int count) {
    return '$count points';
  }

  @override
  String get measureUndo => 'Undo';

  @override
  String get measureRedo => 'Redo';

  @override
  String get measureComplete => 'Confirm measurement';

  @override
  String get measureOfficial => 'System verified';

  @override
  String measureLengthResult(String value) {
    return '$value m';
  }

  @override
  String measureAreaResult(String value) {
    return '$value m²';
  }

  @override
  String get routeTitle => 'Directions';

  @override
  String get routeSelectHint =>
      'Tap the map to select start then end. Mapbox calculates the route.';

  @override
  String get routeStart => 'Start';

  @override
  String get routeEnd => 'End';

  @override
  String get routeUseGps => 'Use current location';

  @override
  String get routeSwap => 'Swap endpoints';

  @override
  String get routeFind => 'Find route';

  @override
  String get routeSourceMapbox => 'Routing source: Mapbox';

  @override
  String routeDistance(String value) {
    return 'Length $value m';
  }

  @override
  String get fieldToolSheetDragHint => 'Swipe up for more, down to see the map';

  @override
  String get routeInstructionFallback => 'Continue along the route';

  @override
  String get fieldToolCancel => 'Exit tool';

  @override
  String get reportsTitle => 'Field reports';

  @override
  String get reportsSubtitle =>
      'Track community-observed changes across Cam Pha';

  @override
  String get reportCreate => 'Submit report';

  @override
  String get myReports => 'My reports';

  @override
  String get reportListView => 'List';

  @override
  String get reportMapView => 'Map';

  @override
  String get reportStale =>
      'Showing the latest available data. Pull down to retry.';

  @override
  String get reportStatusAll => 'All';

  @override
  String get reportStatusPending => 'Pending';

  @override
  String get reportStatusReview => 'Under review';

  @override
  String get reportStatusApproved => 'Verified';

  @override
  String get reportStatusRejected => 'Rejected';

  @override
  String get reportStatusResolved => 'Resolved';

  @override
  String get reportPublicEmpty => 'No public reports yet.';

  @override
  String get reportFilteredEmpty => 'No reports match these filters.';

  @override
  String reportDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String reportHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String reportMinutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String get reportEvidenceStep => 'Evidence';

  @override
  String get reportLocationStep => 'Location';

  @override
  String get reportDescriptionStep => 'Description';

  @override
  String get reportEvidenceHint => 'Add 1–5 PNG or WebP photos';

  @override
  String get reportCamera => 'Take photo';

  @override
  String get reportGallery => 'Choose photos';

  @override
  String get reportLocationHint => 'Tap the map to place or adjust the pin';

  @override
  String get reportDescriptionHint =>
      'Describe the situation in 10–2000 characters';

  @override
  String get reportTruthConfirm =>
      'I confirm this information and evidence are truthful.';

  @override
  String get reportNext => 'Continue';

  @override
  String get reportBack => 'Back';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get reportUploadPresign => 'Preparing upload';

  @override
  String get reportUploadUploading => 'Uploading photo';

  @override
  String get reportUploadCommit => 'Running safety checks';

  @override
  String get reportUploadReady => 'Photo ready';

  @override
  String get reportDraftRestored => 'Unsent report restored';

  @override
  String get reportDelete => 'Delete report';

  @override
  String get reportDeleteConfirm =>
      'Delete this report? This action cannot be undone.';

  @override
  String get reportHistory => 'Status timeline';

  @override
  String get reportPhotos => 'Photo evidence';

  @override
  String get reportReviewReason => 'Review response';

  @override
  String get reportNearby30Days => 'Near me · 30 days';

  @override
  String get featureEditTitle => 'Edit feature';

  @override
  String get featureEditForbidden =>
      'This account cannot edit authoritative data.';

  @override
  String get featureEditUnavailable =>
      'This feature or version cannot be edited.';

  @override
  String get featureInvalidValue => 'Value has wrong type or exceeds limit.';

  @override
  String get featureUnsavedTitle => 'Discard unsaved changes?';

  @override
  String get featureUnsavedBody =>
      'Changed attributes or geometry will be lost.';

  @override
  String get featureDiscard => 'Discard';

  @override
  String get featureVertices => 'vertices';

  @override
  String get featureVersion => 'Version';

  @override
  String get featureCurrent => 'Current';

  @override
  String get featureSaveNow => 'Save to server';

  @override
  String get featureSaveOffline => 'Save to offline queue';

  @override
  String get featureHistoryTitle => 'Feature history';

  @override
  String get featureHistoryEmpty => 'No version history yet.';

  @override
  String get featureGeometryChanged => 'Geometry updated';

  @override
  String get featureActionUpdate => 'Updated';

  @override
  String get featureActionRestore => 'Restored';

  @override
  String get featureActionChanged => 'Changed';

  @override
  String get featureRestoreTitle => 'Restore version';

  @override
  String featureRestoreCreatesVersion(int version) {
    return 'Restoring version $version creates a new version and does not overwrite history.';
  }

  @override
  String get featureRestoreAction => 'Restore';

  @override
  String get featureRestoreSuccess => 'New restored version created.';

  @override
  String get featureSyncTitle => 'Offline changes';

  @override
  String get featureSyncNow => 'Sync now';

  @override
  String get featureSyncEmpty => 'No offline changes.';

  @override
  String get featurePending => 'Pending';

  @override
  String get featureConflicts => 'Conflicts';

  @override
  String get featureRejected => 'Rejected';

  @override
  String get featureServerVersion => 'Server version';

  @override
  String get featureUndo => 'Undo last vertex';

  @override
  String get featureConflictTitle => 'Feature changed';

  @override
  String get featureConflictBody =>
      'Server has a newer version. It cannot be overwritten. Reload server data or keep this change in the offline queue.';

  @override
  String get featureReloadServer => 'Reload server data';

  @override
  String get reportNearbyFilterTitle => 'Reports near current location';

  @override
  String get reportNearbyDateRange => 'Date range';

  @override
  String reportNearbyRadius(int meters) {
    return 'Radius: $meters m';
  }

  @override
  String get reportNearbyApply => 'Use current location';

  @override
  String get featureChangedBy => 'Changed by';

  @override
  String get brandTagline => 'The city at your fingertips';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get emailRequired => 'Enter your email';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get passwordMinLength => 'Password must contain at least 8 characters';

  @override
  String get passwordMaxLength => 'Password cannot exceed 128 characters';

  @override
  String get passwordMustDiffer =>
      'New password must differ from the current password';

  @override
  String get fullNameMinLength =>
      'Full name must contain at least 2 characters';

  @override
  String get fullNameMaxLength => 'Full name cannot exceed 255 characters';

  @override
  String get privacyConsentRequired => 'Confirm consent before registering';

  @override
  String mapActiveTool(String name) {
    return 'Active: $name';
  }

  @override
  String mapLayerOpacity(int percent) {
    return 'Visibility $percent%';
  }

  @override
  String get measureDistanceRequired =>
      'Tap 1 more point to start measuring distance.';

  @override
  String get measureAreaRequired =>
      'Tap more points to create an area measurement.';

  @override
  String get routeStartRequired => 'Select a start point on the map.';

  @override
  String get routeEndRequired => 'Select an end point on the map.';

  @override
  String routeEstimatedMinutes(int minutes) {
    return 'Estimated time: $minutes min';
  }

  @override
  String routeMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get draftPoint => 'Point';

  @override
  String get draftLine => 'Line';

  @override
  String get draftPolygon => 'Area';

  @override
  String reportStepProgress(int current, int total, String title) {
    return 'Step $current/$total · $title';
  }

  @override
  String get reportDraftAutosaved =>
      'This draft is saved automatically on this device.';

  @override
  String get reportEvidenceRequired => 'Add at least 1 photo to continue.';

  @override
  String get reportLocationRequired => 'Choose a location to continue.';

  @override
  String get reportDescriptionRequired =>
      'Enter a description with at least 10 characters.';

  @override
  String get reportTruthRequired =>
      'Confirm the information is truthful before submitting.';

  @override
  String get reportCameraPrimerTitle => 'Allow camera access?';

  @override
  String get reportCameraPrimerBody =>
      'The camera opens only after you continue to capture evidence. The app never captures or records in the background.';

  @override
  String get reportCameraPermissionDenied =>
      'Camera permission was not granted. Open settings to enable it.';

  @override
  String get reportPhotoLimit => 'The 5-photo evidence limit has been reached.';

  @override
  String reportPhotoPosition(int current, int total) {
    return 'Photo $current of $total';
  }

  @override
  String get locationLocating => 'Locating…';

  @override
  String get featureNoChanges =>
      'Change at least one attribute or coordinate before saving.';

  @override
  String get featureLongitude => 'Longitude';

  @override
  String get featureLatitude => 'Latitude';

  @override
  String get featureCoordinateOutOfBounds =>
      'Coordinates must be inside Cam Pha.';

  @override
  String get featureDiscardOfflineTitle => 'Delete offline change?';

  @override
  String get featureDiscardOfflineBody =>
      'This unsynced change will be removed from the device and cannot be recovered.';

  @override
  String get featureSyncDiscardAction => 'Delete change';

  @override
  String get featureSyncing => 'Syncing';

  @override
  String get featureSyncRejectedReason =>
      'This change cannot be synced. Review its data or remove it from the queue.';

  @override
  String get reportDiscardDraftTitle => 'Delete report draft?';

  @override
  String get reportDiscardDraftBody =>
      'Unsaved photos, location, and description will be removed from this device and cannot be recovered.';
}
