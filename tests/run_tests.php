<?php
require_once __DIR__ . '/../database.php';

$results = [];

function assertSameValue($expected, $actual, $label) {
    global $results;
    if ($expected !== $actual) {
        $results[] = ['ok' => false, 'label' => $label, 'message' => 'Expected ' . var_export($expected, true) . ' got ' . var_export($actual, true)];
        return;
    }
    $results[] = ['ok' => true, 'label' => $label, 'message' => ''];
}

$monitorPerms = roleDefaultPermissions(ROLE_TODA_MONITOR);
assertSameValue(true, in_array(PERM_TRIPS_VIEW, $monitorPerms, true), 'TODA monitor can view trip history');
assertSameValue(true, in_array(PERM_RATINGS_VIEW, $monitorPerms, true), 'TODA monitor can view ratings');
assertSameValue(false, in_array(PERM_COMMUTERS_VIEW, $monitorPerms, true), 'TODA monitor sidebar no longer exposes commuters');
assertSameValue(true, in_array(PERM_VERIFICATION_VIEW, $monitorPerms, true), 'TODA monitor can view validation records');

$_SESSION['admin_role'] = ROLE_TODA_MONITOR;
$_SESSION['admin_toda_id'] = 'bulanao_norte';
assertSameValue('toda_dashboard.php', getDashboardRouteForCurrentUser(), 'TODA monitor dashboard route uses dedicated file');
assertSameValue('toda_ratings.php', getRatingsRouteForCurrentUser(), 'TODA monitor ratings route uses dedicated file');
assertSameValue('toda_drivers.php', getDriversRouteForCurrentUser(), 'TODA monitor drivers route uses dedicated file');

$_SESSION['admin_role'] = ROLE_BPLO_VERIFIER;
$_SESSION['admin_toda_id'] = null;
assertSameValue('bplo_dashboard.php', getDashboardRouteForCurrentUser(), 'BPLO dashboard route uses dedicated file');
assertSameValue('ratings.php', getRatingsRouteForCurrentUser(), 'BPLO ratings route stays on shared ratings file');

$_SESSION['admin_role'] = ROLE_SUPER_ADMIN;
$_SESSION['admin_toda_id'] = null;
assertSameValue('dashboard.php', getDashboardRouteForCurrentUser(), 'Super admin dashboard route stays on main dashboard');
assertSameValue('drivers.php', getDriversRouteForCurrentUser(), 'Super admin drivers route stays on shared drivers file');

$_SESSION['admin_role'] = ROLE_TODA_ADMIN;
$_SESSION['admin_toda_id'] = 'bulanao_centro';
assertSameValue('toda_drivers.php', getDriversRouteForCurrentUser(), 'TODA admin drivers route uses dedicated file');

$onlineDriver = ['isOnline' => true, 'accountStatus' => 'validated', 'isDriverActive' => false];
assertSameValue(true, isDriverOnlineRecord($onlineDriver, 2000000), 'Explicit online flag marks driver online');

$offlineValidatedDriver = ['accountStatus' => 'validated', 'validationStatus' => 'approved', 'isDriverActive' => false];
assertSameValue(false, isDriverOnlineRecord($offlineValidatedDriver, 2000000), 'Approved driver is not online without live flag');

$recentPresenceDriver = ['presence' => ['lastSeen' => 1999]];
assertSameValue(true, isDriverOnlineRecord($recentPresenceDriver, 2000000, 5000), 'Recent presence timestamp marks driver online');

$documents = getDriverValidationDocuments('demo-driver', [
    'validationIdUrl' => 'https://example.com/driver-id.jpg',
    'validationPermitUrl' => 'https://example.com/permit.jpg',
], [
    'documents' => [
        'selfieUrl' => 'https://example.com/selfie.jpg',
    ],
]);
assertSameValue('https://example.com/driver-id.jpg', $documents['idUrl'], 'Validation document resolver keeps direct ID URL');
assertSameValue('https://example.com/permit.jpg', $documents['permitUrl'], 'Validation document resolver keeps direct permit URL');
assertSameValue('https://example.com/selfie.jpg', $documents['selfieUrl'], 'Validation document resolver falls back to driver_validations node');

$sampleDrivers = [
    'd1' => ['todaId' => 'bulanao_norte', 'accountStatus' => 'validated', 'isDriverActive' => true],
    'd2' => ['todaId' => 'bulanao_norte', 'accountStatus' => 'pending', 'isDriverActive' => false],
    'd3' => ['todaId' => 'bulanao_centro', 'accountStatus' => 'validated', 'isDriverActive' => true],
];
$northDriverStats = getDriverStatisticsForToda('bulanao_norte', $sampleDrivers);
assertSameValue(2, $northDriverStats['totalDrivers'], 'Scoped driver stats count only selected TODA drivers');
assertSameValue(1, $northDriverStats['pendingDrivers'], 'Scoped driver stats keep pending count within TODA');

$sampleRatings = [
    'd1' => ['todaId' => 'bulanao_norte', 'ratingCount' => 2, 'currentRating' => 4.5],
    'd2' => ['todaId' => 'bulanao_norte', 'ratingCount' => 0, 'currentRating' => 0],
    'd3' => ['todaId' => 'bulanao_centro', 'ratingCount' => 1, 'currentRating' => 3.0],
];
$northRatingStats = getRatingStatisticsForToda('bulanao_norte', $sampleRatings);
assertSameValue(2, $northRatingStats['totalDrivers'], 'Scoped rating stats count only drivers in selected TODA');
assertSameValue(1, $northRatingStats['ratedDrivers'], 'Scoped rating stats count only rated drivers in selected TODA');

$normalizedSelectedIds = normalizeSelectedIds([' d1 ', 'd1', '', 'd2']);
assertSameValue(['d1', 'd2'], $normalizedSelectedIds, 'Bulk selection normalization trims empties and duplicates');

$bulkDeleteResult = bulkDeleteRecords(['a', 'b', 'a', ''], function($id) {
    return $id !== 'b';
});
assertSameValue(2, $bulkDeleteResult['requested'], 'Bulk delete counts unique selected ids');
assertSameValue(1, $bulkDeleteResult['deleted'], 'Bulk delete counts successful deletions');
assertSameValue(1, $bulkDeleteResult['failed'], 'Bulk delete counts failed deletions');

$invalidBulkDelete = bulkDeleteRecords(['only'], 'not_a_real_callback');
assertSameValue(1, $invalidBulkDelete['failed'], 'Bulk delete reports invalid callbacks as failed deletions');

$feedbackComment = extractFeedbackCommentText(['comments' => 'Comment: Driver was polite']);
assertSameValue('Driver was polite', $feedbackComment, 'Feedback helper strips the Comment prefix from ride records');
assertSameValue('', extractFeedbackCommentText('Comment: '), 'Feedback helper ignores empty passenger comments');

$feedbackRecords = buildTripCommentFeedbackRecords([
    'trip123' => [
        'driverId' => 'd1',
        'driverName' => 'Driver One',
        'userName' => 'Passenger One',
        'userPhone' => '09123',
        'comments' => 'Comment: safe ride',
        'accepted_at' => 1762270073973,
        'status' => 'ended',
        'fareAmount' => '15.0',
        'originAddress' => 'Origin',
        'destinationAddress' => 'Destination',
    ],
    'commentOnly' => 'Comment: raw feedback node',
    'blank' => 'Comment: ',
], [], [], [], [], []);
assertSameValue(true, isset($feedbackRecords['trip_comment_trip123']), 'Trip comment feedback builder creates a record for ride comments');
assertSameValue('safe ride', $feedbackRecords['trip_comment_trip123']['comment'], 'Trip comment feedback builder stores normalized passenger comments');
assertSameValue(true, isset($feedbackRecords['trip_comment_trip123_commentOnly']), 'Trip comment feedback builder attaches sibling raw comment nodes to the latest trip context');
assertSameValue('Driver One', $feedbackRecords['trip_comment_trip123_commentOnly']['driverName'], 'Attached raw comment nodes inherit the trip driver name');
assertSameValue('Passenger One', $feedbackRecords['trip_comment_trip123_commentOnly']['commuterName'], 'Attached raw comment nodes inherit the trip passenger name');
assertSameValue(false, isset($feedbackRecords['trip_comment_blank']), 'Trip comment feedback builder skips blank passenger comments');

$orphanFeedbackRecords = buildTripCommentFeedbackRecords([
    'commentOnly' => 'Comment: raw feedback node',
], [], [], [], [], []);
assertSameValue(true, isset($orphanFeedbackRecords['trip_comment_commentOnly']), 'Trip comment feedback builder still supports standalone raw comment nodes');

$resolvedFeedbackRecords = buildTripCommentFeedbackRecords([
    'trip456' => [
        'driverId' => 'driver42',
        'userId' => 'user77',
        'userPhone' => '09999',
        'comments' => 'Comment: great trip',
        'accepted_at' => 1762270073973,
        'status' => 'ended',
        'fareAmount' => '15.0',
        'originAddress' => 'Origin',
        'destinationAddress' => 'Destination',
    ],
], [], [], ['driver42' => 'Resolved Driver'], ['user77' => 'Resolved Passenger'], ['09999' => 'Phone Passenger']);
assertSameValue('Resolved Driver', $resolvedFeedbackRecords['trip_comment_trip456']['driverName'], 'Trip comment feedback builder resolves missing driver names from the driver index');
assertSameValue('Resolved Passenger', $resolvedFeedbackRecords['trip_comment_trip456']['commuterName'], 'Trip comment feedback builder resolves missing passenger names from the passenger index');
$passengerFeedbackAccessorMarkup = file_get_contents(__DIR__ . '/../database.php');
assertSameValue(true, strpos($passengerFeedbackAccessorMarkup, 'function getPassengerCommentFeedbackRecords()') !== false, 'Passenger comment accessor exists in the data layer');

firebaseRequestCacheWrite('drivers/demo', ['name' => 'Demo']);
$cacheFound = false;
$cachedValue = firebaseRequestCacheRead('drivers/demo', $cacheFound);
assertSameValue(true, $cacheFound, 'Firebase request cache reads previously written values');
assertSameValue('Demo', $cachedValue['name'], 'Firebase request cache preserves cached payloads');
firebaseRequestCacheClear('drivers');
$cacheFoundAfterClear = false;
firebaseRequestCacheRead('drivers/demo', $cacheFoundAfterClear);
assertSameValue(false, $cacheFoundAfterClear, 'Firebase request cache clear removes nested cached entries');

$sidebarMarkup = file_get_contents(__DIR__ . '/../sidebar.php');
assertSameValue(true, strpos($sidebarMarkup, '<span>TODAs</span>') !== false, 'Sidebar uses the shorter TODAs label for aligned navigation');
assertSameValue(true, strpos($sidebarMarkup, 'assets/sidebar.css?v=19') !== false, 'Sidebar loads cached external sidebar CSS');
assertSameValue(true, strpos($sidebarMarkup, 'assets/sidebar.js?v=19') !== false, 'Sidebar loads cached external sidebar JavaScript');
assertSameValue(true, strpos($sidebarMarkup, '!$isTodaMonitor && hasPermission(PERM_COMMUTERS_VIEW)') !== false, 'Sidebar hides commuters for TODA monitor accounts');
assertSameValue(true, strpos($sidebarMarkup, '$dashboardHref = getDashboardRouteForCurrentUser();') !== false, 'Sidebar uses role-aware dashboard routing');
assertSameValue(true, strpos($sidebarMarkup, '$driversHref = getDriversRouteForCurrentUser();') !== false, 'Sidebar uses role-aware driver routing');
assertSameValue(true, strpos($sidebarMarkup, '<span>Feedback</span>') !== false, 'Sidebar exposes the feedback page when the role has feedback access');
assertSameValue(false, strpos($sidebarMarkup, 'Admin Panel') !== false, 'Sidebar no longer shows the old Admin Panel header text');
assertSameValue(false, strpos($sidebarMarkup, 'Management dashboard') !== false, 'Sidebar no longer shows the old management dashboard subtitle');
assertSameValue(true, strpos($sidebarMarkup, '🛺') !== false, 'Sidebar branding uses the login-page tricycle icon');
assertSameValue(false, strpos($sidebarMarkup, 'admin_users.php') !== false, 'Sidebar no longer links to the admin users page');
assertSameValue(true, file_exists(__DIR__ . '/../assets/sidebar.css'), 'External sidebar stylesheet exists');
assertSameValue(true, file_exists(__DIR__ . '/../assets/sidebar.js'), 'External sidebar JavaScript exists');

assertSameValue(true, file_exists(__DIR__ . '/../toda_dashboard.php'), 'Dedicated TODA dashboard file exists');
assertSameValue(true, file_exists(__DIR__ . '/../toda_ratings.php'), 'Dedicated TODA ratings file exists');
assertSameValue(true, file_exists(__DIR__ . '/../toda_drivers.php'), 'Dedicated TODA drivers file exists');
assertSameValue(true, file_exists(__DIR__ . '/../bplo_dashboard.php'), 'Dedicated BPLO dashboard file exists');

$adminUsersMarkup = file_get_contents(__DIR__ . '/../admin_users.php');
assertSameValue(true, strpos($adminUsersMarkup, "Location: toda_management.php") !== false, 'Admin users page now redirects into TODA management');

$todaManagementMarkup = file_get_contents(__DIR__ . '/../toda_management.php');
assertSameValue(true, strpos($todaManagementMarkup, 'Create TODA Account') !== false, 'TODA management includes a dedicated TODA account creation form');
assertSameValue(true, strpos($todaManagementMarkup, 'Monitoring All TODAs') !== false, 'TODA management includes monitoring for all TODAs');
assertSameValue(false, strpos($todaManagementMarkup, '<h3 style="margin-bottom:10px;">Create TODA</h3>') !== false, 'TODA management no longer renders the old create TODA form');

$tripsMarkup = file_get_contents(__DIR__ . '/../trips.php');
assertSameValue(false, strpos($tripsMarkup, 'Filter Trips') !== false, 'Trip management no longer renders the filter panel');
assertSameValue(false, strpos($tripsMarkup, 'toggleFilter()') !== false, 'Trip management no longer renders the filter toggle control');

$todaDashboardMarkup = file_get_contents(__DIR__ . '/../toda_dashboard.php');
assertSameValue(false, strpos($todaDashboardMarkup, 'Quick Overview') !== false, 'TODA dashboard no longer shows the quick overview card');

$themeMarkup = file_get_contents(__DIR__ . '/../ui_theme.php');
$themeCssMarkup = file_get_contents(__DIR__ . '/../assets/ui-theme.css');
assertSameValue(true, strpos($themeMarkup, 'assets/ui-theme.css?v=19') !== false, 'Shared UI theme now loads cached external CSS');
assertSameValue(true, strpos($themeCssMarkup, '--app-bg: linear-gradient(135deg, #2c3e50 0%, #3498db 100%);') !== false, 'Shared UI theme CSS keeps the restored v6 login background gradient');
assertSameValue(true, strpos($themeCssMarkup, 'background: linear-gradient(135deg, #3498db 0%, #2980b9 100%)') !== false, 'Shared UI theme CSS keeps the restored v6 login button gradient');
assertSameValue(true, strpos($themeCssMarkup, '.header {') !== false, 'Shared UI theme CSS styles page headers as consistent surface cards');
assertSameValue(true, strpos($themeCssMarkup, 'overflow-x: hidden !important;') !== false, 'Shared UI theme CSS prevents horizontal overflow for phone layouts');
assertSameValue(true, strpos($themeCssMarkup, '@media (max-width: 768px) {') !== false, 'Shared UI theme CSS includes a dedicated phone breakpoint');
assertSameValue(true, strpos($themeCssMarkup, '.drivers-table-container,') !== false, 'Shared UI theme CSS makes record tables horizontally scrollable on smaller screens');
assertSameValue(true, file_exists(__DIR__ . '/../assets/ui-theme.css'), 'External shared UI theme stylesheet exists');

$driversMarkup = file_get_contents(__DIR__ . '/../drivers.php');
assertSameValue(true, strpos($driversMarkup, 'driverPaginationResult = paginateAssociativeArray') !== false, 'Drivers page paginates records before rendering');
$ratingsMarkup = file_get_contents(__DIR__ . '/../ratings.php');
assertSameValue(true, strpos($ratingsMarkup, 'ratingsPaginationResult = paginateAssociativeArray') !== false, 'Ratings page paginates records before rendering');
$commutersMarkup = file_get_contents(__DIR__ . '/../commuters.php');
assertSameValue(true, strpos($commutersMarkup, 'commuterPaginationResult = paginateAssociativeArray') !== false, 'Commuters page paginates records before rendering');
$todaRatingsMarkup = file_get_contents(__DIR__ . '/../toda_ratings.php');
assertSameValue(true, strpos($todaRatingsMarkup, 'todaRatingsPaginationResult = paginateAssociativeArray') !== false, 'Dedicated TODA ratings page paginates records before rendering');
$feedbackMarkup = file_get_contents(__DIR__ . '/../feedback.php');
assertSameValue(true, strpos($feedbackMarkup, 'feedbackPaginationResult = paginateAssociativeArray') !== false, 'Feedback page paginates records before rendering');
assertSameValue(true, strpos($feedbackMarkup, 'getPassengerCommentFeedbackRecords()') !== false, 'Feedback page reads passenger comments only');
assertSameValue(true, strpos($feedbackMarkup, '<th>Driver Name</th>') !== false, 'Feedback page shows a dedicated driver name column');
assertSameValue(true, strpos($feedbackMarkup, '<th>Passenger Name</th>') !== false, 'Feedback page shows a dedicated passenger name column');
assertSameValue(false, strpos($feedbackMarkup, 'Create Feedback (Manual)') !== false, 'Feedback page no longer renders manual feedback creation');
assertSameValue(false, strpos($feedbackMarkup, 'Manual admin feedback is combined') !== false, 'Feedback page no longer mixes manual admin feedback copy');


$bootstrapMarkup = file_get_contents(__DIR__ . '/../app_bootstrap.php');
assertSameValue(true, strpos($bootstrapMarkup, "ob_start('ob_gzhandler')") !== false, 'Bootstrap enables gzip output compression when supported');
assertSameValue(true, strpos($bootstrapMarkup, "define('APP_DEBUG'") !== false, 'Bootstrap defines a central APP_DEBUG flag');
assertSameValue(true, file_exists(__DIR__ . '/../app_bootstrap.php'), 'Shared bootstrap file exists');

assertSameValue(true, strpos($passengerFeedbackAccessorMarkup, 'function paginateAssociativeArray(') !== false, 'Data layer exposes shared pagination helper');
assertSameValue(true, strpos($passengerFeedbackAccessorMarkup, 'function buildQueryUrl(') !== false, 'Data layer exposes shared query URL helper');
assertSameValue(true, strpos($passengerFeedbackAccessorMarkup, 'function appRequestMemo(') !== false, 'Data layer exposes request memoization helper');
assertSameValue(true, strpos($passengerFeedbackAccessorMarkup, 'firebase_trip_collection_path') !== false, 'Data layer remembers the preferred Firebase trip collection path');
assertSameValue(true, strpos($passengerFeedbackAccessorMarkup, 'function getAllUsers()') !== false, 'Data layer exposes a memoized all-users helper');
assertSameValue(true, strpos($passengerFeedbackAccessorMarkup, 'function extractTripsFromCollection($data)') !== false, 'Data layer exposes a shared trip collection extractor');
assertSameValue(true, strpos($passengerFeedbackAccessorMarkup, "return appRequestMemo('driver_display_list'") !== false, 'Data layer memoizes the formatted drivers list');
assertSameValue(true, strpos($passengerFeedbackAccessorMarkup, "return appRequestMemo('dashboard_total_counts'") !== false, 'Data layer memoizes dashboard totals');

$paginatedSample = paginateAssociativeArray(['a' => 1, 'b' => 2, 'c' => 3], 2, 2);
assertSameValue(['c' => 3], $paginatedSample['items'], 'Pagination helper slices associative arrays while preserving keys');
assertSameValue(2, $paginatedSample['pagination']['current_page'], 'Pagination helper reports the current page correctly');
assertSameValue(true, $paginatedSample['pagination']['has_previous'], 'Pagination helper reports previous-page availability');
assertSameValue(false, $paginatedSample['pagination']['has_next'], 'Pagination helper reports next-page availability on the last page');

$loginMarkup = file_get_contents(__DIR__ . '/../index.php');
$loginCssMarkup = file_get_contents(__DIR__ . '/../assets/login.css');
assertSameValue(true, strpos($loginMarkup, '🛺 Kaltrike Admin') !== false, 'Login page restores the v6 branding');
assertSameValue(true, strpos($loginMarkup, 'assets/login.css?v=16') !== false, 'Login page now loads cached external CSS');
assertSameValue(true, strpos($loginCssMarkup, 'background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%)') !== false, 'Login stylesheet restores the v6 gradient design');
assertSameValue(true, file_exists(__DIR__ . '/../assets/login.css'), 'External login stylesheet exists');

$failed = array_values(array_filter($results, function($result) {
    return !$result['ok'];
}));

foreach ($results as $result) {
    echo ($result['ok'] ? '[PASS] ' : '[FAIL] ') . $result['label'];
    if ($result['message'] !== '') {
        echo ' - ' . $result['message'];
    }
    echo PHP_EOL;
}

exit(count($failed) > 0 ? 1 : 0);
