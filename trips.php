<?php
// trips.php - Trip Management System with Pagination
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_TRIPS_VIEW);


// Handle form submissions
$message = '';
$messageType = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    requirePermission(PERM_TRIPS_MANAGE);
    $tripId = $_POST['trip_id'] ?? '';
    
    if ($_POST['action'] === 'delete' && !empty($tripId)) {
        if (deleteTrip($tripId)) {
            $message = "Trip deleted successfully!";
            $messageType = 'success';
        } else {
            $message = "Failed to delete trip!";
            $messageType = 'error';
        }
    } elseif ($_POST['action'] === 'bulk_delete') {
        $bulkDeleteResult = bulkDeleteRecords($_POST['selected_ids'] ?? [], 'deleteTrip');
        if ($bulkDeleteResult['requested'] === 0) {
            $message = "Please select at least one trip to delete!";
            $messageType = 'error';
        } elseif ($bulkDeleteResult['failed'] === 0) {
            $message = "Deleted " . $bulkDeleteResult['deleted'] . " trip(s) successfully!";
            $messageType = 'success';
        } else {
            $message = "Deleted " . $bulkDeleteResult['deleted'] . " trip(s). Failed to delete " . $bulkDeleteResult['failed'] . " selected record(s).";
            $messageType = $bulkDeleteResult['deleted'] > 0 ? 'success' : 'error';
        }
    } elseif ($_POST['action'] === 'update_status' && !empty($tripId)) {
        $status = $_POST['status'] ?? '';
        $reason = $_POST['reason'] ?? '';
        
        if (updateTripStatus($tripId, $status, $reason)) {
            $message = "Trip status updated successfully!";
            $messageType = 'success';
        } else {
            $message = "Failed to update trip status!";
            $messageType = 'error';
        }
    }
}

// Get statistics
$stats = getTripStatistics();
$selectedTodaId = null;
$registeredDriverCount = getRegisteredDriverCount();

[$todaByDriverId, $todaByPhone] = buildDriverTodaIndex();

// Get search parameters
$searchTerm = $_GET['search'] ?? '';
$sortBy = $_GET['sort'] ?? 'time';
$sortOrder = $_GET['order'] ?? 'desc';
$page = isset($_GET['page']) ? intval($_GET['page']) : 1;
$perPage = 20;

// Trip filters were removed from the UI. Only role-based TODA scoping still applies.
$filters = [];
if (isset($_GET['toda_id']) && $_GET['toda_id'] !== '' && (isSuperAdmin() || currentAdminRole() === ROLE_BPLO_VERIFIER)) {
    $filters['toda_id'] = $_GET['toda_id'];
}

// Enforce TODA scope for TODA accounts
if (!isSuperAdmin() && currentAdminRole() !== ROLE_BPLO_VERIFIER) {
    $myToda = currentAdminTodaId();
    if (!empty($myToda)) {
        $filters['toda_id'] = $myToda;
    }
}

// Get paginated trips
$paginationResult = getTripsPaginated($page, $perPage, $searchTerm, $sortBy, $sortOrder, $filters);
$tripsToDisplay = $paginationResult['trips'];
$pagination = $paginationResult['pagination'];

$selectedTodaId = $filters['toda_id'] ?? null;
$stats = getTripStatisticsForToda($selectedTodaId);
$registeredDriverCount = getRegisteredDriverCount($selectedTodaId);

// Function to get sort icon
function getSortIcon($column, $currentSort, $currentOrder) {
    if ($currentSort === $column) {
        if ($currentOrder === 'asc') {
            return 'fa-sort-up';
        } else {
            return 'fa-sort-down';
        }
    }
    return 'fa-sort';
}

// Function to build URL with parameters
function buildUrl($params = []) {
    $currentParams = $_GET;
    foreach (['start_date', 'end_date', 'status_filter', 'min_fare', 'max_fare'] as $removedParam) {
        unset($currentParams[$removedParam]);
    }
    $mergedParams = array_merge($currentParams, $params);

    if (isset($mergedParams['page']) && $mergedParams['page'] == 1) {
        unset($mergedParams['page']);
    }

    return 'trips.php' . (count($mergedParams) ? '?' . http_build_query($mergedParams) : '');
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trips - Kaltrike Admin</title>
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
        
        /* Top Controls */
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
        
        .control-buttons {
            display: flex;
            gap: 15px;
            align-items: center;
        }
        
        /* Sort Dropdown */
        .sort-container {
            position: relative;
        }
        
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
        
        .sort-btn:hover {
            border-color: #3498db;
            background: #f8f9fa;
        }
        
        .sort-dropdown {
            display: none;
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            border: 2px solid #ddd;
            border-radius: 6px;
            margin-top: 5px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            z-index: 100;
        }
        
        .sort-dropdown.show {
            display: block;
        }
        
        .sort-option {
            padding: 10px 15px;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 10px;
            transition: all 0.2s;
        }
        
        .sort-option:hover {
            background: #f8f9fa;
        }
        
        .sort-option.active {
            background: #e8f4fc;
            color: #3498db;
            font-weight: 600;
        }
        
        .sort-option i {
            width: 16px;
            text-align: center;
        }
        
        /* Search Box */
        .search-container {
            margin-bottom: 25px;
            position: relative;
        }
        
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
        
        .search-controls {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .clear-search {
            color: #e74c3c;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 5px;
            transition: all 0.3s;
        }
        
        .clear-search:hover {
            color: #c0392b;
            text-decoration: underline;
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
        .stat-card:nth-child(3) { border-top-color: #f39c12; }
        .stat-card:nth-child(4) { border-top-color: #9b59b6; }
        .stat-card:nth-child(5) { border-top-color: #1abc9c; }
        .stat-card:nth-child(6) { border-top-color: #e74c3c; }
        
        .stat-icon {
            font-size: 30px;
            margin-bottom: 15px;
            opacity: 0.8;
        }
        
        .stat-card:nth-child(1) .stat-icon { color: #3498db; }
        .stat-card:nth-child(2) .stat-icon { color: #27ae60; }
        .stat-card:nth-child(3) .stat-icon { color: #f39c12; }
        .stat-card:nth-child(4) .stat-icon { color: #9b59b6; }
        .stat-card:nth-child(5) .stat-icon { color: #1abc9c; }
        .stat-card:nth-child(6) .stat-icon { color: #e74c3c; }
        
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
        
        /* Trips Table */
        .trips-table-container {
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
        
        .table-header h3 {
            color: #2c3e50;
            font-size: 18px;
            font-weight: 600;
        }
        
        .trip-count {
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
            cursor: pointer;
            user-select: none;
        }
        
        th:hover {
            background-color: #eef2f7;
        }
        
        .sortable-header {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .sort-icon {
            color: #7f8c8d;
            font-size: 12px;
        }
        
        td {
            padding: 15px;
            border-bottom: 1px solid #eee;
            vertical-align: middle;
        }
        
        tr:hover {
            background-color: #f9f9f9;
        }
        
        /* Trip Info */
        .trip-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .trip-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 16px;
            flex-shrink: 0;
        }
        
        .trip-details {
            display: flex;
            flex-direction: column;
        }
        
        .trip-passenger {
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 3px;
        }
        
        .trip-id {
            color: #7f8c8d;
            font-size: 12px;
        }
        
        /* Status Badges */
        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }
        
        .status-completed {
            background-color: #d5f4e6;
            color: #27ae60;
        }
        
        .status-pending {
            background-color: #fff3cd;
            color: #856404;
        }
        
        .status-active {
            background-color: #d1ecf1;
            color: #0c5460;
        }
        
        .status-cancelled {
            background-color: #f8d7da;
            color: #721c24;
        }
        
        .status-unknown {
            background-color: #e2e3e5;
            color: #383d41;
        }
        
        /* Fare Badge */
        .fare-badge {
            background: linear-gradient(135deg, #27ae60 0%, #219653 100%);
            color: white;
            padding: 6px 12px;
            border-radius: 6px;
            font-weight: 600;
            font-size: 13px;
            display: inline-block;
        }
        
        /* Action Buttons */
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        
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
        
        .action-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 3px 8px rgba(0,0,0,0.1);
        }
        
        .btn-view:hover {
            background-color: #3498db;
            color: white;
            border-color: #3498db;
        }
        
        .btn-edit:hover {
            background-color: #f39c12;
            color: white;
            border-color: #f39c12;
        }
        
        .btn-delete:hover {
            background-color: #e74c3c;
            color: white;
            border-color: #e74c3c;
        }
        
        /* Pagination */
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            gap: 8px;
            flex-wrap: wrap;
        }
        
        .pagination-item {
            padding: 8px 12px;
            border-radius: 6px;
            text-decoration: none;
            color: #2c3e50;
            font-weight: 600;
            background: #f8f9fa;
            border: 1px solid #ddd;
            transition: all 0.3s;
            font-size: 14px;
            min-width: 36px;
            text-align: center;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .pagination-item:hover {
            background: #3498db;
            color: white;
            border-color: #3498db;
        }
        
        .pagination-item.active {
            background: #3498db;
            color: white;
            border-color: #3498db;
        }
        
        .pagination-item.disabled {
            opacity: 0.5;
            cursor: not-allowed;
            background: #f8f9fa;
            color: #2c3e50;
            border-color: #ddd;
        }
        
        .pagination-item.disabled:hover {
            background: #f8f9fa;
            color: #2c3e50;
            border-color: #ddd;
            transform: none;
            box-shadow: none;
        }
        
        .pagination-info {
            color: #7f8c8d;
            font-size: 14px;
            margin-right: 15px;
            font-weight: 600;
        }
        
        .no-data {
            text-align: center;
            padding: 60px 20px;
            color: #7f8c8d;
        }
        
        .no-data i {
            font-size: 48px;
            margin-bottom: 15px;
            color: #bdc3c7;
        }
        
        /* Message Box */
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
            from {
                transform: translateX(100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
        
        .message-success {
            background: linear-gradient(135deg, #27ae60 0%, #219653 100%);
            border-left: 4px solid #1e874b;
        }
        
        .message-error {
            background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
            border-left: 4px solid #a93226;
        }
        
        /* Filter Section */
        .filter-section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            display: none;
        }
        
        .filter-section.active {
            display: block;
            animation: slideDown 0.3s;
        }
        
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .filter-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        
        .filter-title {
            font-size: 18px;
            font-weight: 600;
            color: #2c3e50;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .filter-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        
        .filter-label {
            color: #2c3e50;
            font-weight: 600;
            font-size: 14px;
        }
        
        .filter-input {
            padding: 10px 15px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .filter-input:focus {
            border-color: #3498db;
            outline: none;
            box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
        }
        
        .filter-actions {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
        
        .btn-filter {
            padding: 10px 20px;
            border-radius: 6px;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: all 0.3s;
            border: none;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-apply {
            background: #3498db;
            color: white;
        }
        
        .btn-apply:hover {
            background: #2980b9;
        }
        
        .btn-reset {
            background: #95a5a6;
            color: white;
        }
        
        .btn-reset:hover {
            background: #7f8c8d;
        }
        
        .toggle-filter {
            background: #f39c12;
            color: white;
            padding: 9px 15px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
            border: none;
        }
        
        .toggle-filter:hover {
            background: #d68910;
            transform: translateY(-2px);
        }
        
        .close-modal {
            background: none;
            border: none;
            color: #7f8c8d;
            font-size: 20px;
            cursor: pointer;
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            transition: all 0.3s;
        }
        
        .close-modal:hover {
            background: #f8f9fa;
            color: #e74c3c;
        }
        
        /* Modal */
        .modal {
            display: none;
            position: fixed;
            z-index: 3000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
            animation: fadeIn 0.3s;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .modal-content {
            background-color: white;
            margin: 5% auto;
            padding: 0;
            width: 90%;
            max-width: 500px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            animation: slideUp 0.3s;
        }
        
        @keyframes slideUp {
            from {
                transform: translateY(50px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }
        
        .modal-header {
            padding: 20px;
            border-bottom: 1px solid #eee;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h3 {
            color: #2c3e50;
            font-size: 20px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .modal-body {
            padding: 20px;
        }
        
        /* Responsive Design */
        @media (max-width: 1024px) {
            .stats-grid {
                grid-template-columns: repeat(3, 1fr);
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
                grid-template-columns: repeat(2, 1fr);
            }
            
            .top-controls {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .control-buttons {
                width: 100%;
                justify-content: space-between;
            }
            
            table {
                display: block;
                overflow-x: auto;
            }
            
            .action-buttons {
                flex-direction: column;
                gap: 5px;
            }
            
            .action-btn {
                width: 100%;
                justify-content: center;
            }
        }
        
        @media (max-width: 480px) {
            .header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .stats-grid {
                grid-template-columns: 1fr;
            }
            
            .control-buttons {
                flex-direction: column;
                gap: 10px;
            }
            
            .sort-btn {
                width: 100%;
            }
            
            .pagination {
                gap: 5px;
            }
            
            .pagination-item {
                padding: 6px 8px;
                font-size: 12px;
                min-width: 32px;
            }
            
            .pagination-info {
                width: 100%;
                text-align: center;
                margin-right: 0;
                margin-bottom: 10px;
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
            <h1><i class="fas fa-car"></i> Trip Management</h1>
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
                <h2>Trip List <span>(<?php echo $stats['totalTrips']; ?> total trips • <?php echo $registeredDriverCount; ?> registered drivers<?php echo $selectedTodaId ? ' in ' . htmlspecialchars(getTodaName($selectedTodaId)) : ''; ?>)</span></h2>
            </div>
            <div class="control-buttons">
                <div class="sort-container">
                    <button class="sort-btn" onclick="toggleSortDropdown()">
                        <span><i class="fas fa-sort-amount-down"></i> Sort</span>
                        <i class="fas fa-chevron-down"></i>
                    </button>
                    <div class="sort-dropdown" id="sortDropdown">
                        <div class="sort-option <?php echo $sortBy == 'time' && $sortOrder == 'desc' ? 'active' : ''; ?>" 
                             onclick="sortBy('time', 'desc')">
                            <i class="fas fa-calendar"></i>
                            <span>Newest First</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'time' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('time', 'asc')">
                            <i class="fas fa-calendar"></i>
                            <span>Oldest First</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'passenger' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('passenger', 'asc')">
                            <i class="fas fa-user"></i>
                            <span>Passenger (A-Z)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'passenger' && $sortOrder == 'desc' ? 'active' : ''; ?>" 
                             onclick="sortBy('passenger', 'desc')">
                            <i class="fas fa-user"></i>
                            <span>Passenger (Z-A)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'driver' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('driver', 'asc')">
                            <i class="fas fa-users"></i>
                            <span>Driver (A-Z)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'driver' && $sortOrder == 'desc' ? 'active' : ''; ?>" 
                             onclick="sortBy('driver', 'desc')">
                            <i class="fas fa-users"></i>
                            <span>Driver (Z-A)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'fare' && $sortOrder == 'desc' ? 'active' : ''; ?>" 
                             onclick="sortBy('fare', 'desc')">
                            <i class="fas fa-money-bill-wave"></i>
                            <span>Highest Fare</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'fare' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('fare', 'asc')">
                            <i class="fas fa-money-bill-wave"></i>
                            <span>Lowest Fare</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'status' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('status', 'asc')">
                            <i class="fas fa-sort"></i>
                            <span>Status (A-Z)</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Statistics Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-car"></i>
                </div>
                <div class="stat-number"><?php echo $stats['totalTrips']; ?></div>
                <div class="stat-label">Total Trips</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-id-card"></i>
                </div>
                <div class="stat-number"><?php echo $registeredDriverCount; ?></div>
                <div class="stat-label">Registered Drivers</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-check-circle"></i>
                </div>
                <div class="stat-number"><?php echo $stats['completedTrips']; ?></div>
                <div class="stat-label">Completed</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-clock"></i>
                </div>
                <div class="stat-number"><?php echo $stats['activeTrips'] + $stats['pendingTrips']; ?></div>
                <div class="stat-label">Active/Pending</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-money-bill-wave"></i>
                </div>
                <div class="stat-number">₱<?php echo number_format($stats['totalRevenue'], 2); ?></div>
                <div class="stat-label">Total Revenue</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-users"></i>
                </div>
                <div class="stat-number"><?php echo $stats['ridesharingTrips']; ?></div>
                <div class="stat-label">Ridesharing</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-calendar-day"></i>
                </div>
                <div class="stat-number"><?php echo $stats['todaysTrips'] ?? 0; ?></div>
                <div class="stat-label">Today's Trips</div>
            </div>
        </div>
        
        <!-- Search Box -->
        <div class="search-container">
            <div class="search-controls">
                <form method="GET" action="" id="searchForm" style="flex: 1;">
                    <i class="fas fa-search search-icon"></i>
                    <input type="text" name="search" class="search-box" 
                           placeholder="Search trips by passenger, driver, phone, address, or trip ID..."
                           value="<?php echo htmlspecialchars($searchTerm); ?>">
                    <input type="hidden" name="sort" value="<?php echo htmlspecialchars($sortBy); ?>">
                    <input type="hidden" name="order" value="<?php echo htmlspecialchars($sortOrder); ?>">
                    <input type="hidden" name="page" value="1">
                </form>
                <?php if ($searchTerm): ?>
                <a href="<?php echo buildUrl(['search' => '', 'page' => 1]); ?>" class="clear-search">
                    <i class="fas fa-times"></i> Clear Search
                </a>
                <?php endif; ?>
            </div>
        </div>
        
        <!-- Trips Table -->
        <div class="trips-table-container">
            <div class="table-header">
                <h3>All Trips</h3>
                <div style="display:flex; align-items:center; gap:12px; flex-wrap:wrap;">
                <div class="trip-count">
                    <?php 
                    if ($searchTerm) {
                        echo "Found " . $pagination['total_items'] . " trip" . ($pagination['total_items'] != 1 ? 's' : '') . 
                             " for \"" . htmlspecialchars($searchTerm) . "\"";
                    } else {
                        echo "Showing " . min($pagination['per_page'], $pagination['total_items'] - $pagination['offset']) . 
                             " of " . $pagination['total_items'] . " trips";
                    }
                    ?>
                </div>
                <?php if (hasPermission(PERM_TRIPS_MANAGE)): ?>
                <label style="display:flex; align-items:center; gap:8px; font-size:13px; color:#2c3e50;">
                    <input type="checkbox" id="selectAllTrips"> Select All
                </label>
                <button type="button" class="action-btn btn-delete" onclick="submitBulkTripDelete()">
                    <i class="fas fa-trash"></i> Delete Selected
                </button>
                <?php endif; ?>
                </div>
            </div>

            <form id="bulkTripDeleteForm" method="POST" style="display:none;">
                <input type="hidden" name="action" value="bulk_delete">
                <div id="bulkTripDeleteInputs"></div>
            </form>
            
            <div style="overflow-x: auto;">
                <table>
                    <thead>
                        <tr>
                            <?php if (hasPermission(PERM_TRIPS_MANAGE)): ?>
                            <th style="width:54px;">
                                <input type="checkbox" id="selectAllTripsHeader" aria-label="Select all trips">
                            </th>
                            <?php endif; ?>
                            <th onclick="sortBy('passenger', '<?php echo $sortBy == 'passenger' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Passenger</span>
                                    <i class="fas <?php echo getSortIcon('passenger', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('driver', '<?php echo $sortBy == 'driver' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Driver</span>
                                    <i class="fas <?php echo getSortIcon('driver', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('toda', '<?php echo $sortBy == 'toda' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>TODA</span>
                                    <i class="fas <?php echo getSortIcon('toda', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th>Pickup Location</th>
                            <th>Destination</th>
                            <th onclick="sortBy('time', '<?php echo $sortBy == 'time' && $sortOrder == 'desc' ? 'asc' : 'desc'; ?>')">
                                <div class="sortable-header">
                                    <span>Time</span>
                                    <i class="fas <?php echo getSortIcon('time', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th>Fare</th>
                            <th onclick="sortBy('status', '<?php echo $sortBy == 'status' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Status</span>
                                    <i class="fas <?php echo getSortIcon('status', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php
                        if (!empty($tripsToDisplay)) {
                            foreach ($tripsToDisplay as $tripId => $trip) {
                                $tripData = formatTripData($trip, $tripId);

                                // Basic safe values
                                $passengerName  = $tripData['passengerName'] ?? 'Unknown Passenger';
                                $passengerPhone = $tripData['passengerPhone'] ?? 'N/A';
                                $driverName     = $tripData['driverName'] ?? 'Unknown Driver';
                                $driverPhone    = $tripData['driverPhone'] ?? 'N/A';
                                $tripTodaId = getTripTodaId($trip, $todaByDriverId, $todaByPhone);
                                $tripTodaName = getTodaName($tripTodaId);
                                $originAddress  = $tripData['originAddress'] ?? 'N/A';
                                $destAddress    = $tripData['destinationAddress'] ?? 'N/A';
                                $formattedTime  = $tripData['formattedTime'] ?? '';

                                $firstLetter = strtoupper(substr($passengerName, 0, 1));

                                // 🔹 SAFE passengerCount default
                                $passengerCountRaw = $tripData['passengerCount'] 
                                    ?? ($trip['passengerCount'] ?? $trip['pax'] ?? 1);
                                $passengerCount = is_numeric($passengerCountRaw) ? (int)$passengerCountRaw : 1;

                                // 🔹 SAFE rideSharing default
                                $rideSharingRaw = $tripData['rideSharing'] 
                                    ?? ($trip['rideSharing'] ?? $trip['isRideshare'] ?? 'No');
                                $rideSharingStr = strtolower(trim((string)$rideSharingRaw));
                                if (in_array($rideSharingStr, ['yes', 'true', '1', 'enabled'])) {
                                    $rideSharing = 'Yes';
                                } else {
                                    $rideSharing = 'No';
                                }

                                // 🔹 Status class & text for badges
                                $statusRaw = strtolower($tripData['status'] ?? ($trip['status'] ?? 'unknown'));
                                $statusText = $tripData['statusText'] ?? ucfirst($statusRaw);
                                $statusClass = 'status-unknown';

                                switch ($statusRaw) {
                                    case 'ended':
                                    case 'completed':
                                    case 'finished':
                                        $statusClass = 'status-completed';
                                        $statusText = 'Completed';
                                        break;
                                    case 'pending':
                                    case 'requested':
                                    case 'waiting':
                                        $statusClass = 'status-pending';
                                        $statusText = 'Pending';
                                        break;
                                    case 'accepted':
                                    case 'ongoing':
                                    case 'active':
                                    case 'started':
                                        $statusClass = 'status-active';
                                        $statusText = 'Active';
                                        break;
                                    case 'cancelled':
                                    case 'canceled':
                                    case 'rejected':
                                        $statusClass = 'status-cancelled';
                                        $statusText = 'Cancelled';
                                        break;
                                    default:
                                        $statusClass = 'status-unknown';
                                        if ($statusText === '') {
                                            $statusText = 'Unknown';
                                        }
                                }
                        ?>
                        <tr>
                            <?php if (hasPermission(PERM_TRIPS_MANAGE)): ?>
                            <td>
                                <input type="checkbox" class="trip-row-select" value="<?php echo htmlspecialchars($tripId); ?>" aria-label="Select trip <?php echo htmlspecialchars($tripId); ?>">
                            </td>
                            <?php endif; ?>
                            <td>
                                <div class="trip-info">
                                    <div class="trip-avatar"><?php echo htmlspecialchars($firstLetter); ?></div>
                                    <div class="trip-details">
                                        <div class="trip-passenger"><?php echo htmlspecialchars($passengerName); ?></div>
                                        <div class="trip-id"><?php echo htmlspecialchars($passengerPhone); ?></div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div style="font-weight: 600; color: #2c3e50;"><?php echo htmlspecialchars($driverName); ?></div>
                                <div style="color: #7f8c8d; font-size: 13px;"><?php echo htmlspecialchars($driverPhone); ?></div>
                            </td>
                            <td>
                                <div style="font-weight: 600; color: #2c3e50;">
                                    <?php echo htmlspecialchars($tripTodaName); ?>
                                </div>
                                <div style="color: #95a5a6; font-size: 12px;"><?php echo htmlspecialchars((string)($tripTodaId ?? '')); ?></div>
                            </td>
                            <td>
                                <div style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" 
                                     title="<?php echo htmlspecialchars($originAddress); ?>">
                                    <?php echo htmlspecialchars($originAddress); ?>
                                </div>
                            </td>
                            <td>
                                <div style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;"
                                     title="<?php echo htmlspecialchars($destAddress); ?>">
                                    <?php echo htmlspecialchars($destAddress); ?>
                                </div>
                            </td>
                            <td>
                                <div style="color: #7f8c8d; font-size: 13px;">
                                    <?php echo htmlspecialchars((string)$formattedTime); ?>
                                </div>
                                <div style="color: #95a5a6; font-size: 12px; margin-top: 3px;">
                                    <i class="fas fa-users"></i>
                                    <?php echo htmlspecialchars((string)$passengerCount); ?> pax
                                    <?php if ($rideSharing === 'Yes'): ?>
                                    <span style="background: #e8f4fc; color: #3498db; padding: 2px 6px; border-radius: 3px; font-size: 10px; margin-left: 5px;">
                                        Rideshare
                                    </span>
                                    <?php endif; ?>
                                </div>
                            </td>
                            <td>
                                <div class="fare-badge"><?php echo htmlspecialchars($tripData['fare'] ?? '₱0.00'); ?></div>
                            </td>
                            <td>
                                <span class="status-badge <?php echo htmlspecialchars($statusClass); ?>">
                                    <?php echo htmlspecialchars($statusText); ?>
                                </span>
                            </td>
                            <td>
                                <div class="action-buttons">
                                    <button class="action-btn btn-view" onclick="viewTripDetails(<?php echo htmlspecialchars(json_encode($tripId), ENT_QUOTES, 'UTF-8'); ?>)">
                                        <i class="fas fa-eye"></i> View
                                    </button>
                                    <?php if (hasPermission(PERM_TRIPS_MANAGE)): ?>
                                    <button class="action-btn btn-edit" onclick="updateTripStatus(<?php echo htmlspecialchars(json_encode($tripId), ENT_QUOTES, 'UTF-8'); ?>, '<?php echo $statusRaw; ?>')">
                                        <i class="fas fa-edit"></i> Status
                                    </button>
                                    <button class="action-btn btn-delete" onclick="deleteTrip(<?php echo htmlspecialchars(json_encode($tripId), ENT_QUOTES, 'UTF-8'); ?>)">
                                        <i class="fas fa-trash"></i> Delete
                                    </button>
                                    <?php endif; ?>
                                </div>
                            </td>
                        </tr>
                        <?php 
                            }
                        } else {
                            echo '<tr><td colspan="9" class="no-data">
                                <i class="fas fa-car"></i><br>
                                <div style="margin-top: 10px; font-size: 16px;">';
                            
                            if ($searchTerm) {
                                echo 'No trips found for "' . htmlspecialchars($searchTerm) . '"';
                            } else {
                                echo 'No trips found in the system.';
                            }
                            
                            echo '</div></td></tr>';
                        }
                        ?>
                    </tbody>
                </table>
            </div>
            
            <!-- Pagination -->
            <?php if ($pagination['total_pages'] > 1): ?>
            <div class="pagination">
                <span class="pagination-info">
                    Page <?php echo $pagination['current_page']; ?> of <?php echo $pagination['total_pages']; ?>
                </span>
                
                <?php if ($pagination['has_previous']): ?>
                <a href="<?php echo buildUrl(['page' => 1]); ?>" class="pagination-item" title="First Page">
                    <i class="fas fa-angle-double-left"></i>
                </a>
                <a href="<?php echo buildUrl(['page' => $pagination['current_page'] - 1]); ?>" class="pagination-item" title="Previous Page">
                    <i class="fas fa-angle-left"></i>
                </a>
                <?php else: ?>
                <span class="pagination-item disabled">
                    <i class="fas fa-angle-double-left"></i>
                </span>
                <span class="pagination-item disabled">
                    <i class="fas fa-angle-left"></i>
                </span>
                <?php endif; ?>
                
                <?php
                // Show page numbers
                $startPage = max(1, $pagination['current_page'] - 2);
                $endPage = min($pagination['total_pages'], $pagination['current_page'] + 2);
                
                for ($i = $startPage; $i <= $endPage; $i++):
                ?>
                <a href="<?php echo buildUrl(['page' => $i]); ?>" 
                   class="pagination-item <?php echo $i == $pagination['current_page'] ? 'active' : ''; ?>">
                    <?php echo $i; ?>
                </a>
                <?php endfor; ?>
                
                <?php if ($pagination['has_next']): ?>
                <a href="<?php echo buildUrl(['page' => $pagination['current_page'] + 1]); ?>" class="pagination-item" title="Next Page">
                    <i class="fas fa-angle-right"></i>
                </a>
                <a href="<?php echo buildUrl(['page' => $pagination['total_pages']]); ?>" class="pagination-item" title="Last Page">
                    <i class="fas fa-angle-double-right"></i>
                </a>
                <?php else: ?>
                <span class="pagination-item disabled">
                    <i class="fas fa-angle-right"></i>
                </span>
                <span class="pagination-item disabled">
                    <i class="fas fa-angle-double-right"></i>
                </span>
                <?php endif; ?>
            </div>
            <?php endif; ?>
        </div>
    </div>
    
    <?php if (hasPermission(PERM_TRIPS_MANAGE)): ?>
    <!-- Update Status Modal -->
    <div id="updateStatusModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class="fas fa-edit"></i> Update Trip Status</h3>
                <button class="close-modal" onclick="closeModal()">&times;</button>
            </div>
            <div class="modal-body">
                <form id="updateStatusForm" method="POST" action="">
                    <input type="hidden" name="action" value="update_status">
                    <input type="hidden" id="modalTripId" name="trip_id" value="">
                    
                    <div style="margin-bottom: 20px;">
                        <label for="status"><i class="fas fa-tag"></i> New Status</label>
                        <select id="status" name="status" required style="width: 100%; padding: 10px; border: 2px solid #ddd; border-radius: 6px; font-size: 14px;">
                            <option value="pending">Pending</option>
                            <option value="requested">Requested</option>
                            <option value="accepted">Accepted</option>
                            <option value="ongoing">Ongoing</option>
                            <option value="completed">Completed</option>
                            <option value="ended">Ended</option>
                            <option value="cancelled">Cancelled</option>
                        </select>
                    </div>
                    
                    <div style="margin-bottom: 20px;">
                        <label for="reason"><i class="fas fa-comment"></i> Reason (Optional)</label>
                        <textarea id="reason" name="reason" rows="3" 
                                  placeholder="Enter reason for status change..."
                                  style="width: 100%; padding: 10px; border: 2px solid #ddd; border-radius: 6px; font-size: 14px;"></textarea>
                    </div>
                    
                    <div class="form-actions" style="display: flex; justify-content: flex-end; gap: 10px; margin-top: 20px;">
                        <button type="button" class="action-btn" onclick="closeModal()" style="background: #95a5a6; color: white;">
                            Cancel
                        </button>
                        <button type="submit" class="action-btn" style="background: #3498db; color: white;">
                            <i class="fas fa-save"></i> Update Status
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <?php endif; ?>

    <script>
    // Auto-hide message box after 5 seconds
    const messageBox = document.getElementById('messageBox');
    if (messageBox) {
        setTimeout(() => {
            messageBox.style.opacity = '0';
            messageBox.style.transition = 'opacity 0.5s';
            setTimeout(() => {
                messageBox.style.display = 'none';
            }, 500);
        }, 5000);
    }
    
    // Sorting Functions
    function toggleSortDropdown() {
        const dropdown = document.getElementById('sortDropdown');
        dropdown.classList.toggle('show');
    }
    
    function sortBy(column, order) {
        window.location.href = '<?php echo buildUrl(['page' => 1]); ?>' + 
            (window.location.search ? '&' : '?') + 
            'sort=' + column + '&order=' + order;
    }
    
    // Close dropdown when clicking outside
    document.addEventListener('click', function(event) {
        const dropdown = document.getElementById('sortDropdown');
        const sortBtn = document.querySelector('.sort-btn');
        
        if (sortBtn && !sortBtn.contains(event.target) && dropdown && !dropdown.contains(event.target)) {
            dropdown.classList.remove('show');
        }
    });
    
    // Trip Actions
    function viewTripDetails(tripId) {
        window.location.href = 'trip_details.php?id=' + encodeURIComponent(tripId);
    }
    
    <?php if (hasPermission(PERM_TRIPS_MANAGE)): ?>
    function updateTripStatus(tripId, currentStatus) {
        const modal = document.getElementById('updateStatusModal');
        const tripIdInput = document.getElementById('modalTripId');
        const statusSelect = document.getElementById('status');
        
        tripIdInput.value = tripId;
        statusSelect.value = currentStatus || 'pending';
        
        modal.style.display = 'block';
    }
    
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

    function submitBulkTripDelete() {
        const selected = Array.from(document.querySelectorAll('.trip-row-select:checked')).map((row) => row.value);
        if (!selected.length) {
            alert('Please select at least one trip.');
            return;
        }

        if (!confirm('Delete the selected trip record(s)? This action cannot be undone.')) {
            return;
        }

        const container = document.getElementById('bulkTripDeleteInputs');
        container.innerHTML = '';
        selected.forEach((id) => {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'selected_ids[]';
            input.value = id;
            container.appendChild(input);
        });
        document.getElementById('bulkTripDeleteForm').submit();
    }

    syncBulkSelection('#selectAllTrips', '.trip-row-select');
    syncBulkSelection('#selectAllTripsHeader', '.trip-row-select');

    function deleteTrip(tripId) {
        if (confirm('⚠️ WARNING: Are you sure you want to delete this trip?\n\nThis action cannot be undone and will permanently remove all trip data.')) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '';
            
            const actionInput = document.createElement('input');
            actionInput.type = 'hidden';
            actionInput.name = 'action';
            actionInput.value = 'delete';
            form.appendChild(actionInput);
            
            const idInput = document.createElement('input');
            idInput.type = 'hidden';
            idInput.name = 'trip_id';
            idInput.value = tripId;
            form.appendChild(idInput);
            
            document.body.appendChild(form);
            form.submit();
        }
    }
    
    // Modal Functions
    function closeModal() {
        document.getElementById('updateStatusModal').style.display = 'none';
    }
    
    // Close modal when clicking outside
    <?php endif; ?>

    window.onclick = function(event) {
        const modal = document.getElementById('updateStatusModal');
        if (event.target == modal) {
            closeModal();
        }
    }
    
    // Close modal with Escape key
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeModal();
        }
    });
    
    // Search box auto-submit with slight delay
    let searchTimeout;
    const searchBox = document.querySelector('.search-box');
    if (searchBox) {
        searchBox.addEventListener('input', function() {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(() => {
                if (this.value.trim()) {
                    document.getElementById('searchForm').submit();
                }
            }, 500);
        });
        
        // Handle Enter key in search
        searchBox.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                document.getElementById('searchForm').submit();
            }
        });
    }
    
    </script>
</body>
</html>
