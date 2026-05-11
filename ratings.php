<?php
// ratings.php - Ratings Management System
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_RATINGS_VIEW);

if (isTodaMonitor() && !empty(currentAdminTodaId())) {
    header('Location: toda_ratings.php');
    exit();
}

// Ratings are read-only in the admin panel.

$message = '';
$messageType = 'success';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    requirePermission(PERM_DRIVERS_MANAGE);

    if ($_POST['action'] === 'bulk_delete') {
        $bulkDeleteResult = bulkDeleteRecords($_POST['selected_ids'] ?? [], 'deleteDriver');

        if ($bulkDeleteResult['requested'] === 0) {
            $message = 'Please select at least one driver to delete.';
            $messageType = 'error';
        } elseif ($bulkDeleteResult['failed'] === 0) {
            $message = 'Deleted ' . $bulkDeleteResult['deleted'] . ' driver(s) from ratings successfully.';
            $messageType = 'success';
        } else {
            $message = 'Deleted ' . $bulkDeleteResult['deleted'] . ' driver(s). Failed to delete ' . $bulkDeleteResult['failed'] . ' selected record(s).';
            $messageType = $bulkDeleteResult['deleted'] > 0 ? 'success' : 'error';
        }
    }
}

// Get statistics
$stats = getRatingStatistics();
$selectedTodaId = null;
$registeredDriverCount = getRegisteredDriverCount();

// TODA list
$todas = getAllTodas();

// Check for search
if (isset($_GET['search']) && !empty($_GET['search'])) {
    $searchTerm = trim($_GET['search']);
    $ratingsToDisplay = searchRatings($searchTerm);
} else {
    $ratingsToDisplay = getAllRatings();
}

// TODA filter / scope
$todaFilter = $_GET['toda_id'] ?? '';
$isScopedTODA = (!isSuperAdmin() && currentAdminRole() !== ROLE_BPLO_VERIFIER);
if ($isScopedTODA) {
    $todaFilter = currentAdminTodaId();
}

if ($todaFilter !== '') {
    $ratingsToDisplay = array_filter($ratingsToDisplay, function($r) use ($todaFilter) {
        if (!is_array($r)) return false;
        return (string)($r['todaId'] ?? '') === (string)$todaFilter;
    });
}

$selectedTodaId = $todaFilter !== '' ? $todaFilter : null;
$stats = getRatingStatisticsForToda($selectedTodaId);
$registeredDriverCount = getRegisteredDriverCount($selectedTodaId);

// Handle sorting
$sortBy = $_GET['sort'] ?? 'rating';
$sortOrder = $_GET['order'] ?? 'desc';

// Apply sorting to ratings
if (!empty($ratingsToDisplay)) {
    $ratingsToDisplay = sortRatings($ratingsToDisplay, $sortBy, $sortOrder);
}

$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = max(10, min(100, (int)($_GET['per_page'] ?? 20)));
$ratingsPaginationResult = paginateAssociativeArray($ratingsToDisplay, $page, $perPage);
$ratingsToDisplay = $ratingsPaginationResult['items'];
$ratingsPagination = $ratingsPaginationResult['pagination'];

// Function to get sort icon
function getSortIcon($column, $currentSort, $currentOrder) {
    if ($currentSort === $column) {
        if ($currentOrder === 'asc') return 'fa-sort-up';
        return 'fa-sort-down';
    }
    return 'fa-sort';
}

// Function to generate star rating HTML
function generateStars($rating, $size = 'normal') {
    $rating = max(0, min(5, floatval($rating)));

    $fullStars = floor($rating);
    $halfStar = ($rating - $fullStars) >= 0.5;
    $emptyStars = 5 - $fullStars - ($halfStar ? 1 : 0);

    $sizeClass = $size === 'large' ? 'star-large' : ($size === 'small' ? 'star-small' : 'star-normal');

    $html = '<div class="star-rating ' . $sizeClass . '">';

    for ($i = 0; $i < $fullStars; $i++) $html .= '<span class="star star-full">★</span>';
    if ($halfStar) $html .= '<span class="star star-half">★</span>';
    for ($i = 0; $i < $emptyStars; $i++) $html .= '<span class="star star-empty">★</span>';

    $html .= '<span class="rating-text">' . number_format($rating, 1) . '</span>';
    $html .= '</div>';

    return $html;
}

// Function to format last rated time
function formatLastRated($timestamp) {
    if (!$timestamp) return 'Never';

    $diff = time() - (int)$timestamp;

    if ($diff < 60) return 'Just now';
    if ($diff < 3600) {
        $minutes = floor($diff / 60);
        return $minutes . ' min' . ($minutes > 1 ? 's' : '') . ' ago';
    }
    if ($diff < 86400) {
        $hours = floor($diff / 3600);
        return $hours . ' hour' . ($hours > 1 ? 's' : '') . ' ago';
    }
    if ($diff < 2592000) {
        $days = floor($diff / 86400);
        return $days . ' day' . ($days > 1 ? 's' : '') . ' ago';
    }

    return date('M d, Y', (int)$timestamp);
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ratings - Kaltrike Admin</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel=\"stylesheet\" href=\"assets/styles.css\">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f6fa;
            color: #2c3e50;
            display: flex;
            min-height: 100vh;
        }

        .sidebar {
            position: fixed;
            left: 0; top: 0;
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

        .logo span { font-weight: 600; }

        .nav-links { list-style: none; padding: 20px 0; }
        .nav-links li { margin: 5px 0; }

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

        .nav-links a:hover { background: rgba(255,255,255,0.1); color: white; }

        /* Keep same structure as commuters.php; ratings uses a gold accent */
        .nav-links a.active {
            background: rgba(255,255,255,0.15);
            color: white;
            border-left-color: #f39c12;
        }

        .nav-links i { width: 20px; text-align: center; font-size: 16px; }

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

        .header h1 { color: #2c3e50; font-size: 28px; font-weight: 600; }

        .top-controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            gap: 20px;
        }

        .page-title h2 { color: #2c3e50; font-size: 22px; font-weight: 600; }
        .page-title span { color: #7f8c8d; font-size: 14px; font-weight: normal; }

        .control-buttons { display: flex; gap: 15px; align-items: center; }

        .sort-container { position: relative; }

        .sort-btn {
            background: white;
            color: #2c3e50;
            border: 2px solid #ddd;
            padding: 9px 15px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
            min-width: 160px;
            justify-content: space-between;
        }

        .sort-btn:hover { border-color: #3498db; background: #f8f9fa; }

        .sort-dropdown {
            display: none;
            position: absolute;
            top: 100%;
            left: 0; right: 0;
            background: white;
            border: 2px solid #ddd;
            border-radius: 6px;
            margin-top: 5px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            z-index: 100;
        }

        .sort-dropdown.show { display: block; }

        .sort-option {
            padding: 10px 15px;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 10px;
            transition: all 0.2s;
        }

        .sort-option:hover { background: #f8f9fa; }
        .sort-option.active { background: #e8f4fc; color: #3498db; font-weight: 600; }
        .sort-option i { width: 16px; text-align: center; }

        .search-container { margin-bottom: 25px; position: relative; }

        .search-box {
            width: 100%;
            padding: 14px 20px;
            padding-left: 45px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 15px;
            transition: all 0.3s;
            background: white;
        }

        .search-box:focus {
            border-color: #3498db;
            outline: none;
            box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
        }

        .search-icon {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: #7f8c8d;
            font-size: 16px;
        }

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

        .stat-card:hover { transform: translateY(-5px); }

        .stat-card:nth-child(1) { border-top-color: #3498db; }
        .stat-card:nth-child(2) { border-top-color: #f39c12; }
        .stat-card:nth-child(3) { border-top-color: #9b59b6; }
        .stat-card:nth-child(4) { border-top-color: #27ae60; }
        .stat-card:nth-child(5) { border-top-color: #e74c3c; }
        .stat-card:nth-child(6) { border-top-color: #34495e; }

        .stat-icon { font-size: 30px; margin-bottom: 15px; opacity: 0.8; }
        .stat-card:nth-child(1) .stat-icon { color: #3498db; }
        .stat-card:nth-child(2) .stat-icon { color: #f39c12; }
        .stat-card:nth-child(3) .stat-icon { color: #9b59b6; }
        .stat-card:nth-child(4) .stat-icon { color: #27ae60; }
        .stat-card:nth-child(5) .stat-icon { color: #e74c3c; }
        .stat-card:nth-child(6) .stat-icon { color: #34495e; }

        .stat-number { font-size: 32px; font-weight: bold; color: #2c3e50; margin: 10px 0; line-height: 1; }
        .stat-label { color: #7f8c8d; font-size: 13px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600; }

        .ratings-table-container {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            overflow: hidden;
        }

        .table-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .table-header h3 { color: #2c3e50; font-size: 18px; font-weight: 600; }
        .rating-count { color: #7f8c8d; font-size: 14px; }

        table { width: 100%; border-collapse: collapse; font-size: 14px; }

        th {
            background-color: #f8f9fa;
            padding: 15px;
            text-align: left;
            color: #2c3e50;
            border-bottom: 2px solid #e0e0e0;
            font-weight: 600;
            white-space: nowrap;
            cursor: pointer;
            user-select: none;
        }

        th:hover { background-color: #eef2f7; }

        .sortable-header { display: flex; align-items: center; gap: 8px; }
        .sort-icon { color: #7f8c8d; font-size: 12px; }

        td { padding: 15px; border-bottom: 1px solid #eee; vertical-align: middle; }
        tr:hover { background-color: #f9f9f9; }

        .driver-info { display: flex; align-items: center; gap: 12px; }

        .driver-avatar {
            width: 40px; height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #f39c12 0%, #e74c3c 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 16px;
            flex-shrink: 0;
        }

        .driver-details { display: flex; flex-direction: column; }
        .driver-name { font-weight: 600; color: #2c3e50; margin-bottom: 3px; }

        .driver-contact {
            color: #7f8c8d;
            font-size: 12px;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }

        .star-rating { display: flex; align-items: center; gap: 3px; }
        .star { font-size: 18px; color: #e2e8f0; }

        .star-large .star { font-size: 24px; }
        .star-normal .star { font-size: 18px; }
        .star-small .star { font-size: 14px; }

        .star-full { color: #f39c12; }

        .star-half {
            color: #f39c12;
            position: relative;
        }

        .star-half:after {
            content: '★';
            position: absolute;
            left: 0;
            width: 50%;
            overflow: hidden;
            color: #e2e8f0;
        }

        .rating-text { margin-left: 8px; font-weight: 600; color: #2c3e50; }

        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }

        .status-validated { background-color: #d5f4e6; color: #27ae60; }
        .status-pending { background-color: #fff3cd; color: #856404; }
        .status-inactive { background-color: #d1ecf1; color: #0c5460; }

        .active-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-top: 5px;
        }

        .active-true { background: #d5f4e6; color: #27ae60; }
        .active-false { background: #fed7d7; color: #742a2a; }

        .action-buttons { display: flex; gap: 8px; }

        .action-btn {
            padding: 6px 12px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 12px;
            font-weight: 600;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 5px;
            background: #f8f9fa;
            color: #2c3e50;
            border: 1px solid #ddd;
        }

        .action-btn:hover { transform: translateY(-2px); box-shadow: 0 3px 8px rgba(0,0,0,0.1); }

        .btn-view:hover { background-color: #3498db; color: white; border-color: #3498db; }
        .btn-recalculate:hover { background-color: #f39c12; color: white; border-color: #f39c12; }
        .btn-update:hover { background-color: #27ae60; color: white; border-color: #27ae60; }

        .no-data { text-align: center; padding: 60px 20px; color: #7f8c8d; }
        .no-data i { font-size: 48px; margin-bottom: 15px; color: #bdc3c7; }

        .message-box {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 8px;
            color: white;
            font-weight: 600;
            z-index: 2000;
            animation: slideInMessage 0.3s;
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
            display: flex;
            align-items: center;
            gap: 10px;
            max-width: 400px;
        }

        @keyframes slideInMessage {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }

        .message-success {
            background: linear-gradient(135deg, #27ae60 0%, #219653 100%);
            border-left: 4px solid #1e874b;
        }

        .message-error {
            background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
            border-left: 4px solid #a93226;
        }

        .modal {
            display: none;
            position: fixed;
            top: 0; left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 3000;
            justify-content: center;
            align-items: center;
        }

        .modal-content {
            background: white;
            border-radius: 10px;
            padding: 30px;
            width: 90%;
            max-width: 500px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 1px solid #eee;
        }

        .modal-header h3 {
            color: #2c3e50;
            font-size: 18px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .modal-close {
            background: none;
            border: none;
            font-size: 24px;
            color: #7f8c8d;
            cursor: pointer;
            transition: color 0.3s;
        }

        .modal-close:hover { color: #2c3e50; }

        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; margin-bottom: 8px; font-weight: 600; color: #2c3e50; }

        .form-control {
            width: 100%;
            padding: 10px 15px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: all 0.3s;
        }

        .form-control:focus {
            outline: none;
            border-color: #3498db;
            box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
        }

        .form-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 25px; }

        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
        }

        .btn-warning { background: #f39c12; color: white; }
        .btn-warning:hover { background: #d68910; transform: translateY(-2px); box-shadow: 0 3px 10px rgba(243,156,18,0.3); }

        .btn-success { background: #27ae60; color: white; }
        .btn-success:hover { background: #219653; transform: translateY(-2px); box-shadow: 0 3px 10px rgba(39,174,96,0.3); }

        .btn-secondary { background: #95a5a6; color: white; }
        .btn-secondary:hover { background: #7f8c8d; transform: translateY(-2px); }

        @media (max-width: 1024px) { .stats-grid { grid-template-columns: repeat(2, 1fr); } }

        @media (max-width: 768px) {
            .sidebar { width: 100%; height: auto; position: relative; margin-bottom: 20px; }
            .main-content { margin-left: 0; padding: 15px; }
            .stats-grid { grid-template-columns: 1fr; }
            .top-controls { flex-direction: column; align-items: flex-start; gap: 15px; }
            .control-buttons { width: 100%; justify-content: space-between; }
            table { display: block; overflow-x: auto; }
        }

        @media (max-width: 480px) {
            .header { flex-direction: column; align-items: flex-start; gap: 15px; }
            .action-buttons { flex-direction: column; width: 100%; }
            .action-btn { width: 100%; justify-content: center; }
            .control-buttons { flex-direction: column; gap: 10px; }
            .modal-content { padding: 20px; width: 95%; }
            .form-actions { flex-direction: column; }
            .btn { width: 100%; justify-content: center; }
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>

    <!-- Sidebar -->
    <?php include 'sidebar.php'; ?>

    <div class="main-content">
        <div class="header">
            <h1><i class="fas fa-star"></i> Driver Ratings Management</h1>
        </div>

        <!-- Message Box -->
        <?php if ($message): ?>
        <div class="message-box message-<?php echo $messageType; ?>" id="messageBox">
            <i class="fas fa-<?php echo $messageType == 'success' ? 'check-circle' : 'exclamation-circle'; ?>"></i>
            <?php echo $message; ?>
        </div>
        <?php endif; ?>

        <!-- Top Controls -->
        <div class="top-controls">
            <div class="page-title">
                <h2>Driver Ratings <span>(<?php echo $registeredDriverCount; ?> registered drivers<?php echo $selectedTodaId ? ' in ' . htmlspecialchars(getTodaName($selectedTodaId)) : ''; ?>)</span></h2>
            </div>
            <div class="control-buttons">
                <div class="sort-container">
                    <button class="sort-btn" onclick="toggleSortDropdown()" type="button">
                        <span><i class="fas fa-sort-amount-down"></i> Sort</span>
                        <i class="fas fa-chevron-down"></i>
                    </button>
                    <div class="sort-dropdown" id="sortDropdown">
                        <div class="sort-option <?php echo $sortBy == 'rating' && $sortOrder == 'desc' ? 'active' : ''; ?>"
                             onclick="sortBy('rating', 'desc')">
                            <i class="fas fa-star"></i>
                            <span>Rating (High to Low)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'rating' && $sortOrder == 'asc' ? 'active' : ''; ?>"
                             onclick="sortBy('rating', 'asc')">
                            <i class="fas fa-star"></i>
                            <span>Rating (Low to High)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'name' && $sortOrder == 'asc' ? 'active' : ''; ?>"
                             onclick="sortBy('name', 'asc')">
                            <i class="fas fa-sort-alpha-down"></i>
                            <span>Name (A-Z)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'name' && $sortOrder == 'desc' ? 'active' : ''; ?>"
                             onclick="sortBy('name', 'desc')">
                            <i class="fas fa-sort-alpha-down-alt"></i>
                            <span>Name (Z-A)</span>
                        </div>
<div class="sort-option <?php echo $sortBy == 'toda' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
     onclick="sortBy('toda', 'asc')">
    <i class="fas fa-building-user"></i>
    <span>TODA (A-Z)</span>
</div>
<div class="sort-option <?php echo $sortBy == 'toda' && $sortOrder == 'desc' ? 'active' : ''; ?>" 
     onclick="sortBy('toda', 'desc')">
    <i class="fas fa-building-user"></i>
    <span>TODA (Z-A)</span>
</div>
                        <div class="sort-option <?php echo $sortBy == 'ratingCount' && $sortOrder == 'desc' ? 'active' : ''; ?>"
                             onclick="sortBy('ratingCount', 'desc')">
                            <i class="fas fa-sort-numeric-down"></i>
                            <span>Rating Count (High)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'completedTrips' && $sortOrder == 'desc' ? 'active' : ''; ?>"
                             onclick="sortBy('completedTrips', 'desc')">
                            <i class="fas fa-road"></i>
                            <span>Trips (High)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'lastRated' && $sortOrder == 'desc' ? 'active' : ''; ?>"
                             onclick="sortBy('lastRated', 'desc')">
                            <i class="fas fa-calendar"></i>
                            <span>Recently Rated</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Statistics Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-users"></i></div>
                <div class="stat-number"><?php echo $stats['totalDrivers']; ?></div>
                <div class="stat-label">Registered Drivers</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-star"></i></div>
                <div class="stat-number"><?php echo $stats['ratedDrivers']; ?></div>
                <div class="stat-label">Rated Drivers</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-star-half-alt"></i></div>
                <div class="stat-number"><?php echo $stats['averageRating']; ?></div>
                <div class="stat-label">Average Rating</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-crown"></i></div>
                <div class="stat-number"><?php echo $stats['topRatedCount']; ?></div>
                <div class="stat-label">Top Rated (4.5+)</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-exclamation-triangle"></i></div>
                <div class="stat-number"><?php echo $stats['lowRatedCount']; ?></div>
                <div class="stat-label">Low Rated (&lt;3.0)</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-question-circle"></i></div>
                <div class="stat-number"><?php echo $stats['unratedDrivers']; ?></div>
                <div class="stat-label">Unrated Drivers</div>
            </div>
        </div>

        <!-- Search Box -->
        <div class="search-container">
            <form method="GET" action="" id="searchForm">
                <i class="fas fa-search search-icon"></i>
                <input type="text" name="search" class="search-box"
                       placeholder="Search drivers by name, phone, permit or plate..."
                       value="<?php echo isset($_GET['search']) ? htmlspecialchars($_GET['search']) : ''; ?>">
<?php if (!$isScopedTODA): ?>
<select name="toda_id" class="filter-input" style="width: 220px; margin-left: 10px;" onchange="document.getElementById('searchForm').submit();">
    <option value="">All TODAs</option>
    <?php if (is_array($todas) && !empty($todas)): ?>
        <?php foreach ($todas as $tid => $td): ?>
            <option value="<?php echo htmlspecialchars($tid); ?>" <?php echo (($todaFilter ?? '') == $tid) ? 'selected' : ''; ?>>
                <?php echo htmlspecialchars($td['name'] ?? $tid); ?>
            </option>
        <?php endforeach; ?>
    <?php endif; ?>
</select>
<?php else: ?>
<input type="text" class="filter-input" style="width: 220px; margin-left: 10px;" value="<?php echo htmlspecialchars(getTodaName($todaFilter)); ?>" disabled>
<input type="hidden" name="toda_id" value="<?php echo htmlspecialchars($todaFilter); ?>">
<?php endif; ?>

                <input type="hidden" name="sort" value="<?php echo htmlspecialchars($sortBy); ?>">
                <input type="hidden" name="order" value="<?php echo htmlspecialchars($sortOrder); ?>">
            </form>
        </div>

        <!-- Ratings Table -->
        <div class="ratings-table-container">
            <div class="table-header">
                <h3>Driver Ratings</h3>
                <div style="display:flex; align-items:center; gap:12px; flex-wrap:wrap;">
                <div class="rating-count">
                    <?php
                    if (isset($_GET['search']) && !empty($_GET['search'])) {
                        echo $ratingsPagination['total_items'] . " drivers found";
                    } else {
                        echo "Showing " . ($ratingsPagination['total_items'] > 0 ? ($ratingsPagination['offset'] + 1) : 0) . "-" . min($ratingsPagination['offset'] + $ratingsPagination['per_page'], $ratingsPagination['total_items']) . " of " . $ratingsPagination['total_items'] . " drivers";
                    }
                    ?>
                </div>
                <?php if (hasPermission(PERM_DRIVERS_MANAGE)): ?>
                <label style="display:flex; align-items:center; gap:8px; font-size:13px; color:#2c3e50;">
                    <input type="checkbox" id="selectAllRatings"> Select All
                </label>
                <button type="button" class="sort-btn" onclick="submitBulkRatingDelete()" style="background:#e74c3c; color:#fff;">
                    <i class="fas fa-trash"></i> Delete Selected
                </button>
                <?php endif; ?>
                </div>
            </div>

            <form id="bulkRatingDeleteForm" method="POST" style="display:none;">
                <input type="hidden" name="action" value="bulk_delete">
                <div id="bulkRatingDeleteInputs"></div>
            </form>

            <div style="overflow-x: auto;">
                <table>
                    <thead>
                        <tr>
                            <?php if (hasPermission(PERM_DRIVERS_MANAGE)): ?>
                            <th style="width: 54px;">
                                <input type="checkbox" id="selectAllRatingsHeader" aria-label="Select all rated drivers">
                            </th>
                            <?php endif; ?>
                            <th onclick="sortBy('name', '<?php echo $sortBy == 'name' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Driver</span>
                                    <i class="fas <?php echo getSortIcon('name', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('toda', '<?php echo $sortBy == 'toda' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>TODA</span>
                                    <i class="fas <?php echo getSortIcon('toda', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('rating', '<?php echo $sortBy == 'rating' && $sortOrder == 'desc' ? 'asc' : 'desc'; ?>')">
                                <div class="sortable-header">
                                    <span>Rating</span>
                                    <i class="fas <?php echo getSortIcon('rating', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('completedTrips', '<?php echo $sortBy == 'completedTrips' && $sortOrder == 'desc' ? 'asc' : 'desc'; ?>')">
                                <div class="sortable-header">
                                    <span>Trips</span>
                                    <i class="fas <?php echo getSortIcon('completedTrips', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('ratingCount', '<?php echo $sortBy == 'ratingCount' && $sortOrder == 'desc' ? 'asc' : 'desc'; ?>')">
                                <div class="sortable-header">
                                    <span>Rating Count</span>
                                    <i class="fas <?php echo getSortIcon('ratingCount', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th>Status</th>
                            <th onclick="sortBy('lastRated', '<?php echo $sortBy == 'lastRated' && $sortOrder == 'desc' ? 'asc' : 'desc'; ?>')">
                                <div class="sortable-header">
                                    <span>Last Rated</span>
                                    <i class="fas <?php echo getSortIcon('lastRated', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php
                        if (!empty($ratingsToDisplay)) {
                            foreach ($ratingsToDisplay as $driverId => $driver) {
                                $firstLetter = strtoupper(substr($driver['name'] ?? '?', 0, 1));
                                $status = $driver['status'] ?? 'pending';
                                $statusClass = 'status-' . $status;
                                $isActive = $driver['isActive'] ?? false;
                                $activeClass = 'active-' . ($isActive ? 'true' : 'false');
                                $lastRated = $driver['lastRated'] ?? null;

                        ?>
                        <tr>
                            <?php if (hasPermission(PERM_DRIVERS_MANAGE)): ?>
                            <td>
                                <input type="checkbox" class="rating-row-select" value="<?php echo htmlspecialchars($driverId); ?>" aria-label="Select driver <?php echo htmlspecialchars($driver['name'] ?? ''); ?>">
                            </td>
                            <?php endif; ?>
                            <td>
                                <div class="driver-info">
                                    <div class="driver-avatar"><?php echo htmlspecialchars($firstLetter); ?></div>
                                    <div class="driver-details">
                                        <div class="driver-name"><?php echo htmlspecialchars($driver['name'] ?? 'Unknown Driver'); ?></div>
                                        <div class="driver-contact">
                                            <span><i class="fas fa-phone"></i> <?php echo htmlspecialchars($driver['phone'] ?? 'N/A'); ?></span>
                                            <span><i class="fas fa-id-card"></i> <?php echo htmlspecialchars($driver['permitNumber'] ?? 'N/A'); ?></span>
                                        </div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div style="font-weight: 600; color: #2c3e50;"><?php echo htmlspecialchars($driver['todaName'] ?? 'Unassigned'); ?></div>
                                <div class="small"><?php echo htmlspecialchars((string)($driver['todaId'] ?? '')); ?></div>
                            </td>
                            <td>
                                <?php echo generateStars($driver['currentRating'] ?? 0); ?>
                                <?php if (!empty($driver['ratingMismatch'])): ?>
                                    <div style="color: #e74c3c; font-size: 11px; margin-top: 3px;">
                                        <i class="fas fa-exclamation-triangle"></i> Mismatch detected
                                    </div>
                                <?php endif; ?>
                            </td>
                            <td>
                                <div style="font-weight: 600; color: #2c3e50;">
                                    <?php echo (int)($driver['completedTrips'] ?? 0); ?> / <?php echo (int)($driver['totalTrips'] ?? 0); ?>
                                </div>
                                <div style="color: #7f8c8d; font-size: 12px;">Completed / Total</div>
                            </td>
                            <td>
                                <div style="font-weight: 600; color: #2c3e50;">
                                    <?php echo (int)($driver['ratingCount'] ?? 0); ?>
                                </div>
                                <?php if ((int)($driver['ratingCount'] ?? 0) > 0): ?>
                                    <div style="color: #7f8c8d; font-size: 12px;">
                                        Sum: <?php echo number_format((float)($driver['totalRating'] ?? 0), 1); ?>
                                    </div>
                                <?php endif; ?>
                            </td>
                            <td>
                                <span class="status-badge <?php echo $statusClass; ?>">
                                    <?php echo ucfirst($status); ?>
                                </span>
                                <div class="active-badge <?php echo $activeClass; ?>">
                                    <?php echo $isActive ? 'Active' : 'Inactive'; ?>
                                </div>
                            </td>
                            <td>
                                <div style="color: #7f8c8d; font-size: 13px;">
                                    <?php echo $lastRated ? formatLastRated($lastRated) : 'Never'; ?>
                                </div>
                                <?php if ($lastRated): ?>
                                    <div style="color: #95a5a6; font-size: 11px;">
                                        <?php echo date('M d, Y', (int)$lastRated); ?>
                                    </div>
                                <?php endif; ?>
                            </td>
                        </tr>
                        <?php
                            }
                        } else {
                            echo '<tr><td colspan="8" class="no-data">
                                <i class="fas fa-star"></i><br>
                                <div style="margin-top: 10px; font-size: 16px;">';

                            if (isset($_GET["search"]) && !empty($_GET["search"])) {
                                echo 'No drivers found for "' . htmlspecialchars($_GET["search"]) . '"';
                            } else {
                                echo 'No drivers with ratings found in the system.';
                            }

                            echo '</div></td></tr>';
                        }
                        ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
    // Auto-hide message box after 5 seconds
    const messageBox = document.getElementById('messageBox');
    if (messageBox) {
        setTimeout(() => {
            messageBox.style.opacity = '0';
            messageBox.style.transition = 'opacity 0.5s';
            setTimeout(() => { messageBox.style.display = 'none'; }, 500);
        }, 5000);
    }

    function toggleSortDropdown() {
        const dropdown = document.getElementById('sortDropdown');
        dropdown.classList.toggle('show');
    }

    function sortBy(column, order) {
        const url = new URL(window.location.href);
        url.searchParams.set('sort', column);
        url.searchParams.set('order', order);
        window.location.href = url.toString();
    }

    document.addEventListener('click', function(event) {
        const dropdown = document.getElementById('sortDropdown');
        const sortBtn = document.querySelector('.sort-btn');

        if (sortBtn && !sortBtn.contains(event.target) && dropdown && !dropdown.contains(event.target)) {
            dropdown.classList.remove('show');
        }
    });

    function syncBulkSelection(masterSelector, rowSelector) {
        const master = document.querySelector(masterSelector);
        const rows = document.querySelectorAll(rowSelector);
        if (!master || !rows.length) return;

        master.addEventListener('change', function() {
            rows.forEach((row) => { row.checked = master.checked; });
        });

        rows.forEach((row) => {
            row.addEventListener('change', function() {
                master.checked = rows.length > 0 && Array.from(rows).every((item) => item.checked);
            });
        });
    }

    function submitBulkRatingDelete() {
        const selected = Array.from(document.querySelectorAll('.rating-row-select:checked')).map((row) => row.value);
        if (!selected.length) {
            alert('Please select at least one driver.');
            return;
        }

        if (!confirm('Delete the selected driver record(s) from the ratings list? This will remove the driver accounts.')) {
            return;
        }

        const container = document.getElementById('bulkRatingDeleteInputs');
        container.innerHTML = '';
        selected.forEach((id) => {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'selected_ids[]';
            input.value = id;
            container.appendChild(input);
        });
        document.getElementById('bulkRatingDeleteForm').submit();
    }

    syncBulkSelection('#selectAllRatings', '.rating-row-select');
    syncBulkSelection('#selectAllRatingsHeader', '.rating-row-select');

    let searchTimeout;
    const searchBox = document.querySelector('.search-box');
    if (searchBox) {
        searchBox.addEventListener('input', function() {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(() => {
                if (this.value.trim()) document.getElementById('searchForm').submit();
            }, 500);
        });

        searchBox.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                document.getElementById('searchForm').submit();
            }
        });
    }
    </script>
    <?php if (($ratingsPagination['total_pages'] ?? 1) > 1): ?>
    <div style="padding:0 25px 25px; margin-left:250px;">
        <div style="display:flex; justify-content:space-between; align-items:center; gap:12px; flex-wrap:wrap; background:#fff; border-radius:12px; padding:14px 18px; box-shadow:0 2px 10px rgba(0,0,0,0.08);">
            <div style="font-size:13px; color:#64748b;">Page <?php echo $ratingsPagination['current_page']; ?> of <?php echo $ratingsPagination['total_pages']; ?></div>
            <div style="display:flex; gap:8px; flex-wrap:wrap;">
                <?php if ($ratingsPagination['has_previous']): ?><a class="action-btn btn-view" href="<?php echo htmlspecialchars(buildQueryUrl(['page' => $ratingsPagination['current_page'] - 1])); ?>">Previous</a><?php endif; ?>
                <?php if ($ratingsPagination['has_next']): ?><a class="action-btn btn-view" href="<?php echo htmlspecialchars(buildQueryUrl(['page' => $ratingsPagination['current_page'] + 1])); ?>">Next</a><?php endif; ?>
            </div>
        </div>
    </div>
    <?php endif; ?>
</body>
</html>
