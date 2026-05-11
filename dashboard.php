<?php
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_DASHBOARD_VIEW);

if (isTodaMonitor() && !empty(currentAdminTodaId())) {
    header('Location: toda_dashboard.php');
    exit();
}

if (isBploVerifier()) {
    header('Location: bplo_dashboard.php');
    exit();
}


// =====================
// Scoped Dashboard Data
// =====================
$scopedTodaId = isTodaScopedAdmin() ? currentAdminTodaId() : null;
$isScopedDashboard = !empty($scopedTodaId);

$driverStats  = getDriverStatistics();
$commStats    = getCommuterStatistics();
$tripStats    = getTripStatistics();
$ratingStats  = getRatingStatistics();
$counts       = getTotalCounts();

$allDrivers = getDriversList();
if (!is_array($allDrivers)) {
    $allDrivers = [];
}

if ($isScopedDashboard) {
    $allDrivers = array_filter($allDrivers, function($driver) use ($scopedTodaId) {
        return is_array($driver) && (string)($driver['todaId'] ?? '') === (string)$scopedTodaId;
    });
}


$topRatedDrivers = [];
$allRatings = getAllRatings();
if (!is_array($allRatings)) {
    $allRatings = [];
}
if ($isScopedDashboard) {
    $allRatings = array_filter($allRatings, function($rating) use ($scopedTodaId) {
        return is_array($rating) && (string)($rating['todaId'] ?? '') === (string)$scopedTodaId;
    });
}
if (!empty($allRatings)) {
    uasort($allRatings, function($a, $b) {
        $ra = (float)($a['currentRating'] ?? 0);
        $rb = (float)($b['currentRating'] ?? 0);

        if ($ra == $rb) {
            $ca = (int)($a['completedTrips'] ?? 0);
            $cb = (int)($b['completedTrips'] ?? 0);
            return $cb <=> $ca;
        }

        return $rb <=> $ra;
    });

    $topRatedDrivers = array_slice($allRatings, 0, 5, true);
}

$allTrips = getAllTrips();
if (!is_array($allTrips)) {
    $allTrips = [];
}
[$todaByDriverId, $todaByPhone] = buildDriverTodaIndex();
if ($isScopedDashboard) {
    $allTrips = array_filter($allTrips, function($trip) use ($scopedTodaId, $todaByDriverId, $todaByPhone) {
        return is_array($trip) && (string)getTripTodaId($trip, $todaByDriverId, $todaByPhone) === (string)$scopedTodaId;
    });
}

$rides = $allTrips;
if (!empty($rides)) {
    uasort($rides, function($a, $b) {
        $ta = parseTimestamp($a['time'] ?? $a['timestamp'] ?? $a['createdAt'] ?? '') ?: 0;
        $tb = parseTimestamp($b['time'] ?? $b['timestamp'] ?? $b['createdAt'] ?? '') ?: 0;
        return $tb <=> $ta;
    });
    $rides = array_slice($rides, 0, 10, true);
} else {
    $rides = [];
}

if ($isScopedDashboard) {
    $driverStats = [
        'totalDrivers' => count($allDrivers),
    ];

    $uniqueCommuters = [];
    foreach ($allTrips as $trip) {
        if (!is_array($trip)) continue;
        $commuterKey = (string)($trip['userId'] ?? $trip['user_id'] ?? $trip['userPhone'] ?? $trip['user_phone'] ?? $trip['passengerPhone'] ?? $trip['passengerName'] ?? '');
        if ($commuterKey !== '') {
            $uniqueCommuters[$commuterKey] = true;
        }
    }
    $commStats = [
        'totalCommuters' => count($uniqueCommuters),
    ];

    $tripStats = [
        'totalTrips' => count($allTrips),
    ];

    $ratedDrivers = 0;
    $ratingSum = 0;
    foreach ($allRatings as $rating) {
        if (!is_array($rating)) continue;
        $ratingCount = (int)($rating['ratingCount'] ?? 0);
        $currentRating = (float)($rating['currentRating'] ?? 0);
        if ($ratingCount > 0 || $currentRating > 0) {
            $ratedDrivers++;
            $ratingSum += $currentRating;
        }
    }
    $ratingStats = [
        'averageRating' => $ratedDrivers > 0 ? round($ratingSum / $ratedDrivers, 1) : 0,
    ];

    $counts = [
        'total_drivers' => count($allDrivers),
        'total_commuters' => count($uniqueCommuters),
        'total_rides' => count($allTrips),
    ];
}

// =====================
// Helpers
// =====================
function fmtTime($t) {
    $ts = parseTimestamp($t);
    return $ts ? date('M d, Y h:i A', $ts) : 'N/A';
}

function tripStatusClass($status) {
    $s = strtolower((string)$status);
    if (in_array($s, ['ended','completed','finished'])) return 'status-ended';
    if (in_array($s, ['pending','requested','waiting'])) return 'status-pending';
    if (in_array($s, ['cancelled','canceled','rejected'])) return 'status-cancelled';
    return 'status-active';
}

function initials($name) {
    $name = trim((string)$name);
    if ($name === '') return '?';
    return strtoupper(substr($name, 0, 1));
}

// Safe number
function n($v, $default = 0) {
    return is_numeric($v) ? $v : $default;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Kaltrike Admin</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel=\"stylesheet\" href=\"assets/styles.css\">

    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f6fa;
            color: #2c3e50;
            display: flex;
            min-height: 100vh;
        }

        .sidebar {
            position: fixed;
            left: 0;
            top: 0;
            height: 100vh;
            width: 250px;
            background: linear-gradient(180deg, #2c3e50 0%, #3498db 100%);
            padding: 20px 0;
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
            z-index: 1000;
            overflow-y: auto;
        }

        .logo {
            text-align: center;
            padding: 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            color: white;
            font-size: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }

        .logo span {
            font-weight: 600;
        }

        .nav-links {
            list-style: none;
            padding: 20px 0;
        }

        .nav-links li {
            margin: 5px 0;
        }

        .nav-links a {
            display: flex;
            align-items: center;
            gap: 15px;
            padding: 15px 25px;
            color: rgba(255,255,255,0.9);
            text-decoration: none;
            transition: all 0.3s;
            font-size: 15px;
            border-left: 4px solid transparent;
        }

        .nav-links a:hover {
            background: rgba(255,255,255,0.1);
            color: white;
        }

        .nav-links a.active {
            background: rgba(255,255,255,0.15);
            color: white;
            border-left-color: #27ae60;
        }

        .nav-links i {
            width: 20px;
            text-align: center;
            font-size: 16px;
        }

        .main-content {
            flex: 1;
            margin-left: 250px;
            padding: 25px;
            min-height: 100vh;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #e0e0e0;
        }

        .header h1 {
            color: #2c3e50;
            font-size: 28px;
            font-weight: 600;
        }

        /* Top Controls (match commuters.php style) */
        .top-controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            gap: 20px;
        }

        .page-title h2 {
            color: #2c3e50;
            font-size: 22px;
            font-weight: 600;
        }

        .page-title span {
            color: #7f8c8d;
            font-size: 14px;
            font-weight: normal;
        }

        /* Statistics Grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            text-align: center;
            border-top: 4px solid #3498db;
            transition: transform 0.3s;
        }

        .stat-card:hover {
            transform: translateY(-5px);
        }

        .stat-card:nth-child(1) { border-top-color: #3498db; }
        .stat-card:nth-child(2) { border-top-color: #27ae60; }
        .stat-card:nth-child(3) { border-top-color: #9b59b6; }
        .stat-card:nth-child(4) { border-top-color: #f1c40f; }

        .stat-icon {
            font-size: 30px;
            margin-bottom: 15px;
            opacity: 0.85;
        }

        .stat-card:nth-child(1) .stat-icon { color: #3498db; }
        .stat-card:nth-child(2) .stat-icon { color: #27ae60; }
        .stat-card:nth-child(3) .stat-icon { color: #9b59b6; }
        .stat-card:nth-child(4) .stat-icon { color: #f1c40f; }

        .stat-number {
            font-size: 32px;
            font-weight: bold;
            color: #2c3e50;
            margin: 10px 0;
            line-height: 1;
        }

        .stat-label {
            color: #7f8c8d;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 600;
        }

        /* Generic Section Container (like commuters table container) */
        .section {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            overflow: hidden;
            margin-bottom: 25px;
        }

        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .section-header h3 {
            color: #2c3e50;
            font-size: 18px;
            font-weight: 600;
        }

        .section-subtitle {
            color: #7f8c8d;
            font-size: 14px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }

        th {
            background-color: #f8f9fa;
            padding: 15px;
            text-align: left;
            color: #2c3e50;
            border-bottom: 2px solid #e0e0e0;
            font-weight: 600;
            white-space: nowrap;
        }

        td {
            padding: 15px;
            border-bottom: 1px solid #eee;
            vertical-align: middle;
        }

        tr:hover {
            background-color: #f9f9f9;
        }

        /* Person Info (for drivers / commuters) */
        .person-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .person-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #3498db 0%, #2c3e50 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 16px;
            flex-shrink: 0;
        }

        .person-details {
            display: flex;
            flex-direction: column;
        }

        .person-name {
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 3px;
        }

        .person-sub {
            color: #7f8c8d;
            font-size: 12px;
        }

        /* Status Badges (reuse commuters style + extra states) */
        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
            text-transform: capitalize;
        }

        .status-active {
            background-color: #d5f4e6;
            color: #27ae60;
        }

        .status-inactive {
            background-color: #fff3cd;
            color: #856404;
        }

        .status-pending {
            background-color: #d1ecf1;
            color: #0c5460;
        }

        .status-ended {
            background-color: #fadbd8;
            color: #e74c3c;
        }

        .status-cancelled {
            background-color: #fff3cd;
            color: #856404;
        }

        .no-data {
            text-align: center;
            padding: 40px 20px;
            color: #7f8c8d;
        }

        .no-data i {
            font-size: 40px;
            margin-bottom: 10px;
            color: #bdc3c7;
        }

        /* Responsive Design */
        @media (max-width: 1024px) {
            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 768px) {
            .sidebar {
                width: 100%;
                height: auto;
                position: relative;
                margin-bottom: 20px;
            }

            .main-content {
                margin-left: 0;
                padding: 15px;
            }

            .stats-grid {
                grid-template-columns: 1fr;
            }

            .top-controls {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }

            table {
                display: block;
                overflow-x: auto;
            }
        }

        @media (max-width: 480px) {
            .header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>
    <!-- Sidebar -->
    <?php include 'sidebar.php'; ?>

    <div class="main-content">
        <div class="header">
            <h1><i class="fas fa-chart-line"></i> Dashboard Overview</h1>
        </div>

        <div class="top-controls">
            <div class="page-title">
                <h2>System Summary <span>(Live snapshot from Firebase)</span></h2>
            </div>
        </div>

        <!-- ======================
             TOP STATS (as requested)
             Total Drivers, Total Commuters,
             Total Trips, Average Rating
        ======================= -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-users"></i></div>
                <div class="stat-number">
                    <?php echo (int)n($driverStats['totalDrivers'] ?? $counts['total_drivers'] ?? 0); ?>
                </div>
                <div class="stat-label">Total Drivers</div>
            </div>

            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-user-friends"></i></div>
                <div class="stat-number">
                    <?php echo (int)n($commStats['totalCommuters'] ?? $counts['total_commuters'] ?? 0); ?>
                </div>
                <div class="stat-label">Total Commuters</div>
            </div>

            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-car"></i></div>
                <div class="stat-number">
                    <?php echo (int)n($tripStats['totalTrips'] ?? $counts['total_rides'] ?? 0); ?>
                </div>
                <div class="stat-label">Total Trips</div>
            </div>

            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-star"></i></div>
                <div class="stat-number">
                    <?php echo number_format((float)n($ratingStats['averageRating'] ?? 0), 1); ?>
                </div>
                <div class="stat-label">Average Rating</div>
            </div>
        </div>
        <!-- ======================
             TOP RATED DRIVERS
        ======================= -->
        <div class="section">
            <div class="section-header">
                <h3><i class="fas fa-crown"></i> Top Rated Drivers</h3>
                <div class="section-subtitle">
                    <?php echo $isScopedDashboard ? 'Top performers in your TODA' : 'Highlighting best performers (sorted by rating)'; ?>
                </div>
            </div>

            <div style="overflow-x:auto;">
                <table>
                    <thead>
                        <tr>
                            <th>Driver</th>
                            <th>Phone</th>
                            <th>Plate</th>
                            <th>Rating</th>
                            <th>Completed Trips</th>
                            <th>Total Ratings</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (!empty($topRatedDrivers)): ?>
                            <?php foreach ($topRatedDrivers as $driverId => $d): ?>
                                <?php
                                    $name      = $d['name'] ?? 'Unknown';
                                    $phone     = $d['phone'] ?? 'N/A';
                                    $plate     = $d['plateNumber'] ?? 'N/A';
                                    $rating    = (float)($d['currentRating'] ?? 0);
                                    $completed = (int)($d['completedTrips'] ?? 0);
                                    $ratingCnt = (int)($d['ratingCount'] ?? 0);
                                ?>
                                <tr>
                                    <td>
                                        <div class="person-info">
                                            <div class="person-avatar" style="background: linear-gradient(135deg,#f1c40f 0%,#e67e22 100%);">
                                                <?php echo htmlspecialchars(initials($name)); ?>
                                            </div>
                                            <div class="person-details">
                                                <div class="person-name"><?php echo htmlspecialchars($name); ?></div>
                                                <div class="person-sub">ID: <?php echo htmlspecialchars(substr($driverId, 0, 8) . '...'); ?></div>
                                            </div>
                                        </div>
                                    </td>
                                    <td><strong><?php echo htmlspecialchars($phone); ?></strong></td>
                                    <td><?php echo htmlspecialchars($plate); ?></td>
                                    <td style="font-weight: 600;">
                                        <i class="fas fa-star" style="color:#f1c40f;"></i>
                                        <?php echo number_format($rating, 1); ?>
                                    </td>
                                    <td><?php echo $completed; ?></td>
                                    <td><?php echo $ratingCnt; ?></td>
                                </tr>
                            <?php endforeach; ?>
                        <?php else: ?>
                            <tr>
                                <td colspan="6" class="no-data">
                                    <i class="fas fa-star-half-alt"></i><br>
                                    <div style="margin-top: 10px; font-size: 16px;">
                                        No rating data available yet.
                                    </div>
                                </td>
                            </tr>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- ======================
             RECENT TRIPS
        ======================= -->
        <div class="section">
            <div class="section-header">
                <h3><i class="fas fa-clock"></i> Recent Trips</h3>
                <div class="section-subtitle">
                    Showing <?php echo count($rides); ?> latest <?php echo $isScopedDashboard ? 'TODA' : 'system'; ?> records
                </div>
            </div>

            <div style="overflow-x:auto;">
                <table>
                    <thead>
                        <tr>
                            <th>Trip ID</th>
                            <th>Driver</th>
                            <th>Commuter</th>
                            <th>Origin</th>
                            <th>Destination</th>
                            <th>Fare</th>
                            <th>Status</th>
                            <th>Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (!empty($rides)): ?>
                            <?php foreach ($rides as $id => $ride): ?>
                                <?php
                                    $driverName   = $ride['driverName'] ?? $ride['driver_name'] ?? $ride['name'] ?? 'N/A';
                                    $commuterName = $ride['username'] ?? $ride['userName'] ?? $ride['user_name'] ?? $ride['passengerName'] ?? 'N/A';

                                    $origin = $ride['originAddress'] ??
                                        (is_array($ride['origin'] ?? null) ? ($ride['origin']['address'] ?? 'N/A') : ($ride['origin'] ?? 'N/A'));
                                    $dest   = $ride['destinationAddress'] ??
                                        (is_array($ride['destination'] ?? null) ? ($ride['destination']['address'] ?? 'N/A') : ($ride['destination'] ?? 'N/A'));

                                    $fare        = getTripFare($ride);
                                    $status      = $ride['status'] ?? 'unknown';
                                    $statusClass = tripStatusClass($status);
                                ?>
                                <tr>
                                    <td style="color:#7f8c8d; font-size: 13px;">
                                        <?php echo htmlspecialchars(substr((string)$id, 0, 8) . '...'); ?>
                                    </td>

                                    <td>
                                        <div class="person-info">
                                            <div class="person-avatar">
                                                <?php echo htmlspecialchars(initials($driverName)); ?>
                                            </div>
                                            <div class="person-details">
                                                <div class="person-name"><?php echo htmlspecialchars($driverName); ?></div>
                                                <div class="person-sub">Driver</div>
                                            </div>
                                        </div>
                                    </td>

                                    <td>
                                        <div class="person-info">
                                            <div class="person-avatar" style="background: linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%);">
                                                <?php echo htmlspecialchars(initials($commuterName)); ?>
                                            </div>
                                            <div class="person-details">
                                                <div class="person-name"><?php echo htmlspecialchars($commuterName); ?></div>
                                                <div class="person-sub">Commuter</div>
                                            </div>
                                        </div>
                                    </td>

                                    <td><?php echo htmlspecialchars(mb_strimwidth((string)$origin, 0, 28, '...')); ?></td>
                                    <td><?php echo htmlspecialchars(mb_strimwidth((string)$dest, 0, 28, '...')); ?></td>

                                    <td style="font-weight:600;">
                                        ₱<?php echo number_format((float)$fare, 2); ?>
                                    </td>

                                    <td>
                                        <span class="status-badge <?php echo $statusClass; ?>">
                                            <?php echo htmlspecialchars((string)$status); ?>
                                        </span>
                                    </td>

                                    <td style="color:#7f8c8d; font-size:13px;">
                                        <?php echo htmlspecialchars(fmtTime($ride['time'] ?? $ride['timestamp'] ?? $ride['createdAt'] ?? '')); ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        <?php else: ?>
                            <tr>
                                <td colspan="8" class="no-data">
                                    <i class="fas fa-car"></i><br>
                                    <div style="margin-top: 10px; font-size: 16px;">
                                        No trips found.
                                    </div>
                                </td>
                            </tr>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>

    </div>
</body>
</html>
