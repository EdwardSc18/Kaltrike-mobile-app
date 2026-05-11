<?php
// database.php - Firebase Realtime Database Connection
require_once __DIR__ . '/app_bootstrap.php';

// Firebase Configuration
define('FIREBASE_URL', 'https://kaltrikedriverapp-default-rtdb.firebaseio.com/');

// OPTIONAL: If your Firebase rules require auth, put your database secret / token here.
// If not required, leave blank.
if (!defined('FIREBASE_AUTH')) {
    define('FIREBASE_AUTH', '');
}

// ======================================================
// ADMIN AUTH (Firebase-backed users + RBAC)
// ======================================================

// Bootstrap (first-login) super admin credentials.
// NOTE: On first login, a Firebase admin user will be auto-created using these values.
define('DEFAULT_SUPERADMIN_USERNAME', 'admin');
define('DEFAULT_SUPERADMIN_PASSWORD', 'admin123'); // CHANGE THIS IN PRODUCTION

// Firebase nodes
define('FB_NODE_ADMIN_USERS', 'adminUsers');
define('FB_NODE_TODAS', 'todas');
define('FB_NODE_AUDIT_LOGS', 'auditLogs');
define('FB_NODE_FEEDBACK', 'feedback');

// Roles
define('ROLE_SUPER_ADMIN', 'SUPER_ADMIN');
define('ROLE_TODA_ADMIN', 'TODA_ADMIN');
define('ROLE_TODA_STAFF', 'TODA_STAFF');
define('ROLE_TODA_MONITOR', 'TODA_MONITOR');
define('ROLE_BPLO_VERIFIER', 'BPLO_VERIFIER');
define('ROLE_AUDITOR', 'AUDITOR');

// Permissions (string identifiers)
define('PERM_DASHBOARD_VIEW', 'dashboard.view');
define('PERM_DRIVERS_VIEW', 'drivers.view');
define('PERM_DRIVERS_MANAGE', 'drivers.manage');
define('PERM_DRIVERS_EDIT', 'drivers.edit');
define('PERM_TRIPS_VIEW', 'trips.view');
define('PERM_TRIPS_MANAGE', 'trips.manage');
define('PERM_RATINGS_VIEW', 'ratings.view');
define('PERM_RATINGS_MANAGE', 'ratings.manage');
define('PERM_COMMUTERS_VIEW', 'commuters.view');
define('PERM_FEEDBACK_VIEW', 'feedback.view');
define('PERM_FEEDBACK_MANAGE', 'feedback.manage');
define('PERM_REPORTS_GENERATE', 'reports.generate');
define('PERM_VERIFICATION_VIEW', 'verification.view');
define('PERM_VERIFICATION_MANAGE', 'verification.manage');
define('PERM_ADMIN_USERS_MANAGE', 'admin_users.manage');
define('PERM_TODAS_MANAGE', 'todas.manage');

function roleDefaultPermissions($role) {
    switch ($role) {
        case ROLE_SUPER_ADMIN:
            return ['*'];

        case ROLE_TODA_ADMIN:
            return [
                PERM_DASHBOARD_VIEW,
                PERM_DRIVERS_VIEW, PERM_DRIVERS_MANAGE,
                PERM_TRIPS_VIEW, PERM_TRIPS_MANAGE,
                PERM_RATINGS_VIEW, PERM_RATINGS_MANAGE,
                PERM_COMMUTERS_VIEW,
                PERM_FEEDBACK_VIEW, PERM_FEEDBACK_MANAGE,
                PERM_REPORTS_GENERATE,
            ];

        case ROLE_TODA_MONITOR:
            return [
                PERM_DASHBOARD_VIEW,
                PERM_DRIVERS_VIEW,
                PERM_TRIPS_VIEW,
                PERM_RATINGS_VIEW,
                PERM_VERIFICATION_VIEW,
            ];

        case ROLE_TODA_STAFF:
                return [
                    PERM_DASHBOARD_VIEW,
                    PERM_DRIVERS_VIEW,
                    PERM_TRIPS_VIEW,
                    PERM_RATINGS_VIEW,
                    PERM_COMMUTERS_VIEW,
                    PERM_FEEDBACK_VIEW, PERM_FEEDBACK_MANAGE,
                ];

        case ROLE_BPLO_VERIFIER:
            return [
                PERM_DASHBOARD_VIEW,
                PERM_DRIVERS_VIEW,
                PERM_DRIVERS_EDIT,
                PERM_VERIFICATION_VIEW, PERM_VERIFICATION_MANAGE,
            ];

        case ROLE_AUDITOR:
        default:
            return [
                PERM_DASHBOARD_VIEW,
                PERM_DRIVERS_VIEW,
                PERM_TRIPS_VIEW, PERM_TRIPS_MANAGE,
                PERM_RATINGS_VIEW, PERM_RATINGS_MANAGE,
                PERM_COMMUTERS_VIEW,
                PERM_FEEDBACK_VIEW,
                PERM_REPORTS_GENERATE,
                PERM_VERIFICATION_VIEW,
            ];
    }
}

function ensureDefaultSuperAdminExists() {
    // Create a predictable record to avoid duplicates
    $existing = firebaseGet(FB_NODE_ADMIN_USERS . '/superadmin');

    if (is_array($existing) && !empty($existing['username'])) {
        return true;
    }

    $data = [
        'username' => DEFAULT_SUPERADMIN_USERNAME,
        'email' => '',
        'role' => ROLE_SUPER_ADMIN,
        'todaId' => null,
        'permissions' => roleDefaultPermissions(ROLE_SUPER_ADMIN),
        'active' => true,
        'createdAt' => (int)(microtime(true) * 1000),
        'passwordHash' => password_hash(DEFAULT_SUPERADMIN_PASSWORD, PASSWORD_DEFAULT)
    ];

    return firebaseSet(FB_NODE_ADMIN_USERS . '/superadmin', $data);
}

function ensureSeedTodosAndUsersExists() {
    // Seed TODAs
    $seedTodas = [
        'bulanao_norte' => ['name' => 'Bulanao Norte', 'code' => 'BN'],
        'bulanao_centro' => ['name' => 'Bulanao Centro', 'code' => 'BC'],
    ];

    foreach ($seedTodas as $tid => $t) {
        $existing = firebaseGet(FB_NODE_TODAS . '/' . $tid);
        if (!is_array($existing) || empty($existing['name'])) {
            $payload = [
                'name' => $t['name'],
                'code' => $t['code'],
                'active' => true,
                'createdAt' => (int)(microtime(true) * 1000),
                'seeded' => true,
            ];
            firebaseSet(FB_NODE_TODAS . '/' . $tid, $payload);
        }
    }

    // Seed Admin Users
    $seedUsers = [
        // TODA monitor accounts (view-only, scoped per TODA)
        'toda_bulanao_norte' => [
            'username' => 'bulanao norte',
            'role' => ROLE_TODA_MONITOR,
            'todaId' => 'bulanao_norte',
            'password' => 'norte123',
        ],
        'toda_bulanao_centro' => [
            'username' => 'bulanao centro',
            'role' => ROLE_TODA_MONITOR,
            'todaId' => 'bulanao_centro',
            'password' => 'centro123',
        ],
        // BPLO verifier (can edit driver compliance fields)
        'bplo' => [
            'username' => 'BPLO',
            'role' => ROLE_BPLO_VERIFIER,
            'todaId' => null,
            'password' => 'bplo123',
        ],
    ];

    foreach ($seedUsers as $uid => $u) {
        $existing = firebaseGet(FB_NODE_ADMIN_USERS . '/' . $uid);
        if (is_array($existing) && !empty($existing['username'])) {
            // Keep existing passwordHash if already set; but ensure role/permissions match
            $update = [
                'username' => $u['username'],
                'role' => $u['role'],
                'todaId' => $u['todaId'],
                'permissions' => roleDefaultPermissions($u['role']),
                'active' => true,
                'seeded' => true,
                'updatedAt' => (int)(microtime(true) * 1000),
            ];
            firebaseUpdate(FB_NODE_ADMIN_USERS . '/' . $uid, $update);
            continue;
        }

        $payload = [
            'username' => $u['username'],
            'email' => '',
            'role' => $u['role'],
            'todaId' => $u['todaId'],
            'permissions' => roleDefaultPermissions($u['role']),
            'active' => true,
            'createdAt' => (int)(microtime(true) * 1000),
            'seeded' => true,
            'passwordHash' => password_hash($u['password'], PASSWORD_DEFAULT),
        ];
        firebaseSet(FB_NODE_ADMIN_USERS . '/' . $uid, $payload);
    }

    return true;
}



function getAllAdminUsers() {
    return appRequestMemo('all_admin_users', function () {
        $users = firebaseGet(FB_NODE_ADMIN_USERS);
        return is_array($users) ? $users : [];
    });
}

function findAdminUserByIdentifier($identifier) {
    $identifier = trim((string)$identifier);
    if ($identifier === '') return null;

    $users = getAllAdminUsers();
    foreach ($users as $id => $u) {
        if (!is_array($u)) continue;

        $username = strtolower(trim((string)($u['username'] ?? '')));
        $email = strtolower(trim((string)($u['email'] ?? '')));
        $needle = strtolower($identifier);

        if ($needle === $username || ($email !== '' && $needle === $email)) {
            $u['id'] = $id;
            return $u;
        }
    }

    return null;
}

function authenticateAdmin($identifier, $password) {
    ensureDefaultSuperAdminExists();
    ensureSeedTodosAndUsersExists();

    $user = findAdminUserByIdentifier($identifier);
    if (!$user || !is_array($user)) return false;

    if (empty($user['active'])) return false;

    $hash = (string)($user['passwordHash'] ?? '');
    if ($hash === '' || !password_verify((string)$password, $hash)) {
        return false;
    }

    $_SESSION['admin_logged_in'] = true;
    $_SESSION['admin_id'] = $user['id'] ?? null;
    $_SESSION['admin_username'] = $user['username'] ?? $identifier;
    $_SESSION['admin_email'] = $user['email'] ?? '';
    $_SESSION['admin_role'] = $user['role'] ?? ROLE_AUDITOR;
    $_SESSION['admin_toda_id'] = $user['todaId'] ?? null;
    $_SESSION['admin_permissions'] = is_array($user['permissions'] ?? null) ? $user['permissions'] : roleDefaultPermissions($_SESSION['admin_role']);
    $_SESSION['login_time'] = time();

    return true;
}

// ======================================================
// AUTH / SESSION HELPERS
// ======================================================

function isLoggedIn() {
    return isAdminLoggedIn();
}

function adminLogin($usernameOrEmail, $password) {
    return authenticateAdmin($usernameOrEmail, $password);
}

function adminLogout() {
    session_unset();
    session_destroy();
    return true;
}

// Check session timeout (30 minutes)
function checkSessionTimeout() {
    if (isset($_SESSION['login_time'])) {
        $timeout = 30 * 60;
        if (time() - $_SESSION['login_time'] > $timeout) {
            adminLogout();
            return false;
        }
        $_SESSION['login_time'] = time();
    }
    return true;
}

function isAdminLoggedIn() {
    if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
        return false;
    }
    return checkSessionTimeout();
}

function requireAdminAuth() {
    if (!isAdminLoggedIn()) {
        header('Location: index.php');
        exit();
    }
}

// ======================================================
// RBAC HELPERS
// ======================================================

function currentAdminRole() {
    return $_SESSION['admin_role'] ?? ROLE_AUDITOR;
}

function currentAdminTodaId() {
    return $_SESSION['admin_toda_id'] ?? null;
}

function isTodaMonitor() {
    return currentAdminRole() === ROLE_TODA_MONITOR;
}

function isBploVerifier() {
    return currentAdminRole() === ROLE_BPLO_VERIFIER;
}

function getDashboardRouteForCurrentUser() {
    if (isBploVerifier()) return 'bplo_dashboard.php';
    if (isTodaMonitor() && !empty(currentAdminTodaId())) return 'toda_dashboard.php';
    return 'dashboard.php';
}

function getRatingsRouteForCurrentUser() {
    if (isTodaMonitor() && !empty(currentAdminTodaId())) return 'toda_ratings.php';
    return 'ratings.php';
}

function getDriversRouteForCurrentUser() {
    if (isTodaScopedAdmin()) return 'toda_drivers.php';
    return 'drivers.php';
}

function isSuperAdmin() {
    return currentAdminRole() === ROLE_SUPER_ADMIN;
}

function hasPermission($perm) {
    if (isSuperAdmin()) return true;

    $perms = $_SESSION['admin_permissions'] ?? [];
    if (!is_array($perms)) $perms = [];

    return in_array('*', $perms, true) || in_array($perm, $perms, true);
}

function requirePermission($perm) {
    if (!hasPermission($perm)) {
        http_response_code(403);
        echo "<h3 style='font-family:Segoe UI,Tahoma,sans-serif'>403 - Forbidden</h3>";
        echo "<p>You do not have permission to perform this action.</p>";
        exit();
    }
}

function canAccessToda($todaId) {
    if (isSuperAdmin()) return true;

    $role = currentAdminRole();

    // BPLO can view across TODAs for verification/compliance, but actions should still be guarded by permissions
    if ($role === ROLE_BPLO_VERIFIER) return true;

    $myTodaId = currentAdminTodaId();
    if ($myTodaId === null) return false;

    return (string)$myTodaId === (string)$todaId;
}

function requireTodaAccess($todaId) {
    if (!canAccessToda($todaId)) {
        http_response_code(403);
        echo "<h3 style='font-family:Segoe UI,Tahoma,sans-serif'>403 - Forbidden</h3>";
        echo "<p>You do not have access to this TODA's records.</p>";
        exit();
    }
}

function normalizeSelectedIds($selectedIds) {
    if (!is_array($selectedIds)) {
        $selectedIds = [$selectedIds];
    }

    $normalized = [];
    foreach ($selectedIds as $selectedId) {
        $selectedId = trim((string)$selectedId);
        if ($selectedId === '') continue;
        $normalized[$selectedId] = true;
    }

    return array_keys($normalized);
}

function bulkDeleteRecords($selectedIds, $deleteCallback) {
    $ids = normalizeSelectedIds($selectedIds);

    $result = [
        'requested' => count($ids),
        'deleted' => 0,
        'failed' => 0,
        'selected_ids' => $ids,
    ];

    if ($result['requested'] === 0) {
        return $result;
    }

    if (!is_callable($deleteCallback)) {
        $result['failed'] = $result['requested'];
        return $result;
    }

    foreach ($ids as $id) {
        if (call_user_func($deleteCallback, $id)) {
            $result['deleted']++;
        } else {
            $result['failed']++;
        }
    }

    return $result;
}

// ======================================================
// TODA HELPERS
// ======================================================

function getAllTodas() {
    return appRequestMemo('all_todas', function () {
        $todas = firebaseGet(FB_NODE_TODAS);
        return is_array($todas) ? $todas : [];
    });
}

function getTodaName($todaId) {
    if (empty($todaId)) return 'Unassigned';

    $cache = getAllTodas();

    if (isset($cache[$todaId]['name'])) return (string)$cache[$todaId]['name'];
    if (isset($cache[$todaId]['todaName'])) return (string)$cache[$todaId]['todaName'];

    return (string)$todaId;
}


function isTodaScopedAdmin() {
    return !isSuperAdmin() && currentAdminRole() !== ROLE_BPLO_VERIFIER && !empty(currentAdminTodaId());
}

function getDriversForToda($todaId = null, $drivers = null) {
    if ($drivers === null) {
        $drivers = getAllDrivers();
    }

    if (!is_array($drivers)) {
        return [];
    }

    if ($todaId === null || $todaId === '') {
        return $drivers;
    }

    return array_filter($drivers, function($driver) use ($todaId) {
        return is_array($driver) && (string)($driver['todaId'] ?? '') === (string)$todaId;
    });
}

function getRegisteredDriverCount($todaId = null, $drivers = null) {
    return count(getDriversForToda($todaId, $drivers));
}

function getDriverStatisticsForToda($todaId = null, $drivers = null) {
    $drivers = getDriversForToda($todaId, $drivers);

    $stats = [
        'totalDrivers' => 0,
        'activeDrivers' => 0,
        'pendingDrivers' => 0,
        'validatedDrivers' => 0
    ];

    if (!is_array($drivers) || empty($drivers)) {
        return $stats;
    }

    $stats['totalDrivers'] = count($drivers);

    foreach ($drivers as $driver) {
        if (!is_array($driver)) continue;

        $status = strtolower((string)($driver['accountStatus'] ?? ($driver['status'] ?? 'pending')));

        if (!empty($driver['isDriverActive'])) $stats['activeDrivers']++;
        if ($status === 'pending') $stats['pendingDrivers']++;
        if (in_array($status, ['validated', 'active', 'approved'], true)) $stats['validatedDrivers']++;
    }

    return $stats;
}

function getTripsForToda($todaId = null, $trips = null, $indexById = null, $indexByPhone = null) {
    if ($trips === null) {
        $trips = getAllTrips();
    }

    if (!is_array($trips)) {
        return [];
    }

    if ($todaId === null || $todaId === '') {
        return $trips;
    }

    if ($indexById === null || $indexByPhone === null) {
        [$indexById, $indexByPhone] = buildDriverTodaIndex();
    }

    return array_filter($trips, function($trip) use ($todaId, $indexById, $indexByPhone) {
        return is_array($trip) && (string)getTripTodaId($trip, $indexById, $indexByPhone) === (string)$todaId;
    });
}

function getTripStatisticsForToda($todaId = null, $trips = null) {
    $trips = getTripsForToda($todaId, $trips);

    $stats = [
        'totalTrips' => 0,
        'completedTrips' => 0,
        'activeTrips' => 0,
        'pendingTrips' => 0,
        'cancelledTrips' => 0,
        'totalRevenue' => 0,
        'averageFare' => 0,
        'ridesharingTrips' => 0,
        'todaysTrips' => 0,
        'todayRevenue' => 0
    ];

    if (!is_array($trips) || empty($trips)) {
        return $stats;
    }

    $stats['totalTrips'] = count($trips);
    $totalFares = 0;
    $completedCount = 0;
    $today = date('Y-m-d');

    foreach ($trips as $trip) {
        if (!is_array($trip)) continue;

        $status = strtolower((string)($trip['status'] ?? 'unknown'));
        $fare = (float)($trip['fareAmount'] ?? $trip['fare'] ?? $trip['price'] ?? 0);
        $tripTime = parseTimestamp($trip['time'] ?? $trip['timestamp'] ?? $trip['createdAt'] ?? null);
        $passengerCount = (int)($trip['passengerCount'] ?? $trip['passengers'] ?? 1);

        if (in_array($status, ['completed', 'ended', 'finished'], true)) {
            $stats['completedTrips']++;
            $stats['totalRevenue'] += $fare;
            $completedCount++;
        } elseif (in_array($status, ['active', 'ongoing', 'in_progress'], true)) {
            $stats['activeTrips']++;
        } elseif (in_array($status, ['pending', 'requested', 'waiting'], true)) {
            $stats['pendingTrips']++;
        } elseif (in_array($status, ['cancelled', 'canceled', 'rejected'], true)) {
            $stats['cancelledTrips']++;
        }

        $totalFares += $fare;

        if ($passengerCount > 1) {
            $stats['ridesharingTrips']++;
        }

        if ($tripTime && date('Y-m-d', $tripTime) === $today) {
            $stats['todaysTrips']++;
            if (in_array($status, ['completed', 'ended', 'finished'], true)) {
                $stats['todayRevenue'] += $fare;
            }
        }
    }

    if ($stats['totalTrips'] > 0) {
        $stats['averageFare'] = round($totalFares / $stats['totalTrips'], 2);
    }

    return $stats;
}

function getRatingsForToda($todaId = null, $ratings = null) {
    if ($ratings === null) {
        $ratings = getAllRatings();
    }

    if (!is_array($ratings)) {
        return [];
    }

    if ($todaId === null || $todaId === '') {
        return $ratings;
    }

    return array_filter($ratings, function($rating) use ($todaId) {
        return is_array($rating) && (string)($rating['todaId'] ?? '') === (string)$todaId;
    });
}

function getRatingStatisticsForToda($todaId = null, $ratings = null) {
    $drivers = getRatingsForToda($todaId, $ratings);

    $stats = [
        'totalDrivers' => count($drivers),
        'ratedDrivers' => 0,
        'unratedDrivers' => 0,
        'averageRating' => 0,
        'topRatedCount' => 0,
        'lowRatedCount' => 0
    ];

    $sum = 0;

    foreach ($drivers as $driver) {
        $count = (int)($driver['ratingCount'] ?? 0);
        $rating = (float)($driver['currentRating'] ?? 0);

        if ($count > 0) {
            $stats['ratedDrivers']++;
            $sum += $rating;

            if ($rating >= 4.5) $stats['topRatedCount']++;
            if ($rating > 0 && $rating < 3.0) $stats['lowRatedCount']++;
        } else {
            $stats['unratedDrivers']++;
        }
    }

    if ($stats['ratedDrivers'] > 0) {
        $stats['averageRating'] = round($sum / $stats['ratedDrivers'], 1);
    }

    return $stats;
}

function normalizeBooleanFlag($value) {
    if (is_bool($value)) return $value;
    if (is_int($value) || is_float($value)) return ((float)$value) > 0;

    if (is_string($value)) {
        $normalized = strtolower(trim($value));
        if ($normalized === '') return null;

        if (in_array($normalized, ['1', 'true', 'yes', 'online', 'active', 'available'], true)) {
            return true;
        }

        if (in_array($normalized, ['0', 'false', 'no', 'offline', 'inactive', 'unavailable'], true)) {
            return false;
        }
    }

    return null;
}

function extractOnlineTimestampMs($driver) {
    if (!is_array($driver)) return null;

    $timestampKeys = ['lastSeen', 'lastActive', 'lastOnlineAt', 'onlineAt', 'presenceUpdatedAt'];

    foreach ($timestampKeys as $key) {
        if (isset($driver[$key])) {
            $ts = parseTimestamp($driver[$key]);
            if ($ts) return $ts * 1000;
        }
    }

    if (isset($driver['presence']) && is_array($driver['presence'])) {
        foreach ($timestampKeys as $key) {
            if (isset($driver['presence'][$key])) {
                $ts = parseTimestamp($driver['presence'][$key]);
                if ($ts) return $ts * 1000;
            }
        }
    }

    return null;
}

function isDriverOnlineRecord($driver, $nowMs = null, $graceMs = 300000) {
    if (!is_array($driver)) return false;

    $explicitKeys = ['isOnline', 'online', 'driverOnline', 'isDriverOnline'];
    foreach ($explicitKeys as $key) {
        if (array_key_exists($key, $driver)) {
            $flag = normalizeBooleanFlag($driver[$key]);
            if ($flag !== null) return $flag;
        }
    }

    if (isset($driver['presence']) && is_array($driver['presence'])) {
        foreach ($explicitKeys as $key) {
            if (array_key_exists($key, $driver['presence'])) {
                $flag = normalizeBooleanFlag($driver['presence'][$key]);
                if ($flag !== null) return $flag;
            }
        }
    }

    $timestampMs = extractOnlineTimestampMs($driver);
    if ($timestampMs !== null) {
        $nowMs = $nowMs !== null ? (int)$nowMs : (int)(microtime(true) * 1000);
        return ($nowMs - $timestampMs) <= $graceMs;
    }

    $fallback = normalizeBooleanFlag($driver['isDriverActive'] ?? null);
    return $fallback === true;
}

function extractFirstUrlFromArrayByKeywords($data, $keywords) {
    if (!is_array($data)) return '';

    foreach ($data as $key => $value) {
        $normalizedKey = strtolower(preg_replace('/[^a-z0-9]/', '', (string)$key));

        if (is_string($value) && preg_match('/^https?:\/\//i', $value)) {
            foreach ($keywords as $keyword) {
                if (strpos($normalizedKey, $keyword) !== false) {
                    return $value;
                }
            }
        }

        if (is_array($value)) {
            $found = extractFirstUrlFromArrayByKeywords($value, $keywords);
            if ($found !== '') return $found;
        }
    }

    return '';
}

function getDriverValidationDocuments($driverId, $driver = null, $validationNode = null) {
    if ($driver === null) {
        $driver = getDriverById($driverId);
    }
    if (!is_array($driver)) {
        $driver = [];
    }

    if ($validationNode === null && !empty($driverId)) {
        $validationNode = firebaseGet('driver_validations/' . $driverId);
    }

    $documents = [
        'idUrl' => '',
        'permitUrl' => '',
        'selfieUrl' => '',
    ];

    $documents['idUrl'] =
        $driver['validationIdUrl'] ??
        ($driver['idDocumentUrl'] ?? '') ?: '';

    $documents['permitUrl'] =
        $driver['validationPermitUrl'] ??
        ($driver['permitDocumentUrl'] ?? '') ?: '';

    $documents['selfieUrl'] =
        $driver['validationSelfieUrl'] ??
        ($driver['selfieDocumentUrl'] ?? '') ?: '';

    if ($documents['idUrl'] === '') {
        $documents['idUrl'] = extractFirstUrlFromArrayByKeywords($validationNode, ['validationidurl', 'idurl', 'iddocument', 'governmentid', 'validid', 'frontid', 'backid']);
    }

    if ($documents['permitUrl'] === '') {
        $documents['permitUrl'] = extractFirstUrlFromArrayByKeywords($validationNode, ['validationpermiturl', 'permiturl', 'permitdocument', 'businesspermit', 'permit']);
    }

    if ($documents['selfieUrl'] === '') {
        $documents['selfieUrl'] = extractFirstUrlFromArrayByKeywords($validationNode, ['validationselfieurl', 'selfieurl', 'driverselfie', 'selfie']);
    }

    return $documents;
}

// ======================================================
// AUDIT LOGGING
// ======================================================

function auditLog($action, $entityType, $entityId = '', $details = []) {
    $logId = 'log_' . uniqid();

    $payload = [
        'action' => (string)$action,
        'entityType' => (string)$entityType,
        'entityId' => (string)$entityId,
        'details' => $details,
        'actorId' => $_SESSION['admin_id'] ?? null,
        'actorUsername' => $_SESSION['admin_username'] ?? null,
        'actorRole' => $_SESSION['admin_role'] ?? null,
        'timestamp' => (int)(microtime(true) * 1000),
    ];

    return firebaseSet(FB_NODE_AUDIT_LOGS . '/' . $logId, $payload);
}
// ======================================================
// FIREBASE URL BUILDER (FIXES SPACES LIKE "All Ride Requests")
// ======================================================
function firebaseBuildUrl($path) {
    $base = rtrim(FIREBASE_URL, '/');
    $path = trim((string)$path, '/');

    // Root
    if ($path === '') {
        $url = $base . '/.json';
    } else {
        // Encode each segment so spaces become %20 and won't break requests
        $segments = explode('/', $path);
        $segments = array_map('rawurlencode', $segments);
        $url = $base . '/' . implode('/', $segments) . '.json';
    }

    // Add auth token if provided
    if (!empty(FIREBASE_AUTH)) {
        $url .= '?auth=' . urlencode(FIREBASE_AUTH);
    }

    return $url;
}

// ======================================================
// FIREBASE REST API HELPERS
// ======================================================

function firebaseRequestCacheKey($path) {
    return trim((string)$path, '/');
}

function &firebaseRequestCacheStore() {
    static $cache = [];
    return $cache;
}


function &appRequestMemoStore() {
    static $memo = [];
    return $memo;
}

function appRequestMemo($key, $resolver) {
    $memo =& appRequestMemoStore();
    if (array_key_exists($key, $memo)) {
        return $memo[$key];
    }

    $memo[$key] = is_callable($resolver) ? $resolver() : null;
    return $memo[$key];
}

function appRequestMemoForget($prefix = null) {
    $memo =& appRequestMemoStore();

    if ($prefix === null || $prefix === '') {
        $memo = [];
        return;
    }

    foreach (array_keys($memo) as $key) {
        if ($key === $prefix || strpos($key, $prefix . ':') === 0 || strpos($key, $prefix . '|') === 0) {
            unset($memo[$key]);
        }
    }
}

function prioritizeFirebaseNodePaths($paths, $sessionKey) {
    $ordered = array_values(array_unique(array_filter(array_map('strval', (array)$paths), function ($path) {
        return $path !== '';
    })));

    if (session_status() === PHP_SESSION_ACTIVE) {
        $preferred = trim((string)($_SESSION[$sessionKey] ?? ''));
        if ($preferred !== '' && in_array($preferred, $ordered, true)) {
            $ordered = array_values(array_unique(array_merge([$preferred], $ordered)));
        }
    }

    return $ordered;
}

function rememberFirebasePreferredNode($sessionKey, $path) {
    if (session_status() === PHP_SESSION_ACTIVE && is_string($path) && trim($path) !== '') {
        $_SESSION[$sessionKey] = trim($path);
    }
}

function firebaseRequestCacheClear($path = null) {
    $cache =& firebaseRequestCacheStore();

    if ($path === null) {
        $cache = [];
        appRequestMemoForget();
        return;
    }

    $needle = firebaseRequestCacheKey($path);
    foreach (array_keys($cache) as $key) {
        if ($key === $needle || strpos($key, $needle . '/') === 0 || ($needle !== '' && strpos($needle, $key . '/') === 0)) {
            unset($cache[$key]);
        }
    }
}

function firebaseRequestCacheRead($path, &$found = false) {
    $cache =& firebaseRequestCacheStore();
    $key = firebaseRequestCacheKey($path);
    if (array_key_exists($key, $cache)) {
        $found = true;
        return $cache[$key];
    }
    $found = false;
    return null;
}

function firebaseRequestCacheWrite($path, $value) {
    $cache =& firebaseRequestCacheStore();
    $cache[firebaseRequestCacheKey($path)] = $value;
    return $value;
}

function firebaseGet($path) {
    try {
        $found = false;
        $cached = firebaseRequestCacheRead($path, $found);
        if ($found) {
            return $cached;
        }

        $url = firebaseBuildUrl($path);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if (curl_errno($ch)) {
            error_log("CURL Error for path $path: " . curl_error($ch));
            curl_close($ch);
            return firebaseRequestCacheWrite($path, []);
        }

        curl_close($ch);

        if ($httpCode == 200) {
            $data = json_decode($response, true);
            return firebaseRequestCacheWrite($path, $data !== null ? $data : []);
        }

        error_log("Firebase GET error: HTTP $httpCode - Path: $path - Response: $response");
        return firebaseRequestCacheWrite($path, []);
    } catch (Exception $e) {
        error_log("Firebase GET exception: " . $e->getMessage());
        return firebaseRequestCacheWrite($path, []);
    }
}

function firebaseSet($path, $data) {
    try {
        $url = firebaseBuildUrl($path);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PUT");
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if (curl_errno($ch)) {
            error_log("CURL Error for path $path: " . curl_error($ch));
            curl_close($ch);
            return false;
        }

        curl_close($ch);

        $ok = $httpCode == 200 || $httpCode == 204;
        if ($ok) { firebaseRequestCacheClear($path); appRequestMemoForget(); }
        return $ok;
    } catch (Exception $e) {
        error_log("Firebase SET exception: " . $e->getMessage());
        return false;
    }
}

function firebaseUpdate($path, $data) {
    try {
        $url = firebaseBuildUrl($path);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PATCH");
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if (curl_errno($ch)) {
            error_log("CURL Error for path $path: " . curl_error($ch));
            curl_close($ch);
            return false;
        }

        curl_close($ch);

        $ok = $httpCode == 200 || $httpCode == 204;
        if ($ok) { firebaseRequestCacheClear($path); appRequestMemoForget(); }
        return $ok;
    } catch (Exception $e) {
        error_log("Firebase UPDATE exception: " . $e->getMessage());
        return false;
    }
}

function firebaseDelete($path) {
    try {
        $url = firebaseBuildUrl($path);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "DELETE");
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if (curl_errno($ch)) {
            error_log("CURL Error for path $path: " . curl_error($ch));
            curl_close($ch);
            return false;
        }

        curl_close($ch);

        $ok = $httpCode == 200 || $httpCode == 204;
        if ($ok) { firebaseRequestCacheClear($path); appRequestMemoForget(); }
        return $ok;
    } catch (Exception $e) {
        error_log("Firebase DELETE exception: " . $e->getMessage());
        return false;
    }
}

// ======================================================
// HELPER FUNCTIONS
// ======================================================

function buildQueryUrl($overrides = [], $basePath = null, $source = null) {
    $query = is_array($source) ? $source : $_GET;

    foreach ((array)$overrides as $key => $value) {
        if ($value === null || $value === '') {
            unset($query[$key]);
        } else {
            $query[$key] = $value;
        }
    }

    $target = $basePath ?: basename($_SERVER['PHP_SELF'] ?? '');
    $target = $target !== '' ? $target : '';

    return $target . (!empty($query) ? ('?' . http_build_query($query)) : '');
}

function paginateAssociativeArray($items, $page = 1, $perPage = 20) {
    if (!is_array($items)) {
        $items = [];
    }

    $page = max(1, (int)$page);
    $perPage = max(1, min(100, (int)$perPage));
    $totalItems = count($items);
    $totalPages = max(1, (int)ceil($totalItems / $perPage));
    $page = min($page, $totalPages);
    $offset = ($page - 1) * $perPage;

    return [
        'items' => array_slice($items, $offset, $perPage, true),
        'pagination' => [
            'current_page' => $page,
            'per_page' => $perPage,
            'total_items' => $totalItems,
            'total_pages' => $totalPages,
            'offset' => $offset,
            'has_previous' => $page > 1,
            'has_next' => $page < $totalPages,
        ],
    ];
}

function getAllUsers() {
    return appRequestMemo('all_users', function () {
        $users = firebaseGet('users');
        return is_array($users) ? $users : [];
    });
}

function parseTimestamp($timestamp) {
    if (empty($timestamp)) return null;

    if (is_numeric($timestamp)) {
        $t = (float)$timestamp;
        return ($t > 1000000000000) ? (int)($t / 1000) : (int)$t;
    }

    if (is_string($timestamp)) {
        $parsed = strtotime($timestamp);
        return $parsed !== false ? $parsed : null;
    }

    return null;
}

function extractDateFromTimestamp($timestamp) {
    if (empty($timestamp)) return null;

    $t = parseTimestamp($timestamp);
    if ($t) return date('Y-m-d', $t);

    return null;
}

function getTripFare($trip) {
    if (isset($trip['fareAmount']) && is_numeric($trip['fareAmount'])) return floatval($trip['fareAmount']);
    if (isset($trip['fare']) && is_numeric($trip['fare'])) return floatval($trip['fare']);
    if (isset($trip['price']) && is_numeric($trip['price'])) return floatval($trip['price']);
    return 0;
}


function buildDriverTodaIndex() {
    return appRequestMemo('driver_toda_index', function () {
        $drivers = getAllDrivers();
        $byId = [];
        $byPhone = [];

        foreach ($drivers as $driverId => $d) {
            if (!is_array($d)) continue;

            $todaId = $d['todaId'] ?? null;
            if (!empty($todaId)) {
                $byId[$driverId] = $todaId;

                $phone = $d['phone'] ?? '';
                if (!empty($phone)) $byPhone[$phone] = $todaId;
            }
        }

        return [$byId, $byPhone];
    });
}

function getTripTodaId($trip, $indexById = null, $indexByPhone = null) {
    if (!is_array($trip)) return null;

    if ($indexById === null || $indexByPhone === null) {
        [$indexById, $indexByPhone] = buildDriverTodaIndex();
    }

    $driverId = $trip['driverId'] ?? $trip['driver_id'] ?? '';
    if ($driverId !== '' && isset($indexById[$driverId])) return $indexById[$driverId];

    $driverPhone = $trip['driverPhone'] ?? $trip['driver_phone'] ?? $trip['phone'] ?? '';
    if ($driverPhone !== '' && isset($indexByPhone[$driverPhone])) return $indexByPhone[$driverPhone];

    return null;
}

// ======================================================
// TRIP MANAGEMENT
// ======================================================

function isTripData($data) {
    if (!is_array($data) || empty($data)) return false;

    // IMPORTANT:
    // Your old isTripData() matched "status" only, which exists in drivers/users too.
    // This new logic reduces false positives.

    $hasPassenger = (
        isset($data['userName']) || isset($data['user_name']) || isset($data['passengerName']) ||
        isset($data['userPhone']) || isset($data['user_phone']) || isset($data['passengerPhone'])
    );

    $hasDriver = (
        isset($data['driverName']) || isset($data['driver_name']) ||
        isset($data['driverPhone']) || isset($data['driver_phone']) ||
        isset($data['driverId']) || isset($data['driver_id'])
    );

    $hasRoute = (
        isset($data['originAddress']) || isset($data['destinationAddress']) ||
        isset($data['origin']) || isset($data['destination'])
    );

    $hasFare = (isset($data['fareAmount']) || isset($data['fare']) || isset($data['price']));
    $hasStatus = (isset($data['status']) || isset($data['tripStatus']));

    $score = 0;
    if ($hasPassenger) $score++;
    if ($hasDriver) $score++;
    if ($hasRoute) $score++;
    if ($hasFare) $score++;
    if ($hasStatus) $score++;

    // Require at least 3 categories to consider it a real trip
    return $score >= 3;
}

function extractTripsFromCollection($data) {
    $trips = [];

    if (!is_array($data) || empty($data)) {
        return $trips;
    }

    foreach ($data as $itemId => $itemData) {
        if (is_array($itemData) && isTripData($itemData)) {
            $trips[$itemId] = $itemData;
        } elseif (is_array($itemData)) {
            foreach ($itemData as $nestedId => $nestedData) {
                if (is_array($nestedData) && isTripData($nestedData)) {
                    $trips[$nestedId] = $nestedData;
                }
            }
        }
    }

    return $trips;
}

function getAllTrips() {
    return appRequestMemo('all_trips', function () {
        $possiblePaths = prioritizeFirebaseNodePaths([
            'All Ride Requests',
            'rides',
            'trips',
            'RideRequests',
            'ride_requests',
            'Ride_Requests',
            'rideRequests'
        ], 'firebase_trip_collection_path');

        foreach ($possiblePaths as $path) {
            $trips = extractTripsFromCollection(firebaseGet($path));
            if (!empty($trips)) {
                rememberFirebasePreferredNode('firebase_trip_collection_path', $path);
                return $trips;
            }
        }

        return [];
    });
}

function getTripById($tripId) {
    if (empty($tripId)) return null;

    return appRequestMemo('trip_by_id:' . $tripId, function () use ($tripId) {
        $basePaths = prioritizeFirebaseNodePaths([
            'All Ride Requests',
            'rides',
            'trips',
            'RideRequests',
            'ride_requests',
            'Ride_Requests',
            'rideRequests'
        ], 'firebase_trip_collection_path');

        $locations = [];
        foreach ($basePaths as $basePath) {
            $locations[] = $basePath . '/' . $tripId;
        }
        $locations[] = $tripId;

        foreach ($locations as $location) {
            $trip = firebaseGet($location);
            if (!empty($trip) && is_array($trip) && isTripData($trip)) {
                $base = explode('/', $location)[0] ?? '';
                if ($base !== '' && $base !== $tripId) {
                    rememberFirebasePreferredNode('firebase_trip_collection_path', $base);
                }
                return $trip;
            }
        }

        return null;
    });
}

function getTripStatistics() {
    $trips = getAllTrips();

    $stats = [
        'totalTrips' => 0,
        'completedTrips' => 0,
        'activeTrips' => 0,
        'pendingTrips' => 0,
        'cancelledTrips' => 0,
        'totalRevenue' => 0,
        'averageFare' => 0,
        'ridesharingTrips' => 0,
        'todaysTrips' => 0,
        'todayRevenue' => 0
    ];

    if (is_array($trips) && count($trips) > 0) {
        $stats['totalTrips'] = count($trips);

        $totalFares = 0;
        $completedCount = 0;
        $today = date('Y-m-d');

        foreach ($trips as $tripId => $trip) {
            if (!is_array($trip)) continue;

            $status = strtolower($trip['status'] ?? 'unknown');

            switch ($status) {
                case 'ended':
                case 'completed':
                case 'finished':
                    $stats['completedTrips']++;
                    $completedCount++;
                    break;
                case 'pending':
                case 'requested':
                case 'waiting':
                    $stats['pendingTrips']++;
                    break;
                case 'accepted':
                case 'ongoing':
                case 'active':
                case 'started':
                    $stats['activeTrips']++;
                    break;
                case 'cancelled':
                case 'canceled':
                case 'rejected':
                    $stats['cancelledTrips']++;
                    break;
                default:
                    $stats['pendingTrips']++;
            }

            $fare = getTripFare($trip);

            if (in_array($status, ['ended','completed','finished'])) {
                $stats['totalRevenue'] += $fare;
                $totalFares += $fare;
            }

            if (isset($trip['rideSharing'])) {
                $rideSharingValue = strtolower((string)$trip['rideSharing']);
                if (in_array($rideSharingValue, ['yes', 'true', '1', 'enabled'])) {
                    $stats['ridesharingTrips']++;
                }
            }

            $tripTime = $trip['time'] ?? $trip['timestamp'] ?? $trip['createdAt'] ?? '';
            $tripDate = extractDateFromTimestamp($tripTime);

            if ($tripDate && $tripDate === $today) {
                $stats['todaysTrips']++;
                if (in_array($status, ['ended','completed','finished'])) {
                    $stats['todayRevenue'] += $fare;
                }
            }
        }

        if ($completedCount > 0) {
            $stats['averageFare'] = round($totalFares / $completedCount, 2);
        }
    }

    return $stats;
}

function getTripsPaginated($page = 1, $perPage = 20, $searchTerm = '', $sortBy = 'time', $sortOrder = 'desc', $filters = []) {
    $allTrips = getAllTrips();

    // Build driver->TODA indexes once for TODA filtering
    [$todaByDriverId, $todaByPhone] = buildDriverTodaIndex();

    if (!empty($searchTerm)) {
        $allTrips = searchTrips($searchTerm);
    }

    $filteredTrips = [];

    if (!empty($filters)) {
        foreach ($allTrips as $tripId => $trip) {
            if (!is_array($trip)) continue;

            $includeTrip = true;

            if (!empty($filters['start_date'])) {
                $tripTime = $trip['time'] ?? $trip['timestamp'] ?? $trip['createdAt'] ?? '';
                $tripDate = extractDateFromTimestamp($tripTime);
                if ($tripDate && $tripDate < $filters['start_date']) $includeTrip = false;
            }

            if (!empty($filters['end_date']) && $includeTrip) {
                $tripTime = $trip['time'] ?? $trip['timestamp'] ?? $trip['createdAt'] ?? '';
                $tripDate = extractDateFromTimestamp($tripTime);
                if ($tripDate && $tripDate > $filters['end_date']) $includeTrip = false;
            }

            if (!empty($filters['status_filter']) && $includeTrip) {
                $tripStatus = strtolower($trip['status'] ?? '');
                $filterStatus = strtolower($filters['status_filter']);
                if ($tripStatus !== $filterStatus) $includeTrip = false;
            }

            if (!empty($filters['toda_id']) && $includeTrip) {
                $tripToda = getTripTodaId($trip, $todaByDriverId, $todaByPhone);
                if ((string)$tripToda !== (string)$filters['toda_id']) $includeTrip = false;
            }

            if (isset($filters['min_fare']) && is_numeric($filters['min_fare']) && $includeTrip) {
                $fare = getTripFare($trip);
                if ($fare < floatval($filters['min_fare'])) $includeTrip = false;
            }

            if (isset($filters['max_fare']) && is_numeric($filters['max_fare']) && $includeTrip) {
                $fare = getTripFare($trip);
                if ($fare > floatval($filters['max_fare'])) $includeTrip = false;
            }

            if ($includeTrip) $filteredTrips[$tripId] = $trip;
        }
    } else {
        $filteredTrips = $allTrips;
    }

    $sortedTrips = sortTrips($filteredTrips, $sortBy, $sortOrder);

    $totalItems = count($sortedTrips);
    $totalPages = (int)ceil($totalItems / $perPage);

    $page = max(1, min($page, $totalPages > 0 ? $totalPages : 1));
    $offset = ($page - 1) * $perPage;

    $paginatedTrips = array_slice($sortedTrips, $offset, $perPage, true);

    return [
        'trips' => $paginatedTrips,
        'pagination' => [
            'current_page' => $page,
            'total_pages' => $totalPages > 0 ? $totalPages : 1,
            'total_items' => $totalItems,
            'per_page' => $perPage,
            'offset' => $offset,
            'has_previous' => $page > 1,
            'has_next' => $page < $totalPages
        ]
    ];
}

function searchTrips($searchTerm) {
    $trips = getAllTrips();
    $results = [];

    if (empty($searchTerm) || !is_array($trips) || count($trips) === 0) {
        return $trips;
    }

    $searchTermLower = strtolower(trim($searchTerm));

    foreach ($trips as $tripId => $trip) {
        if (!is_array($trip)) continue;

        $found = false;

        $passengerName = $trip['userName'] ?? $trip['user_name'] ?? $trip['passengerName'] ?? '';
        if (!empty($passengerName) && stripos(strtolower($passengerName), $searchTermLower) !== false) $found = true;

        $passengerPhone = $trip['userPhone'] ?? $trip['user_phone'] ?? $trip['passengerPhone'] ?? '';
        if (!empty($passengerPhone) && stripos($passengerPhone, $searchTerm) !== false) $found = true;

        $driverName = $trip['driverName'] ?? $trip['driver_name'] ?? $trip['name'] ?? '';
        if (!empty($driverName) && stripos(strtolower($driverName), $searchTermLower) !== false) $found = true;

        $driverPhone = $trip['driverPhone'] ?? $trip['driver_phone'] ?? $trip['phone'] ?? '';
        if (!empty($driverPhone) && stripos($driverPhone, $searchTerm) !== false) $found = true;

        $originAddress = $trip['originAddress'] ?? (is_array($trip['origin'] ?? null) ? ($trip['origin']['address'] ?? '') : ($trip['origin'] ?? ''));
        $destinationAddress = $trip['destinationAddress'] ?? (is_array($trip['destination'] ?? null) ? ($trip['destination']['address'] ?? '') : ($trip['destination'] ?? ''));

        if (!empty($originAddress) && stripos(strtolower($originAddress), $searchTermLower) !== false) $found = true;
        if (!empty($destinationAddress) && stripos(strtolower($destinationAddress), $searchTermLower) !== false) $found = true;

        $vehicleDetails = $trip['vehicle_details'] ?? $trip['vehicleDetails'] ?? $trip['vehicle'] ?? '';
        if (!empty($vehicleDetails) && stripos(strtolower($vehicleDetails), $searchTermLower) !== false) $found = true;

        $status = $trip['status'] ?? $trip['tripStatus'] ?? '';
        if (!empty($status) && stripos(strtolower($status), $searchTermLower) !== false) $found = true;

        if (stripos($tripId, $searchTerm) !== false) $found = true;

        if ($found) $results[$tripId] = $trip;
    }

    return $results;
}

function deleteTrip($tripId) {
    if (empty($tripId)) return false;

    $locations = [
        'All Ride Requests/' . $tripId,
        'rides/' . $tripId,
        'trips/' . $tripId,
        'RideRequests/' . $tripId,
        'ride_requests/' . $tripId,
        'Ride_Requests/' . $tripId,
        'rideRequests/' . $tripId,
        $tripId
    ];

    $success = false;
    foreach ($locations as $location) {
        if (firebaseDelete($location)) $success = true;
    }

    return $success;
}

function updateTripStatus($tripId, $status, $reason = '') {
    if (empty($tripId)) return false;

    $updateData = [
        'status' => $status,
        'lastUpdated' => (int)(microtime(true) * 1000),
        'adminUpdatedAt' => date('Y-m-d H:i:s'),
        'adminUpdatedBy' => $_SESSION['admin_username'] ?? 'admin'
    ];

    if (!empty($reason)) $updateData['adminNote'] = $reason;

    $locations = [
        'All Ride Requests/' . $tripId,
        'rides/' . $tripId,
        'trips/' . $tripId,
        'RideRequests/' . $tripId,
        'ride_requests/' . $tripId,
        'Ride_Requests/' . $tripId,
        'rideRequests/' . $tripId
    ];

    $success = false;
    foreach ($locations as $location) {
        if (firebaseUpdate($location, $updateData)) $success = true;
    }

    return $success;
}

function formatTripTime($time) {
    if (empty($time)) return 'N/A';
    $timestamp = parseTimestamp($time);
    return $timestamp ? date('M d, Y h:i A', $timestamp) : 'N/A';
}

function formatTripData($trip, $tripId = '') {
    if (!is_array($trip)) {
        return [
            'id' => $tripId,
            'passengerName' => 'Unknown',
            'passengerPhone' => 'N/A',
            'driverName' => 'Unknown Driver',
            'driverPhone' => 'N/A',
            'originAddress' => 'N/A',
            'destinationAddress' => 'N/A',
            'fare' => '₱0.00',
            'fareAmount' => 0,
            'status' => 'unknown',
            'statusText' => 'Unknown',
            'time' => '',
            'formattedTime' => 'N/A',
            'isRated' => false,
            'rating' => 0
        ];
    }

    $passengerName = $trip['userName'] ?? $trip['user_name'] ?? $trip['passengerName'] ?? 'Unknown Passenger';
    $passengerPhone = $trip['userPhone'] ?? $trip['user_phone'] ?? $trip['passengerPhone'] ?? 'N/A';

    $driverName = $trip['driverName'] ?? $trip['driver_name'] ?? $trip['name'] ?? 'Unknown Driver';
    $driverPhone = $trip['driverPhone'] ?? $trip['driver_phone'] ?? $trip['phone'] ?? 'N/A';

    $originAddress = $trip['originAddress'] ?? (is_array($trip['origin'] ?? null) ? ($trip['origin']['address'] ?? 'N/A') : ($trip['origin'] ?? 'N/A'));
    $destinationAddress = $trip['destinationAddress'] ?? (is_array($trip['destination'] ?? null) ? ($trip['destination']['address'] ?? 'N/A') : ($trip['destination'] ?? 'N/A'));

    $fareAmount = getTripFare($trip);
    $fare = '₱' . number_format($fareAmount, 2);

    $status = strtolower($trip['status'] ?? $trip['tripStatus'] ?? 'unknown');
    $statusText = ucfirst($status);

    if (in_array($status, ['ended','completed','finished'])) $statusText = 'Completed';
    if (in_array($status, ['cancelled','canceled','rejected'])) $statusText = 'Cancelled';

    $time = $trip['time'] ?? $trip['timestamp'] ?? $trip['createdAt'] ?? '';
    $formattedTime = !empty($time) ? formatTripTime($time) : 'N/A';

    $isRated = isset($trip['rating']) || isset($trip['driverRating']) || isset($trip['passengerRating']);
    $rating = $trip['rating'] ?? $trip['driverRating'] ?? $trip['passengerRating'] ?? 0;

    return [
        'id' => $tripId,
        'passengerName' => $passengerName,
        'passengerPhone' => $passengerPhone,
        'driverName' => $driverName,
        'driverPhone' => $driverPhone,
        'originAddress' => $originAddress,
        'destinationAddress' => $destinationAddress,
        'fare' => $fare,
        'fareAmount' => $fareAmount,
        'status' => $status,
        'statusText' => $statusText,
        'time' => $time,
        'formattedTime' => $formattedTime,
        'isRated' => $isRated,
        'rating' => $rating
    ];
}

function sortTrips($trips, $sortBy, $sortOrder) {
    if (!is_array($trips) || count($trips) === 0) return $trips;

    $sortedTrips = $trips;

    $todaByDriverId = null;
    $todaByPhone = null;
    if ($sortBy === 'toda') {
        [$todaByDriverId, $todaByPhone] = buildDriverTodaIndex();
    }

    uasort($sortedTrips, function($a, $b) use ($sortBy, $sortOrder, $todaByDriverId, $todaByPhone) {
        $aData = formatTripData($a);
        $bData = formatTripData($b);

        switch ($sortBy) {
            case 'passenger':
                $valueA = strtolower($aData['passengerName']);
                $valueB = strtolower($bData['passengerName']);
                break;
            case 'driver':
                $valueA = strtolower($aData['driverName']);
                $valueB = strtolower($bData['driverName']);
                break;
            case 'fare':
                $valueA = floatval($aData['fareAmount']);
                $valueB = floatval($bData['fareAmount']);
                break;
            case 'status':
                $valueA = strtolower($aData['statusText']);
                $valueB = strtolower($bData['statusText']);
                break;
case 'toda':
    $valueA = strtolower(getTodaName(getTripTodaId($a, $todaByDriverId, $todaByPhone)));
    $valueB = strtolower(getTodaName(getTripTodaId($b, $todaByDriverId, $todaByPhone)));
    break;
            case 'time':
            default:
                $valueA = parseTimestamp($a['time'] ?? $a['timestamp'] ?? $a['createdAt'] ?? '') ?: 0;
                $valueB = parseTimestamp($b['time'] ?? $b['timestamp'] ?? $b['createdAt'] ?? '') ?: 0;
                break;
        }

        if ($sortOrder === 'asc') return $valueA <=> $valueB;
        return $valueB <=> $valueA;
    });

    return $sortedTrips;
}

// ======================================================
// DEBUG FIREBASE STRUCTURE
// ======================================================
function debugFirebaseStructure() {
    $allData = firebaseGet('');

    if (!is_array($allData)) return "<p>No data found in Firebase</p>";

    $result = "<h3>Firebase Database Structure</h3>";
    $result .= "<div style='overflow-x:auto;'>";
    $result .= "<table border='1' cellpadding='5' cellspacing='0'>";
    $result .= "<tr><th>Path</th><th>Type</th><th>Sample Data</th></tr>";

    foreach ($allData as $key => $value) {
        $type = gettype($value);
        $sample = '';

        if (is_array($value)) {
            $count = count($value);
            $sample = "Array with $count items";
            if ($count > 0) {
                $keys = array_keys($value);
                $firstKey = $keys[0] ?? 'unknown';
                $firstValue = $value[$firstKey] ?? null;
                if (is_array($firstValue)) {
                    $firstKeys = array_keys($firstValue);
                    $sample .= " - First item keys: " . implode(', ', array_slice($firstKeys, 0, 5));
                    if (count($firstKeys) > 5) $sample .= ", ...";
                }
            }
        } elseif (is_string($value)) {
            $sample = substr($value, 0, 100) . (strlen($value) > 100 ? '...' : '');
        } elseif (is_numeric($value)) {
            $sample = $value;
        } elseif (is_bool($value)) {
            $sample = $value ? 'true' : 'false';
        } elseif (is_null($value)) {
            $sample = 'null';
        }

        $result .= "<tr>";
        $result .= "<td><strong>" . htmlspecialchars($key) . "</strong></td>";
        $result .= "<td>" . htmlspecialchars($type) . "</td>";
        $result .= "<td>" . htmlspecialchars((string)$sample) . "</td>";
        $result .= "</tr>";
    }

    $result .= "</table></div>";
    return $result;
}

// ======================================================
// DASHBOARD COUNTS
// ======================================================
function getTotalCounts() {
    return appRequestMemo('dashboard_total_counts', function () {
        $counts = [
            'total_rides' => 0,
            'completed_rides' => 0,
            'total_drivers' => 0,
            'total_commuters' => 0,
            'active_drivers' => 0,
            'pending_rides' => 0
        ];

        $trips = getAllTrips();
        if (is_array($trips)) {
            $counts['total_rides'] = count($trips);

            foreach ($trips as $trip) {
                if (!is_array($trip)) continue;
                $status = strtolower($trip['status'] ?? '');
                if (in_array($status, ['ended','completed','finished'])) $counts['completed_rides']++;
                elseif (in_array($status, ['pending','requested'])) $counts['pending_rides']++;
            }
        }

        $drivers = getAllDrivers();
        if (is_array($drivers)) {
            $counts['total_drivers'] = count($drivers);
            foreach ($drivers as $driver) {
                if (is_array($driver) && !empty($driver['isDriverActive'])) $counts['active_drivers']++;
            }
        }

        $counts['total_commuters'] = count(getAllCommuters());

        return $counts;
    });
}

// ======================================================
// DRIVER MANAGEMENT
// ======================================================
function getAllDrivers() {
    return appRequestMemo('all_drivers', function () {
        $drivers = firebaseGet('drivers');
        return is_array($drivers) ? $drivers : [];
    });
}

function getDriverStatistics() {
    $drivers = getAllDrivers();
    $stats = [
        'totalDrivers' => 0,
        'activeDrivers' => 0,
        'pendingDrivers' => 0,
        'validatedDrivers' => 0
    ];

    if (is_array($drivers) && count($drivers) > 0) {
        $stats['totalDrivers'] = count($drivers);

        foreach ($drivers as $driverId => $driver) {
            if (!is_array($driver)) continue;

            $status = $driver['accountStatus'] ?? ($driver['status'] ?? 'pending');

            if (!empty($driver['isDriverActive'])) $stats['activeDrivers']++;

            if ($status === 'pending') $stats['pendingDrivers']++;
            elseif ($status === 'validated' || $status === 'active') $stats['validatedDrivers']++;
        }
    }

    return $stats;
}

function getDriverById($driverId) {
    if (empty($driverId)) return null;
    return firebaseGet('drivers/' . $driverId);
}

function addDriver($driverData) {
    try {
        $driverId = 'driver_' . time() . '_' . rand(1000, 9999);

        $formattedData = [
            'name' => $driverData['name'] ?? '',
            'email' => $driverData['email'] ?? '',
            'phone' => $driverData['phone'] ?? '',
            'permitNumber' => $driverData['permitNumber'] ?? '',
            'password' => $driverData['password'] ?? 'password123',
            'plateNumber' => $driverData['vehiclePlate'] ?? '',
            'accountStatus' => $driverData['status'] ?? 'pending',
            'isDriverActive' => false,
            'isProfileCompleted' => false,
            'createdAt' => (int)(microtime(true) * 1000),
            'earnings' => 0,
            'ratings' => 0,
            'termsAgreed' => true,
            'termsAgreedAt' => (int)(microtime(true) * 1000)
        ];

        return firebaseSet('drivers/' . $driverId, $formattedData);
    } catch (Exception $e) {
        error_log("Error adding driver: " . $e->getMessage());
        return false;
    }
}

function updateDriver($driverId, $data) {
    if (empty($driverId) || !is_array($data)) return false;

    $existingDriver = getDriverById($driverId);
    if (!$existingDriver || !is_array($existingDriver)) return false;

    // Keep TODA access protection if TODA is present
    $todaId = $data['todaId'] ?? ($existingDriver['todaId'] ?? null);
    if (!empty($todaId) && function_exists('requireTodaAccess')) {
        requireTodaAccess($todaId);
    }

    $data['updatedAt'] = (int)(microtime(true) * 1000);

    $updated = firebaseUpdate('drivers/' . $driverId, $data);

    if ($updated && function_exists('auditLog')) {
        auditLog('UPDATE_DRIVER', 'driver', $driverId, $data);
    }

    return $updated;
}

function validateDriver($driverId) {
    if (empty($driverId)) return false;

    $existingDriver = getDriverById($driverId);
    if (!is_array($existingDriver)) return false;

    $updateData = [
        'accountStatus' => 'validated',
        'status' => 'validated',
        // Keep the live online flag separate from validation approval.
        'isDriverActive' => !empty($existingDriver['isDriverActive']),
        'validatedAt' => (int)(microtime(true) * 1000),
        'validatedBy' => $_SESSION['admin_username'] ?? 'admin'
    ];

    return firebaseUpdate('drivers/' . $driverId, $updateData);
}

function deleteDriver($driverId) {
    if (empty($driverId)) return false;
    return firebaseDelete('drivers/' . $driverId);
}

function searchDrivers($searchTerm) {
    $searchTerm = trim((string)$searchTerm);
    if ($searchTerm === '') return getAllDrivers();

    return appRequestMemo('search_drivers:' . strtolower($searchTerm), function () use ($searchTerm) {
        $drivers = getAllDrivers();
        $results = [];

        if (is_array($drivers) && count($drivers) > 0) {
            foreach ($drivers as $driverId => $driver) {
                if (!is_array($driver)) continue;

                $found = false;

                if (isset($driver['name']) && stripos($driver['name'], $searchTerm) !== false) $found = true;
                if (isset($driver['phone']) && stripos($driver['phone'], $searchTerm) !== false) $found = true;
                if (isset($driver['permitNumber']) && stripos($driver['permitNumber'], $searchTerm) !== false) $found = true;
                if (isset($driver['email']) && stripos($driver['email'], $searchTerm) !== false) $found = true;
                if (isset($driver['plateNumber']) && stripos($driver['plateNumber'], $searchTerm) !== false) $found = true;

                if ($found) $results[$driverId] = $driver;
            }
        }

        return $results;
    });
}

function getDriversList() {
    return appRequestMemo('driver_display_list', function () {
        $drivers = getAllDrivers();
        $formattedDrivers = [];

        if (is_array($drivers) && count($drivers) > 0) {
            foreach ($drivers as $driverId => $driver) {
                if (!is_array($driver)) continue;

                $formattedDrivers[$driverId] = [
                    'id' => $driverId,
                    'name' => $driver['name'] ?? 'Unknown Driver',
                    'phone' => $driver['phone'] ?? 'N/A',
                    'email' => $driver['email'] ?? 'N/A',
                    'permitNumber' => $driver['permitNumber'] ?? 'N/A',
                    'plateNumber' => $driver['plateNumber'] ?? 'N/A',
                    'accountStatus' => $driver['accountStatus'] ?? ($driver['status'] ?? 'pending'),
                    'isDriverActive' => $driver['isDriverActive'] ?? false,
                    'isOnline' => $driver['isOnline'] ?? null,
                    'online' => $driver['online'] ?? null,
                    'driverOnline' => $driver['driverOnline'] ?? null,
                    'isDriverOnline' => $driver['isDriverOnline'] ?? null,
                    'lastSeen' => $driver['lastSeen'] ?? null,
                    'lastActive' => $driver['lastActive'] ?? null,
                    'lastOnlineAt' => $driver['lastOnlineAt'] ?? null,
                    'onlineAt' => $driver['onlineAt'] ?? null,
                    'presenceUpdatedAt' => $driver['presenceUpdatedAt'] ?? null,
                    'presence' => $driver['presence'] ?? null,
                    'earnings' => $driver['earnings'] ?? 0,
                    'ratings' => $driver['ratings'] ?? 0,
                    'createdAt' => $driver['createdAt'] ?? 0,
                    'todaId' => $driver['todaId'] ?? null,
                    'todaName' => getTodaName($driver['todaId'] ?? null)
                ];
            }
        }

        return $formattedDrivers;
    });
}

function getDriverRides($driverId) {
    if (empty($driverId)) return [];

    $driver = getDriverById($driverId);
    if (!$driver) return [];

    $driverPhone = $driver['phone'] ?? '';
    if (empty($driverPhone)) return [];

    $allTrips = getAllTrips();
    $driverTrips = [];

    foreach ($allTrips as $tripId => $trip) {
        if (!is_array($trip)) continue;

        $tripDriverPhone = $trip['driverPhone'] ?? $trip['driver_phone'] ?? $trip['phone'] ?? '';
        $tripDriverId = $trip['driverId'] ?? $trip['driver_id'] ?? '';

        if ($tripDriverId === $driverId || $tripDriverPhone === $driverPhone) {
            $trip['id'] = $tripId;
            $driverTrips[] = $trip;
        }
    }

    return $driverTrips;
}

// ======================================================
// ✅ RATINGS FUNCTIONS (THIS FIXES YOUR ERROR IN ratings.php)
// ======================================================

function getAllRatings() {
    return appRequestMemo('all_ratings', function () {
        $drivers = getAllDrivers();
        $trips   = getAllTrips();

        if (!is_array($drivers)) return [];

        $aggById = [];
        $aggByPhone = [];

        foreach ($trips as $tripId => $trip) {
            if (!is_array($trip) || !isTripData($trip)) continue;

            $tripDriverId = $trip['driverId'] ?? $trip['driver_id'] ?? '';
            $tripDriverPhone = $trip['driverPhone'] ?? $trip['driver_phone'] ?? $trip['phone'] ?? '';

            $status = strtolower($trip['status'] ?? '');
            $isCompleted = in_array($status, ['completed','ended','finished']);

            $ratingValue = null;
            if (isset($trip['driverRating']) && is_numeric($trip['driverRating'])) $ratingValue = floatval($trip['driverRating']);
            elseif (isset($trip['rating']) && is_numeric($trip['rating'])) $ratingValue = floatval($trip['rating']);

            $ratedAt = parseTimestamp($trip['ratedAt'] ?? $trip['completedAt'] ?? $trip['endTime'] ?? $trip['time'] ?? $trip['timestamp'] ?? $trip['createdAt'] ?? null);

            $applyAgg = function (&$agg) use ($isCompleted, $ratingValue, $ratedAt) {
                if (!isset($agg['totalTrips'])) {
                    $agg['totalTrips'] = 0;
                    $agg['completedTrips'] = 0;
                    $agg['ratingCount'] = 0;
                    $agg['totalRating'] = 0;
                    $agg['lastRated'] = null;
                }

                $agg['totalTrips']++;

                if ($isCompleted) {
                    $agg['completedTrips']++;

                    if ($ratingValue !== null) {
                        $agg['ratingCount']++;
                        $agg['totalRating'] += $ratingValue;

                        if ($ratedAt) {
                            $agg['lastRated'] = max((int)($agg['lastRated'] ?? 0), (int)$ratedAt);
                        }
                    }
                }
            };

            if (!empty($tripDriverId)) {
                if (!isset($aggById[$tripDriverId])) $aggById[$tripDriverId] = [];
                $applyAgg($aggById[$tripDriverId]);
            }

            if (!empty($tripDriverPhone)) {
                if (!isset($aggByPhone[$tripDriverPhone])) $aggByPhone[$tripDriverPhone] = [];
                $applyAgg($aggByPhone[$tripDriverPhone]);
            }
        }

        $ratings = [];

        foreach ($drivers as $driverId => $driver) {
            if (!is_array($driver)) continue;

            $driverPhone = $driver['phone'] ?? '';

            $agg = $aggById[$driverId] ?? ($aggByPhone[$driverPhone] ?? [
                'totalTrips' => 0,
                'completedTrips' => 0,
                'ratingCount' => 0,
                'totalRating' => 0,
                'lastRated' => null
            ]);

            $ratingCount = (int)($agg['ratingCount'] ?? 0);
            $totalRating = (float)($agg['totalRating'] ?? 0);

            $computedAverage = $ratingCount > 0 ? round($totalRating / $ratingCount, 1) : 0.0;

        $storedRating = isset($driver['ratings']) && is_numeric($driver['ratings']) ? floatval($driver['ratings']) : 0.0;

        // If there are NO trip ratings, show stored rating (so UI isn't always 0)
        $currentRating = $ratingCount > 0 ? $computedAverage : $storedRating;

        $ratingMismatch = false;
        if ($ratingCount > 0 && $storedRating > 0) {
            if (abs($storedRating - $computedAverage) >= 0.2) {
                $ratingMismatch = true;
            }
        }

        $ratings[$driverId] = [
            'name' => $driver['name'] ?? 'Unknown',
            'phone' => $driverPhone,
            'permitNumber' => $driver['permitNumber'] ?? '',
            'plateNumber' => $driver['plateNumber'] ?? '',
            'status' => $driver['accountStatus'] ?? ($driver['status'] ?? 'pending'),
            'isActive' => $driver['isDriverActive'] ?? false,
            'todaId' => $driver['todaId'] ?? null,
            'todaName' => getTodaName($driver['todaId'] ?? null),

            'currentRating' => $currentRating,
            'computedRating' => $computedAverage,
            'storedRating' => $storedRating,
            'ratingMismatch' => $ratingMismatch,

            'ratingCount' => $ratingCount,
            'totalRating' => $totalRating,

            'completedTrips' => (int)($agg['completedTrips'] ?? 0),
            'totalTrips' => (int)($agg['totalTrips'] ?? 0),

            'lastRated' => $agg['lastRated'] ?? null
        ];
    }

    return $ratings;
    });
}

function getRatingStatistics() {
    $drivers = getAllRatings();

    $stats = [
        'totalDrivers' => count($drivers),
        'ratedDrivers' => 0,
        'unratedDrivers' => 0,
        'averageRating' => 0,
        'topRatedCount' => 0,
        'lowRatedCount' => 0
    ];

    $sum = 0;

    foreach ($drivers as $driver) {
        $count = (int)($driver['ratingCount'] ?? 0);
        $rating = (float)($driver['currentRating'] ?? 0);

        if ($count > 0) {
            $stats['ratedDrivers']++;
            $sum += $rating;

            if ($rating >= 4.5) $stats['topRatedCount']++;
            if ($rating > 0 && $rating < 3.0) $stats['lowRatedCount']++;
        } else {
            $stats['unratedDrivers']++;
        }
    }

    if ($stats['ratedDrivers'] > 0) {
        $stats['averageRating'] = round($sum / $stats['ratedDrivers'], 1);
    }

    return $stats;
}

function searchRatings($searchTerm) {
    $searchTerm = strtolower(trim((string)$searchTerm));
    if ($searchTerm === '') {
        return getAllRatings();
    }

    return appRequestMemo('search_ratings:' . $searchTerm, function () use ($searchTerm) {
        $all = getAllRatings();
        $results = [];

        foreach ($all as $id => $driver) {
            $haystack = strtolower(
                ($driver['name'] ?? '') . ' ' .
                ($driver['phone'] ?? '') . ' ' .
                ($driver['permitNumber'] ?? '') . ' ' .
                ($driver['plateNumber'] ?? '')
            );

            if (strpos($haystack, $searchTerm) !== false) {
                $results[$id] = $driver;
            }
        }

        return $results;
    });
}

function sortRatings($ratings, $sortBy, $sortOrder) {
    if (!is_array($ratings) || empty($ratings)) return $ratings;

    uasort($ratings, function($a, $b) use ($sortBy, $sortOrder) {
        $direction = ($sortOrder === 'asc') ? 1 : -1;

        switch ($sortBy) {
            case 'name':
                return $direction * strcmp($a['name'] ?? '', $b['name'] ?? '');
            case 'rating':
                return $direction * ((float)($a['currentRating'] ?? 0) <=> (float)($b['currentRating'] ?? 0));
            case 'ratingCount':
                return $direction * ((int)($a['ratingCount'] ?? 0) <=> (int)($b['ratingCount'] ?? 0));
            case 'toda':
                return $direction * strcmp(($a['todaName'] ?? ''), ($b['todaName'] ?? ''));
            case 'completedTrips':
                return $direction * ((int)($a['completedTrips'] ?? 0) <=> (int)($b['completedTrips'] ?? 0));
            case 'lastRated':
                return $direction * ((int)($a['lastRated'] ?? 0) <=> (int)($b['lastRated'] ?? 0));
            default:
                return 0;
        }
    });

    return $ratings;
}

function updateDriverRating($driverId, $newRating) {
    if (empty($driverId)) return false;

    $newRating = max(0, min(5, (float)$newRating));

    return firebaseUpdate('drivers/' . $driverId, [
        'ratings' => number_format($newRating, 1),
        'updatedAt' => (int)(microtime(true) * 1000)
    ]);
}

function recalculateDriverRating($driverId) {
    if (empty($driverId)) return false;

    $all = getAllRatings();
    if (!isset($all[$driverId])) return false;

    // Use computed rating if there are ratings, otherwise keep currentRating
    $ratingCount = (int)($all[$driverId]['ratingCount'] ?? 0);
    $newRating = $ratingCount > 0
        ? (float)($all[$driverId]['computedRating'] ?? 0)
        : (float)($all[$driverId]['currentRating'] ?? 0);

    return updateDriverRating($driverId, $newRating);
}

// ======================================================
// COMMUTER MANAGEMENT
// ======================================================

function getAllCommuters() {
    return appRequestMemo('all_commuters', function () {
        $users = getAllUsers();
        $commuters = [];

        if (is_array($users) && count($users) > 0) {
            foreach ($users as $userId => $user) {
                if (!is_array($user)) continue;

                $userType = $user['userType'] ?? '';
                $hasDriverFields = isset($user['permitNumber']) || isset($user['plateNumber']);

                if ($userType === 'commuter' || (!$hasDriverFields && !empty($user['phone']))) {
                    $commuters[$userId] = $user;
                }
            }
        }

        return $commuters;
    });
}

function getCommuterStatistics() {
    $commuters = getAllCommuters();
    $allUsers = getAllUsers();

    $stats = [
        'totalCommuters' => count($commuters),
        'activeCommuters' => 0,
        'totalUsers' => is_array($allUsers) ? count($allUsers) : 0
    ];

    foreach ($commuters as $commuter) {
        if (!is_array($commuter)) continue;
        $status = $commuter['accountStatus'] ?? 'active';
        if ($status === 'active') $stats['activeCommuters']++;
    }

    return $stats;
}

function getCommuterById($commuterId) {
    if (empty($commuterId)) return null;
    return firebaseGet('users/' . $commuterId);
}

function deleteCommuter($commuterId) {
    if (empty($commuterId)) return false;
    return firebaseDelete('users/' . $commuterId);
}

function searchCommuters($searchTerm) {
    $searchTerm = trim((string)$searchTerm);
    if ($searchTerm === '') return getAllCommuters();

    return appRequestMemo('search_commuters:' . strtolower($searchTerm), function () use ($searchTerm) {
        $commuters = getAllCommuters();
        $results = [];

        if (is_array($commuters) && count($commuters) > 0) {
            foreach ($commuters as $userId => $commuter) {
                if (!is_array($commuter)) continue;

                $found = false;

                $fullName = trim(($commuter['name'] ?? '') . ' ' . ($commuter['lastName'] ?? ''));
                if (!empty($fullName) && stripos($fullName, $searchTerm) !== false) $found = true;
                if (isset($commuter['phone']) && stripos($commuter['phone'], $searchTerm) !== false) $found = true;
                if (isset($commuter['email']) && stripos($commuter['email'], $searchTerm) !== false) $found = true;
                if (stripos($userId, $searchTerm) !== false) $found = true;

                if ($found) $results[$userId] = $commuter;
            }
        }

        return $results;
    });
}

function getCommuterRides($commuterPhone) {
    if (empty($commuterPhone)) return [];

    $allTrips = getAllTrips();
    $commuterTrips = [];

    foreach ($allTrips as $tripId => $trip) {
        if (!is_array($trip)) continue;

        $tripUserPhone = $trip['userPhone'] ?? $trip['user_phone'] ?? $trip['passengerPhone'] ?? '';
        if ($tripUserPhone === $commuterPhone) {
            $trip['id'] = $tripId;
            $commuterTrips[] = $trip;
        }
    }

    return $commuterTrips;
}

function getCommuterRideStatistics($commuterPhone) {
    $rides = getCommuterRides($commuterPhone);
    $stats = [
        'totalRides' => count($rides),
        'completedRides' => 0,
        'pendingRides' => 0,
        'cancelledRides' => 0,
        'totalSpent' => 0.00,
        'averageRating' => 0.0,
        'totalRatings' => 0
    ];

    $totalRating = 0;

    foreach ($rides as $ride) {
        if (!is_array($ride)) continue;

        $status = strtolower($ride['status'] ?? 'unknown');

        if (in_array($status, ['ended','completed','finished'])) $stats['completedRides']++;
        elseif (in_array($status, ['cancelled','canceled','rejected'])) $stats['cancelledRides']++;
        else $stats['pendingRides']++;

        $stats['totalSpent'] += getTripFare($ride);

        if (isset($ride['driverRating']) && is_numeric($ride['driverRating'])) {
            $stats['totalRatings']++;
            $totalRating += floatval($ride['driverRating']);
        } elseif (isset($ride['rating']) && is_numeric($ride['rating'])) {
            $stats['totalRatings']++;
            $totalRating += floatval($ride['rating']);
        }
    }

    if ($stats['totalRatings'] > 0) {
        $stats['averageRating'] = round($totalRating / $stats['totalRatings'], 1);
    }

    return $stats;
}

function sortCommuters($commuters, $sortBy, $sortOrder) {
    if (!is_array($commuters) || count($commuters) === 0) return $commuters;

    $sortedCommuters = $commuters;

    uasort($sortedCommuters, function($a, $b) use ($sortBy, $sortOrder) {
        $valueA = '';
        $valueB = '';

        switch ($sortBy) {
            case 'name':
                $nameA = ($a['name'] ?? '') . ' ' . ($a['lastName'] ?? '');
                $nameB = ($b['name'] ?? '') . ' ' . ($b['lastName'] ?? '');
                $valueA = strtolower(trim($nameA));
                $valueB = strtolower(trim($nameB));
                break;
            case 'status':
                $valueA = strtolower($a['accountStatus'] ?? 'inactive');
                $valueB = strtolower($b['accountStatus'] ?? 'inactive');
                break;
            case 'phone':
                $valueA = strtolower($a['phone'] ?? '');
                $valueB = strtolower($b['phone'] ?? '');
                break;
            case 'email':
                $valueA = strtolower($a['email'] ?? '');
                $valueB = strtolower($b['email'] ?? '');
                break;
            case 'date':
                $valueA = floatval($a['createdAt'] ?? 0);
                $valueB = floatval($b['createdAt'] ?? 0);
                if ($sortOrder === 'desc') return $valueB <=> $valueA;
                return $valueA <=> $valueB;
            default:
                $nameA = ($a['name'] ?? '') . ' ' . ($a['lastName'] ?? '');
                $nameB = ($b['name'] ?? '') . ' ' . ($b['lastName'] ?? '');
                $valueA = strtolower(trim($nameA));
                $valueB = strtolower(trim($nameB));
        }

        if ($sortOrder === 'asc') return strcmp($valueA, $valueB);
        return strcmp($valueB, $valueA);
    });

    return $sortedCommuters;
}

// ======================================================
// UTILITY
// ======================================================

function testFirebaseConnection() {
    $test = firebaseGet('');
    return $test !== null;
}

function formatFirebaseTimestamp($timestamp, $format = 'F j, Y g:i A') {
    if (empty($timestamp) || !is_numeric($timestamp)) return 'N/A';

    $timestamp = (int)$timestamp;
    if ($timestamp > 1000000000000) $timestamp = (int)($timestamp / 1000);

    return date($format, $timestamp);
}

// ======================================================
// TEST ENDPOINTS
// ======================================================

if (isset($_GET['test']) && $_GET['test'] == 'firebase') {
    if (testFirebaseConnection()) echo "Firebase connection successful!";
    else echo "Firebase connection failed! Check your Firebase URL and internet connection.";
    exit();
}


// ======================================================
// ✅ TODA MANAGEMENT FUNCTIONS
// ======================================================

function createToda($name, $code = '') {
    $name = trim((string)$name);
    if ($name === '') return false;

    $todaId = 'toda_' . time() . '_' . rand(1000, 9999);

    $payload = [
        'name' => $name,
        'code' => trim((string)$code),
        'active' => true,
        'createdAt' => (int)(microtime(true) * 1000)
    ];

    $ok = firebaseSet(FB_NODE_TODAS . '/' . $todaId, $payload);
    if ($ok) auditLog('CREATE_TODA', 'toda', $todaId, ['name' => $name, 'code' => $code]);
    return $ok;
}

function updateToda($todaId, $data) {
    if (empty($todaId) || !is_array($data)) return false;

    $ok = firebaseUpdate(FB_NODE_TODAS . '/' . $todaId, $data);
    if ($ok) auditLog('UPDATE_TODA', 'toda', $todaId, $data);
    return $ok;
}

function deleteToda($todaId) {
    if (empty($todaId)) return false;

    $ok = firebaseDelete(FB_NODE_TODAS . '/' . $todaId);
    if ($ok) auditLog('DELETE_TODA', 'toda', $todaId, []);
    return $ok;
}

function countActiveTODAAccounts($todaId) {
    if (empty($todaId)) return 0;

    $users = getAllAdminUsers();
    $count = 0;

    foreach ($users as $id => $u) {
        if (!is_array($u)) continue;

        $role = $u['role'] ?? '';
        $active = !empty($u['active']);
        $uToda = $u['todaId'] ?? null;

        if (!$active) continue;

        // Count TODA-scoped admin/staff only
        if (in_array($role, [ROLE_TODA_ADMIN, ROLE_TODA_STAFF], true) && (string)$uToda === (string)$todaId) {
            $count++;
        }
    }

    return $count;
}

// ======================================================
// ✅ ADMIN USER MANAGEMENT FUNCTIONS
// ======================================================

function createAdminUser($data, $allowOverrideLimit = false) {
    if (!is_array($data)) return [false, 'Invalid payload'];

    $username = trim((string)($data['username'] ?? ''));
    $email = trim((string)($data['email'] ?? ''));
    $password = (string)($data['password'] ?? '');
    $role = (string)($data['role'] ?? ROLE_AUDITOR);
    $todaId = $data['todaId'] ?? null;
    $active = isset($data['active']) ? (bool)$data['active'] : true;

    if ($username === '') return [false, 'Username is required'];
    if ($password === '') return [false, 'Password is required'];

    // Prevent duplicates
    $users = getAllAdminUsers();
    foreach ($users as $id => $u) {
        if (!is_array($u)) continue;

        if (strtolower($u['username'] ?? '') === strtolower($username)) {
            return [false, 'Username already exists'];
        }
        if ($email !== '' && strtolower($u['email'] ?? '') === strtolower($email)) {
            return [false, 'Email already exists'];
        }
    }

    // Enforce 3 accounts per TODA (for TODA-scoped accounts)
    if (in_array($role, [ROLE_TODA_ADMIN, ROLE_TODA_STAFF], true)) {
        if (empty($todaId)) return [false, 'TODA is required for TODA accounts'];

        $count = countActiveTODAAccounts($todaId);
        if ($active && $count >= 3 && !$allowOverrideLimit) {
            return [false, 'Limit reached: only 3 active accounts are allowed per TODA'];
        }
    }

    $adminId = 'admin_' . time() . '_' . rand(1000, 9999);

    $permissions = $data['permissions'] ?? roleDefaultPermissions($role);
    if (!is_array($permissions)) $permissions = roleDefaultPermissions($role);

    $payload = [
        'username' => $username,
        'email' => $email,
        'role' => $role,
        'todaId' => $todaId,
        'permissions' => $permissions,
        'active' => $active,
        'createdAt' => (int)(microtime(true) * 1000),
        'passwordHash' => password_hash($password, PASSWORD_DEFAULT),
    ];

    $ok = firebaseSet(FB_NODE_ADMIN_USERS . '/' . $adminId, $payload);
    if ($ok) auditLog('CREATE_ADMIN_USER', 'adminUser', $adminId, ['username' => $username, 'role' => $role, 'todaId' => $todaId]);
    return [$ok, $ok ? '' : 'Failed to create admin user'];
}

function updateAdminUser($adminId, $data) {
    if (empty($adminId) || !is_array($data)) return [false, 'Invalid payload'];

    // If activating TODA account, enforce limit again
    $existing = firebaseGet(FB_NODE_ADMIN_USERS . '/' . $adminId);
    if (!is_array($existing)) return [false, 'User not found'];

    $role = $data['role'] ?? ($existing['role'] ?? ROLE_AUDITOR);
    $todaId = $data['todaId'] ?? ($existing['todaId'] ?? null);
    $active = isset($data['active']) ? (bool)$data['active'] : !empty($existing['active']);

    if (in_array($role, [ROLE_TODA_ADMIN, ROLE_TODA_STAFF], true)) {
        if (empty($todaId)) return [false, 'TODA is required for TODA accounts'];

        $count = countActiveTODAAccounts($todaId);

        // If this user is already active in same TODA, exclude them from count
        if (!empty($existing['active']) && (string)($existing['todaId'] ?? '') === (string)$todaId && in_array(($existing['role'] ?? ''), [ROLE_TODA_ADMIN, ROLE_TODA_STAFF], true)) {
            $count = max(0, $count - 1);
        }

        if ($active && $count >= 3 && !isSuperAdmin()) {
            return [false, 'Limit reached: only 3 active accounts are allowed per TODA'];
        }
    }

    // Password update
    if (isset($data['password']) && (string)$data['password'] !== '') {
        $data['passwordHash'] = password_hash((string)$data['password'], PASSWORD_DEFAULT);
        unset($data['password']);
    }

    $ok = firebaseUpdate(FB_NODE_ADMIN_USERS . '/' . $adminId, $data);
    if ($ok) auditLog('UPDATE_ADMIN_USER', 'adminUser', $adminId, $data);
    return [$ok, $ok ? '' : 'Failed to update admin user'];
}

function deleteAdminUser($adminId) {
    if (empty($adminId)) return [false, 'Missing adminId'];

    // Prevent deleting bootstrap superadmin
    if ((string)$adminId === 'superadmin') {
        return [false, 'Cannot delete superadmin'];
    }

    $ok = firebaseDelete(FB_NODE_ADMIN_USERS . '/' . $adminId);
    if ($ok) auditLog('DELETE_ADMIN_USER', 'adminUser', $adminId, []);
    return [$ok, $ok ? '' : 'Failed to delete admin user'];
}

// ======================================================
// ✅ FEEDBACK FUNCTIONS
// ======================================================

function getAllFeedback() {
    return appRequestMemo('all_feedback', function () {
        $fb = firebaseGet(FB_NODE_FEEDBACK);
        return is_array($fb) ? $fb : [];
    });
}

function normalizePassengerCommentText($value) {
    if (!is_string($value)) return '';

    $comment = trim($value);
    if ($comment === '') return '';

    if (preg_match('/^comment\s*:\s*(.*)$/i', $comment, $matches)) {
        $comment = trim((string)($matches[1] ?? ''));
    }

    return $comment;
}

function extractFeedbackCommentText($item) {
    if (is_string($item)) {
        return normalizePassengerCommentText($item);
    }

    if (!is_array($item)) return '';

    $candidates = [
        $item['comment'] ?? null,
        $item['comments'] ?? null,
        $item['note'] ?? null,
        $item['notes'] ?? null,
        $item['adminNote'] ?? null,
        $item['feedbackComment'] ?? null,
        $item['passengerComment'] ?? null,
    ];

    foreach ($candidates as $candidate) {
        $comment = normalizePassengerCommentText($candidate);
        if ($comment !== '') return $comment;
    }

    return '';
}

function getPassengerCommentFeedbackRecords() {
    return appRequestMemo('passenger_comment_feedback_records', function () {
        return buildTripCommentFeedbackRecords();
    });
}

function buildFeedbackDriverNameIndex($drivers = null) {
    if ($drivers === null) {
        return appRequestMemo('feedback_driver_name_index', function () {
            return buildFeedbackDriverNameIndex(getAllDrivers());
        });
    }

    $index = [];
    if (!is_array($drivers)) return $index;

    foreach ($drivers as $driverId => $driver) {
        if (!is_array($driver)) continue;

        $candidates = [
            $driver['name'] ?? null,
            trim((string)(($driver['firstName'] ?? '') . ' ' . ($driver['lastName'] ?? ''))),
            $driver['fullName'] ?? null,
            $driver['displayName'] ?? null,
        ];

        $resolved = '';
        foreach ($candidates as $candidate) {
            $candidate = trim((string)$candidate);
            if ($candidate !== '') {
                $resolved = $candidate;
                break;
            }
        }

        if ($resolved !== '') {
            $index[(string)$driverId] = $resolved;
        }
    }

    return $index;
}

function buildFeedbackPassengerNameIndexes($commuters = null) {
    if ($commuters === null) {
        return appRequestMemo('feedback_passenger_name_indexes', function () {
            return buildFeedbackPassengerNameIndexes(getAllCommuters());
        });
    }

    $byId = [];
    $byPhone = [];
    if (!is_array($commuters)) return [$byId, $byPhone];

    foreach ($commuters as $commuterId => $commuter) {
        if (!is_array($commuter)) continue;

        $candidates = [
            $commuter['name'] ?? null,
            trim((string)(($commuter['firstName'] ?? '') . ' ' . ($commuter['lastName'] ?? ''))),
            $commuter['fullName'] ?? null,
            $commuter['displayName'] ?? null,
            $commuter['userName'] ?? null,
        ];

        $resolved = '';
        foreach ($candidates as $candidate) {
            $candidate = trim((string)$candidate);
            if ($candidate !== '') {
                $resolved = $candidate;
                break;
            }
        }

        if ($resolved === '') continue;

        $byId[(string)$commuterId] = $resolved;

        $phoneCandidates = [
            $commuter['phone'] ?? null,
            $commuter['mobile'] ?? null,
            $commuter['contactNumber'] ?? null,
            $commuter['userPhone'] ?? null,
        ];
        foreach ($phoneCandidates as $phone) {
            $phone = trim((string)$phone);
            if ($phone !== '') {
                $byPhone[$phone] = $resolved;
            }
        }
    }

    return [$byId, $byPhone];
}

function resolveFeedbackPassengerName($tripData, $commuterNameById, $commuterNameByPhone) {
    $nameCandidates = [
        $tripData['userName'] ?? null,
        $tripData['passengerName'] ?? null,
        $tripData['commuterName'] ?? null,
        $tripData['name'] ?? null,
    ];

    foreach ($nameCandidates as $candidate) {
        $candidate = trim((string)$candidate);
        if ($candidate !== '') return $candidate;
    }

    $idCandidates = [
        $tripData['userId'] ?? null,
        $tripData['commuterId'] ?? null,
    ];
    foreach ($idCandidates as $id) {
        $id = trim((string)$id);
        if ($id !== '' && isset($commuterNameById[$id])) return $commuterNameById[$id];
    }

    $phoneCandidates = [
        $tripData['userPhone'] ?? null,
        $tripData['user_phone'] ?? null,
        $tripData['phone'] ?? null,
    ];
    foreach ($phoneCandidates as $phone) {
        $phone = trim((string)$phone);
        if ($phone !== '' && isset($commuterNameByPhone[$phone])) return $commuterNameByPhone[$phone];
    }

    return '';
}

function resolveFeedbackDriverName($tripData, $driverNameById) {
    $nameCandidates = [
        $tripData['driverName'] ?? null,
        $tripData['name'] ?? null,
    ];

    foreach ($nameCandidates as $candidate) {
        $candidate = trim((string)$candidate);
        if ($candidate !== '') return $candidate;
    }

    $driverId = trim((string)($tripData['driverId'] ?? $tripData['driver_id'] ?? ''));
    if ($driverId !== '' && isset($driverNameById[$driverId])) {
        return $driverNameById[$driverId];
    }

    return '';
}

function buildTripCommentFeedbackRecords($tripsNode = null, $indexById = null, $indexByPhone = null, $driverNameById = null, $commuterNameById = null, $commuterNameByPhone = null) {
    if ($tripsNode === null) {
        $preferredNodes = prioritizeFirebaseNodePaths([
            'All Ride Requests',
            'rides',
            'trips',
            'RideRequests',
            'ride_requests',
            'Ride_Requests',
            'rideRequests'
        ], 'firebase_trip_collection_path');

        $tripsNode = [];
        foreach ($preferredNodes as $nodePath) {
            $candidate = firebaseGet($nodePath);
            if (is_array($candidate) && !empty($candidate)) {
                rememberFirebasePreferredNode('firebase_trip_collection_path', $nodePath);
                $tripsNode = $candidate;
                break;
            }
        }
    }

    if (!is_array($tripsNode) || empty($tripsNode)) return [];

    if ($indexById === null || $indexByPhone === null) {
        [$indexById, $indexByPhone] = buildDriverTodaIndex();
    }

    if ($driverNameById === null) {
        $driverNameById = buildFeedbackDriverNameIndex();
    }

    if ($commuterNameById === null || $commuterNameByPhone === null) {
        [$commuterNameById, $commuterNameByPhone] = buildFeedbackPassengerNameIndexes();
    }

    $records = [];
    $lastTripContext = null;

    foreach ($tripsNode as $itemId => $itemData) {
        if (is_array($itemData) && isTripData($itemData)) {
            $lastTripContext = [
                'tripId' => $itemId,
                'driverId' => $itemData['driverId'] ?? $itemData['driver_id'] ?? '',
                'commuterId' => $itemData['userPhone'] ?? $itemData['user_phone'] ?? $itemData['userId'] ?? '',
                'todaId' => getTripTodaId($itemData, $indexById, $indexByPhone),
                'rating' => $itemData['rating'] ?? $itemData['driverRating'] ?? $itemData['passengerRating'] ?? null,
                'createdAt' => $itemData['accepted_at'] ?? $itemData['completed_at'] ?? $itemData['time'] ?? $itemData['timestamp'] ?? $itemData['createdAt'] ?? null,
                'driverName' => resolveFeedbackDriverName($itemData, $driverNameById),
                'commuterName' => resolveFeedbackPassengerName($itemData, $commuterNameById, $commuterNameByPhone),
            ];

            $comment = extractFeedbackCommentText($itemData);
            if ($comment === '') continue;

            $records['trip_comment_' . $itemId] = [
                'id' => 'trip_comment_' . $itemId,
                'tripId' => $lastTripContext['tripId'],
                'driverId' => $lastTripContext['driverId'],
                'commuterId' => $lastTripContext['commuterId'],
                'todaId' => $lastTripContext['todaId'],
                'category' => 'Ride Comment',
                'rating' => $lastTripContext['rating'],
                'comment' => $comment,
                'status' => 'New',
                'createdAt' => $lastTripContext['createdAt'],
                'driverName' => $lastTripContext['driverName'],
                'commuterName' => $lastTripContext['commuterName'],
                'source' => 'firebase_comment',
                'sourceLabel' => 'Trip comment',
                'readOnly' => true,
            ];
            continue;
        }

        if (is_string($itemData)) {
            $comment = normalizePassengerCommentText($itemData);
            if ($comment === '') continue;

            $recordId = 'trip_comment_' . $itemId;
            $tripId = '';
            $driverId = '';
            $commuterId = '';
            $todaId = null;
            $rating = null;
            $createdAt = null;
            $driverName = '';
            $commuterName = '';
            $sourceLabel = 'Raw comment node';

            if (is_array($lastTripContext) && !empty($lastTripContext['tripId'])) {
                $tripId = $lastTripContext['tripId'];
                $driverId = $lastTripContext['driverId'] ?? '';
                $commuterId = $lastTripContext['commuterId'] ?? '';
                $todaId = $lastTripContext['todaId'] ?? null;
                $rating = $lastTripContext['rating'] ?? null;
                $createdAt = $lastTripContext['createdAt'] ?? null;
                $driverName = $lastTripContext['driverName'] ?? '';
                $commuterName = $lastTripContext['commuterName'] ?? '';
                $sourceLabel = 'Trip comment (attached node)';
                $recordId = 'trip_comment_' . $tripId . '_' . $itemId;
            }

            $records[$recordId] = [
                'id' => $recordId,
                'tripId' => $tripId,
                'driverId' => $driverId,
                'commuterId' => $commuterId,
                'todaId' => $todaId,
                'category' => 'Ride Comment',
                'rating' => $rating,
                'comment' => $comment,
                'status' => 'New',
                'createdAt' => $createdAt,
                'driverName' => $driverName,
                'commuterName' => $commuterName,
                'source' => 'firebase_comment',
                'sourceLabel' => $sourceLabel,
                'readOnly' => true,
            ];
        }
    }

    return $records;
}

function getCombinedFeedbackRecords() {
    $combined = [];

    foreach (getAllFeedback() as $id => $feedback) {
        if (!is_array($feedback)) continue;
        $feedback['id'] = $id;
        $feedback['source'] = $feedback['source'] ?? 'manual_feedback';
        $feedback['sourceLabel'] = $feedback['sourceLabel'] ?? 'Admin feedback';
        $feedback['readOnly'] = false;
        $combined[$id] = $feedback;
    }

    foreach (buildTripCommentFeedbackRecords() as $id => $feedback) {
        if (!isset($combined[$id])) {
            $combined[$id] = $feedback;
        }
    }

    return $combined;
}

function addFeedback($payload) {
    if (!is_array($payload)) return false;

    $id = 'fb_' . time() . '_' . rand(1000, 9999);

    $payload['status'] = $payload['status'] ?? 'New';
    $payload['createdAt'] = $payload['createdAt'] ?? (int)(microtime(true) * 1000);

    $ok = firebaseSet(FB_NODE_FEEDBACK . '/' . $id, $payload);
    if ($ok) auditLog('CREATE_FEEDBACK', 'feedback', $id, ['tripId' => $payload['tripId'] ?? '', 'driverId' => $payload['driverId'] ?? '']);
    return $ok;
}

function updateFeedback($feedbackId, $data) {
    if (empty($feedbackId) || !is_array($data)) return false;

    $ok = firebaseUpdate(FB_NODE_FEEDBACK . '/' . $feedbackId, $data);
    if ($ok) auditLog('UPDATE_FEEDBACK', 'feedback', $feedbackId, $data);
    return $ok;
}

// ======================================================
// ✅ REPORT HELPERS (CSV EXPORT)
// ======================================================

function outputCsv($filename, $headers, $rows) {
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename=' . $filename);

    $out = fopen('php://output', 'w');
    fputcsv($out, $headers);

    foreach ($rows as $r) {
        fputcsv($out, $r);
    }

    fclose($out);
    exit();
}

if (isset($_GET['debug']) && $_GET['debug'] == 'firebase') {
    if (isAdminLoggedIn()) {
        echo "<html><head><style>
            body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }
            h3 { color: #333; margin-top: 20px; }
            table { border-collapse: collapse; width: 100%; background: white; }
            th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
            th { background-color: #f2f2f2; font-weight: bold; }
            tr:hover { background-color: #f9f9f9; }
            .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        </style></head><body><div class='container'>";
        echo debugFirebaseStructure();
        echo "</div></body></html>";
        exit();
    }
}
?>
