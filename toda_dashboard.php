<?php
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_DASHBOARD_VIEW);

if (!isTodaMonitor() || empty(currentAdminTodaId())) {
    header('Location: ' . getDashboardRouteForCurrentUser());
    exit();
}

$todaId = currentAdminTodaId();
$todaName = getTodaName($todaId);
$drivers = getDriversForToda($todaId);
$driverStats = getDriverStatisticsForToda($todaId, $drivers);
$ratings = getRatingsForToda($todaId);
$ratingStats = getRatingStatisticsForToda($todaId, $ratings);
[$todaByDriverId, $todaByPhone] = buildDriverTodaIndex();
$trips = getTripsForToda($todaId, null, $todaByDriverId, $todaByPhone);
$tripStats = getTripStatisticsForToda($todaId, $trips);

$registeredDriverCount = getRegisteredDriverCount($todaId, $drivers);

$latestTrips = $trips;
if (!empty($latestTrips)) {
    uasort($latestTrips, function ($a, $b) {
        $ta = parseTimestamp($a['time'] ?? $a['timestamp'] ?? $a['createdAt'] ?? null) ?: 0;
        $tb = parseTimestamp($b['time'] ?? $b['timestamp'] ?? $b['createdAt'] ?? null) ?: 0;
        return $tb <=> $ta;
    });
    $latestTrips = array_slice($latestTrips, 0, 8, true);
}

$topDrivers = $ratings;
if (!empty($topDrivers)) {
    uasort($topDrivers, function ($a, $b) {
        $ratingCompare = ((float)($b['currentRating'] ?? 0)) <=> ((float)($a['currentRating'] ?? 0));
        if ($ratingCompare !== 0) return $ratingCompare;
        return ((int)($b['completedTrips'] ?? 0)) <=> ((int)($a['completedTrips'] ?? 0));
    });
    $topDrivers = array_slice($topDrivers, 0, 6, true);
}

function todaDashboardTime($value) {
    $ts = parseTimestamp($value);
    return $ts ? date('M d, Y h:i A', $ts) : 'N/A';
}

function todaDashboardStatusClass($status) {
    $status = strtolower((string)$status);
    if (in_array($status, ['completed', 'ended', 'finished'], true)) return 'status-good';
    if (in_array($status, ['pending', 'requested', 'waiting'], true)) return 'status-warn';
    if (in_array($status, ['cancelled', 'canceled', 'rejected'], true)) return 'status-bad';
    return 'status-info';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($todaName); ?> Dashboard - Kaltrike Admin</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .main-content { padding-bottom: 40px !important; }
        .hero {
            display: grid;
            grid-template-columns: 1fr;
            gap: 18px;
            margin-bottom: 22px;
        }
        .hero-card,
        .panel-card {
            background: rgba(255,255,255,0.96);
            border: 1px solid #dbe6f3;
            border-radius: 26px;
            box-shadow: 0 24px 48px rgba(15, 23, 42, 0.10);
            padding: 24px;
        }
        .hero-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 14px;
            border-radius: 999px;
            background: rgba(37, 99, 235, 0.10);
            color: #1d4ed8;
            font-weight: 700;
            font-size: 13px;
            margin-bottom: 16px;
        }
        .hero h1 {
            margin: 0;
            font-size: clamp(2rem, 2.8vw, 2.8rem);
        }
        .hero-actions {
            margin-top: 18px;
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
        }
        .hero-actions a {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 12px 18px;
            border-radius: 14px;
            text-decoration: none;
            font-weight: 700;
        }
        .btn-primary { background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); color: #fff; }
        .btn-secondary { background: #eff6ff; color: #1d4ed8; }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 18px;
            margin-bottom: 22px;
        }
        .stat-value {
            font-size: clamp(1.7rem, 2.4vw, 2.4rem);
            font-weight: 800;
            color: #0f172a;
            margin: 14px 0 8px;
        }
        .stat-label { color: #64748b; font-weight: 600; }
        .stat-meta { color: #1d4ed8; font-size: 13px; font-weight: 700; }
        .panel-grid {
            display: grid;
            grid-template-columns: 1.05fr 1fr;
            gap: 18px;
        }
        .panel-card h2 {
            margin: 0 0 16px;
            font-size: 1.2rem;
        }
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; min-width: 620px; }
        th, td { padding: 14px 12px; border-bottom: 1px solid #e5edf8; text-align: left; }
        th { color: #475569; font-size: 12px; text-transform: uppercase; letter-spacing: 0.06em; }
        .status-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: 999px;
            font-weight: 700;
            font-size: 12px;
        }
        .status-good { background: #dcfce7; color: #166534; }
        .status-info { background: #dbeafe; color: #1d4ed8; }
        .status-warn { background: #fef3c7; color: #b45309; }
        .status-bad { background: #fee2e2; color: #b91c1c; }
        .driver-name { font-weight: 700; color: #0f172a; }
        .driver-meta { color: #64748b; font-size: 13px; }
        .empty-state {
            padding: 28px;
            border: 1px dashed #cbd5e1;
            border-radius: 18px;
            text-align: center;
            color: #64748b;
            background: #f8fbff;
        }
        @media (max-width: 1180px) {
            .hero,
            .panel-grid,
            .stats-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>
    <?php include 'sidebar.php'; ?>
    <main class="main-content">
        <section class="hero">
            <div class="hero-card">
                <div class="hero-badge"><i class="fa-solid fa-location-dot"></i> TODA Monitor Workspace</div>
                <h1><?php echo htmlspecialchars($todaName); ?> Dashboard</h1>                <div class="hero-actions">
                    <a class="btn-primary" href="<?php echo htmlspecialchars(getDriversRouteForCurrentUser()); ?>"><i class="fa-solid fa-user-tie"></i> View Drivers</a>
                    <a class="btn-secondary" href="trips.php"><i class="fa-solid fa-route"></i> View Trips</a>
                    <a class="btn-secondary" href="toda_ratings.php"><i class="fa-solid fa-star"></i> View Ratings</a>
                </div>
            </div>
        </section>

        <section class="stats-grid">
            <div class="panel-card">
                <div class="stat-label">Registered Drivers</div>
                <div class="stat-value"><?php echo (int)$registeredDriverCount; ?></div>
                <div class="stat-meta">Assigned to <?php echo htmlspecialchars($todaName); ?></div>
            </div>
            <div class="panel-card">
                <div class="stat-label">Active Drivers</div>
                <div class="stat-value"><?php echo (int)($driverStats['activeDrivers'] ?? 0); ?></div>
                <div class="stat-meta">Currently marked active in driver records</div>
            </div>
            <div class="panel-card">
                <div class="stat-label">Trip History</div>
                <div class="stat-value"><?php echo (int)($tripStats['totalTrips'] ?? 0); ?></div>
                <div class="stat-meta">Completed: <?php echo (int)($tripStats['completedTrips'] ?? 0); ?></div>
            </div>
            <div class="panel-card">
                <div class="stat-label">Rated Drivers</div>
                <div class="stat-value"><?php echo (int)($ratingStats['ratedDrivers'] ?? 0); ?></div>
                <div class="stat-meta">Top rated: <?php echo (int)($ratingStats['topRatedCount'] ?? 0); ?></div>
            </div>
        </section>

        <section class="panel-grid">
            <div class="panel-card">
                <h2><i class="fa-solid fa-star"></i> Assigned Driver Ratings</h2>
                <?php if (!empty($topDrivers)): ?>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>Driver</th>
                                    <th>Rating</th>
                                    <th>Rated Trips</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                            <?php foreach ($topDrivers as $driverId => $driver): ?>
                                <tr>
                                    <td>
                                        <div class="driver-name"><?php echo htmlspecialchars($driver['name'] ?? 'Unknown'); ?></div>
                                        <div class="driver-meta"><?php echo htmlspecialchars($driver['phone'] ?? ''); ?></div>
                                    </td>
                                    <td><?php echo number_format((float)($driver['currentRating'] ?? 0), 1); ?> / 5</td>
                                    <td><?php echo (int)($driver['ratingCount'] ?? 0); ?></td>
                                    <td>
                                        <span class="status-pill <?php echo ((float)($driver['currentRating'] ?? 0) >= 4.5) ? 'status-good' : 'status-info'; ?>">
                                            <?php echo ((float)($driver['currentRating'] ?? 0) >= 4.5) ? 'Top performer' : 'Tracked'; ?>
                                        </span>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php else: ?>
                    <div class="empty-state">No driver rating records are available for this TODA yet.</div>
                <?php endif; ?>
            </div>

            <div class="panel-card">
                <h2><i class="fa-solid fa-clock-rotate-left"></i> Latest Trips</h2>
                <?php if (!empty($latestTrips)): ?>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>Driver</th>
                                    <th>Status</th>
                                    <th>Fare</th>
                                    <th>Time</th>
                                </tr>
                            </thead>
                            <tbody>
                            <?php foreach ($latestTrips as $tripId => $trip): ?>
                                <?php $driverName = $trip['driverName'] ?? $trip['driver_name'] ?? $trip['driver'] ?? 'Unknown driver'; ?>
                                <?php $tripStatus = $trip['status'] ?? 'unknown'; ?>
                                <tr>
                                    <td>
                                        <div class="driver-name"><?php echo htmlspecialchars($driverName); ?></div>
                                        <div class="driver-meta">Trip ID: <?php echo htmlspecialchars($tripId); ?></div>
                                    </td>
                                    <td><span class="status-pill <?php echo todaDashboardStatusClass($tripStatus); ?>"><?php echo htmlspecialchars(ucfirst((string)$tripStatus)); ?></span></td>
                                    <td>₱<?php echo number_format((float)getTripFare($trip), 2); ?></td>
                                    <td><?php echo htmlspecialchars(todaDashboardTime($trip['time'] ?? $trip['timestamp'] ?? $trip['createdAt'] ?? null)); ?></td>
                                </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php else: ?>
                    <div class="empty-state">No trip records are available for this TODA yet.</div>
                <?php endif; ?>
            </div>
        </section>
    </main>
</body>
</html>
