<?php
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_RATINGS_VIEW);

if (!isTodaMonitor() || empty(currentAdminTodaId())) {
    header('Location: ' . getRatingsRouteForCurrentUser());
    exit();
}

$todaId = currentAdminTodaId();
$todaName = getTodaName($todaId);
$searchTerm = trim((string)($_GET['search'] ?? ''));
$sortBy = $_GET['sort'] ?? 'rating';
$sortOrder = $_GET['order'] ?? 'desc';
$message = '';

$ratingsToDisplay = getRatingsForToda($todaId);
if ($searchTerm !== '') {
    $needle = strtolower($searchTerm);
    $ratingsToDisplay = array_filter($ratingsToDisplay, function ($driver) use ($needle) {
        if (!is_array($driver)) return false;
        $haystack = strtolower(
            ($driver['name'] ?? '') . ' ' .
            ($driver['phone'] ?? '') . ' ' .
            ($driver['permitNumber'] ?? '') . ' ' .
            ($driver['plateNumber'] ?? '')
        );
        return strpos($haystack, $needle) !== false;
    });
}

$ratingsToDisplay = sortRatings($ratingsToDisplay, $sortBy, $sortOrder);
$stats = getRatingStatisticsForToda($todaId, getRatingsForToda($todaId));
$registeredDriverCount = getRegisteredDriverCount($todaId);

$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = max(10, min(100, (int)($_GET['per_page'] ?? 20)));
$todaRatingsPaginationResult = paginateAssociativeArray($ratingsToDisplay, $page, $perPage);
$ratingsToDisplay = $todaRatingsPaginationResult['items'];
$todaRatingsPagination = $todaRatingsPaginationResult['pagination'];

function todaRatingsLastRated($timestamp) {
    if (!$timestamp) return 'Not rated yet';
    $ts = parseTimestamp($timestamp);
    return $ts ? date('M d, Y h:i A', $ts) : 'Not rated yet';
}

function todaRatingsSortLink($column, $currentSort, $currentOrder) {
    $nextOrder = ($currentSort === $column && $currentOrder === 'desc') ? 'asc' : 'desc';
    $query = $_GET;
    $query['sort'] = $column;
    $query['order'] = $nextOrder;
    return '?' . http_build_query($query);
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($todaName); ?> Ratings - Kaltrike Admin</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .main-content { padding-bottom: 36px !important; }
        .hero {
            display: grid;
            grid-template-columns: 1.4fr minmax(300px, 0.85fr);
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
        .eyebrow {
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
        h1 { margin: 0 0 10px; font-size: clamp(2rem, 2.8vw, 2.8rem); }
        .subtitle { color: #64748b; line-height: 1.65; }
        .search-form {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
            margin-top: 20px;
        }
        .search-form input {
            flex: 1;
            min-width: 220px;
        }
        .btn-primary, .btn-light {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 12px 18px;
            border-radius: 14px;
            text-decoration: none;
            font-weight: 700;
            border: 0;
        }
        .btn-primary { background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); color: #fff; }
        .btn-light { background: #eff6ff; color: #1d4ed8; }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 18px;
            margin-bottom: 22px;
        }
        .stat-value { font-size: clamp(1.7rem, 2.5vw, 2.4rem); font-weight: 800; margin: 10px 0 6px; }
        .stat-label { color: #64748b; font-weight: 600; }
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; min-width: 760px; }
        th, td { padding: 14px 12px; border-bottom: 1px solid #e5edf8; text-align: left; }
        th a { color: inherit; text-decoration: none; }
        .rating-pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 12px;
            border-radius: 999px;
            background: #eff6ff;
            color: #1d4ed8;
            font-weight: 700;
        }
        .driver-name { font-weight: 700; color: #0f172a; }
        .driver-meta { color: #64748b; font-size: 13px; }
        .empty-state {
            padding: 30px;
            border: 1px dashed #cbd5e1;
            border-radius: 18px;
            text-align: center;
            color: #64748b;
            background: #f8fbff;
        }
        @media (max-width: 1120px) {
            .hero,
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
                <div class="eyebrow"><i class="fa-solid fa-star"></i> TODA Ratings Workspace</div>
                <h1><?php echo htmlspecialchars($todaName); ?> Ratings</h1>
                <p class="subtitle">This page is separated from the super admin ratings page. It only shows the drivers assigned to <strong><?php echo htmlspecialchars($todaName); ?></strong>.</p>
                <form class="search-form" method="GET">
                    <input type="text" name="search" value="<?php echo htmlspecialchars($searchTerm); ?>" placeholder="Search driver, phone, permit, or plate number">
                    <button class="btn-primary" type="submit"><i class="fa-solid fa-magnifying-glass"></i> Search</button>
                    <a class="btn-light" href="toda_ratings.php"><i class="fa-solid fa-rotate-left"></i> Reset</a>
                </form>
            </div>
            <div class="hero-card">
                <div class="stat-label">Registered drivers in this TODA</div>
                <div class="stat-value"><?php echo (int)$registeredDriverCount; ?></div>
                <div class="stat-label">Average rating</div>
                <div class="stat-value"><?php echo number_format((float)($stats['averageRating'] ?? 0), 1); ?></div>
            </div>
        </section>

        <section class="stats-grid">
            <div class="panel-card">
                <div class="stat-label">Registered Drivers</div>
                <div class="stat-value"><?php echo (int)$registeredDriverCount; ?></div>
            </div>
            <div class="panel-card">
                <div class="stat-label">Rated Drivers</div>
                <div class="stat-value"><?php echo (int)($stats['ratedDrivers'] ?? 0); ?></div>
            </div>
            <div class="panel-card">
                <div class="stat-label">Unrated Drivers</div>
                <div class="stat-value"><?php echo (int)($stats['unratedDrivers'] ?? 0); ?></div>
            </div>
            <div class="panel-card">
                <div class="stat-label">Top Rated Drivers</div>
                <div class="stat-value"><?php echo (int)($stats['topRatedCount'] ?? 0); ?></div>
            </div>
        </section>

        <section class="panel-card">
            <h2 style="margin:0 0 16px;"><i class="fa-solid fa-list"></i> Driver Ratings</h2>
            <?php if (!empty($ratingsToDisplay)): ?>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th><a href="<?php echo htmlspecialchars(todaRatingsSortLink('name', $sortBy, $sortOrder)); ?>">Driver</a></th>
                                <th><a href="<?php echo htmlspecialchars(todaRatingsSortLink('rating', $sortBy, $sortOrder)); ?>">Current Rating</a></th>
                                <th><a href="<?php echo htmlspecialchars(todaRatingsSortLink('ratingCount', $sortBy, $sortOrder)); ?>">Ratings Count</a></th>
                                <th><a href="<?php echo htmlspecialchars(todaRatingsSortLink('completedTrips', $sortBy, $sortOrder)); ?>">Completed Trips</a></th>
                                <th>Plate / Permit</th>
                                <th><a href="<?php echo htmlspecialchars(todaRatingsSortLink('lastRated', $sortBy, $sortOrder)); ?>">Last Rated</a></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($ratingsToDisplay as $driverId => $driver): ?>
                                <tr>
                                    <td>
                                        <div class="driver-name"><?php echo htmlspecialchars($driver['name'] ?? 'Unknown'); ?></div>
                                        <div class="driver-meta"><?php echo htmlspecialchars($driver['phone'] ?? ''); ?></div>
                                    </td>
                                    <td><span class="rating-pill"><i class="fa-solid fa-star"></i> <?php echo number_format((float)($driver['currentRating'] ?? 0), 1); ?></span></td>
                                    <td><?php echo (int)($driver['ratingCount'] ?? 0); ?></td>
                                    <td><?php echo (int)($driver['completedTrips'] ?? 0); ?></td>
                                    <td>
                                        <div class="driver-name"><?php echo htmlspecialchars($driver['plateNumber'] ?? 'No plate'); ?></div>
                                        <div class="driver-meta"><?php echo htmlspecialchars($driver['permitNumber'] ?? 'No permit'); ?></div>
                                    </td>
                                    <td><?php echo htmlspecialchars(todaRatingsLastRated($driver['lastRated'] ?? null)); ?></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php else: ?>
                <div class="empty-state">No assigned driver ratings matched your search.</div>
            <?php endif; ?>
        </section>
    </main>
        <?php if (($todaRatingsPagination['total_pages'] ?? 1) > 1): ?>
        <div style="display:flex; justify-content:space-between; align-items:center; gap:12px; flex-wrap:wrap; padding:8px 6px 0;">
            <div style="font-size:13px; color:#64748b;">Page <?php echo $todaRatingsPagination['current_page']; ?> of <?php echo $todaRatingsPagination['total_pages']; ?></div>
            <div style="display:flex; gap:8px; flex-wrap:wrap;">
                <?php if ($todaRatingsPagination['has_previous']): ?><a class="panel-link" href="<?php echo htmlspecialchars(buildQueryUrl(['page' => $todaRatingsPagination['current_page'] - 1])); ?>">Previous</a><?php endif; ?>
                <?php if ($todaRatingsPagination['has_next']): ?><a class="panel-link" href="<?php echo htmlspecialchars(buildQueryUrl(['page' => $todaRatingsPagination['current_page'] + 1])); ?>">Next</a><?php endif; ?>
            </div>
        </div>
        <?php endif; ?>
</body>
</html>
