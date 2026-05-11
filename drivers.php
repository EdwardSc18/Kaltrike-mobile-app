<?php
// drivers.php - Driver Management System
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_DRIVERS_VIEW);

$forceTodaDriverView = defined('FORCE_TODA_DRIVER_VIEW') && FORCE_TODA_DRIVER_VIEW === true;
if (isTodaScopedAdmin() && !$forceTodaDriverView && basename($_SERVER['PHP_SELF']) === 'drivers.php') {
    $query = $_SERVER['QUERY_STRING'] ?? '';
    $target = getDriversRouteForCurrentUser();
    if ($query !== '') {
        $target .= '?' . $query;
    }
    header('Location: ' . $target);
    exit();
}

if ($forceTodaDriverView && !isTodaScopedAdmin()) {
    header('Location: drivers.php');
    exit();
}

$pageTitle = $forceTodaDriverView ? 'Assigned Drivers' : 'Drivers Management';

// Get all drivers
$drivers = getAllDrivers();
$stats = getDriverStatistics();
$selectedTodaId = null;
$registeredDriverCount = 0;

// TODA list
$todas = getAllTodas();

// Handle form submissions
$message = '';
$messageType = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        requirePermission(PERM_DRIVERS_MANAGE);
        $driverId = $_POST['driver_id'] ?? '';
        
        switch ($_POST['action']) {
            case 'validate':
                if (validateDriver($driverId)) {
                    $message = "Driver validated successfully!";
                    $messageType = 'success';
                } else {
                    $message = "Failed to validate driver!";
                    $messageType = 'error';
                }
                break;
                
            case 'delete':
                if (deleteDriver($driverId)) {
                    $message = "Driver deleted successfully!";
                    $messageType = 'success';
                } else {
                    $message = "Failed to delete driver!";
                    $messageType = 'error';
                }
                break;

            case 'bulk_delete':
                $bulkDeleteResult = bulkDeleteRecords($_POST['selected_ids'] ?? [], 'deleteDriver');
                if ($bulkDeleteResult['requested'] === 0) {
                    $message = "Please select at least one driver to delete!";
                    $messageType = 'error';
                } elseif ($bulkDeleteResult['failed'] === 0) {
                    $message = "Deleted " . $bulkDeleteResult['deleted'] . " driver(s) successfully!";
                    $messageType = 'success';
                } else {
                    $message = "Deleted " . $bulkDeleteResult['deleted'] . " driver(s). Failed to delete " . $bulkDeleteResult['failed'] . " selected record(s).";
                    $messageType = $bulkDeleteResult['deleted'] > 0 ? 'success' : 'error';
                }
                break;
                
            case 'assign_toda':
                $newTodaId = $_POST['toda_id'] ?? '';
                if (!isSuperAdmin()) {
                    $newTodaId = currentAdminTodaId();
                }
                if (empty($newTodaId)) {
                    $message = "Missing TODA assignment.";
                    $messageType = 'error';
                    break;
                }
                // TODA admins/staff can only assign to their own TODA
                if (!isSuperAdmin() && currentAdminRole() !== ROLE_BPLO_VERIFIER) {
                    requireTodaAccess($newTodaId);
                }
                $update = [
                    'todaId' => $newTodaId,
                    'todaAssignedAt' => (int)(microtime(true) * 1000),
                    'todaAssignedBy' => $_SESSION['admin_username'] ?? ''
                ];
                if (firebaseUpdate('drivers/' . $driverId, $update)) {
                    auditLog('ASSIGN_DRIVER_TODA', 'driver', $driverId, $update);
                    $message = "Driver TODA assigned successfully!";
                    $messageType = 'success';
                } else {
                    $message = "Failed to assign TODA!";
                    $messageType = 'error';
                }
                break;

            case 'add':
                $driverData = [
                    'name' => $_POST['fullName'] ?? '',
                    'email' => $_POST['email'] ?? '',
                    'phone' => $_POST['phone'] ?? '',
                    'permitNumber' => $_POST['permitNumber'] ?? '',
                    'vehiclePlate' => $_POST['vehiclePlate'] ?? '',
                    'status' => $_POST['status'] ?? 'pending',
                    'password' => $_POST['password'] ?? 'password123'
                ];
                
                if (addDriver($driverData)) {
                    $message = "Driver added successfully!";
                    $messageType = 'success';
                } else {
                    $message = "Failed to add driver!";
                    $messageType = 'error';
                }
                break;
        }
        
        // Refresh data
        $drivers = getAllDrivers();
        $stats = getDriverStatistics();
    }
}

// Get formatted drivers list for display
$displayDrivers = getDriversList();

// Check for search
$searchResults = [];
if (isset($_GET['search']) && !empty($_GET['search'])) {
    $searchTerm = $_GET['search'];
    $searchResults = searchDrivers($searchTerm);
    $driversToDisplay = $searchResults;
} else {
    $driversToDisplay = $displayDrivers;
}

// TODA Filter / Scope
$todaFilter = $_GET['toda_id'] ?? '';
$isScopedTODA = (!isSuperAdmin() && currentAdminRole() !== ROLE_BPLO_VERIFIER);

if ($isScopedTODA) {
    $myToda = currentAdminTodaId();
    if (!empty($myToda)) $todaFilter = $myToda;
}

if ($todaFilter !== '') {
    $driversToDisplay = array_filter($driversToDisplay, function($d) use ($todaFilter, $isScopedTODA) {
        if (!is_array($d)) return false;
        $did = $d['todaId'] ?? null;

        return (string)$did === (string)$todaFilter;
    });
}

$selectedTodaId = $todaFilter !== '' ? $todaFilter : null;
$stats = getDriverStatisticsForToda($selectedTodaId);
$registeredDriverCount = (int)($stats['totalDrivers'] ?? count($driversToDisplay));

// Handle sorting
$sortBy = $_GET['sort'] ?? 'name';
$sortOrder = $_GET['order'] ?? 'asc';

// Apply sorting to drivers
if (!empty($driversToDisplay)) {
    $driversToDisplay = sortDrivers($driversToDisplay, $sortBy, $sortOrder);
}

$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = max(10, min(100, (int)($_GET['per_page'] ?? 20)));
$driverPaginationResult = paginateAssociativeArray($driversToDisplay, $page, $perPage);
$driversToDisplay = $driverPaginationResult['items'];
$driverPagination = $driverPaginationResult['pagination'];

// Function to sort drivers
function sortDrivers($drivers, $sortBy, $sortOrder) {
    $sortedDrivers = $drivers;
    
    uasort($sortedDrivers, function($a, $b) use ($sortBy, $sortOrder) {
        $valueA = '';
        $valueB = '';
        
        switch ($sortBy) {
            case 'name':
                $valueA = strtolower($a['name'] ?? '');
                $valueB = strtolower($b['name'] ?? '');
                break;
            case 'status':
                $valueA = strtolower($a['accountStatus'] ?? '');
                $valueB = strtolower($b['accountStatus'] ?? '');
                break;
            case 'permit':
                $valueA = strtolower($a['permitNumber'] ?? '');
                $valueB = strtolower($b['permitNumber'] ?? '');
                break;
            case 'vehicle':
                $valueA = strtolower($a['plateNumber'] ?? '');
                $valueB = strtolower($b['plateNumber'] ?? '');
                break;
            case 'toda':
                $valueA = strtolower($a['todaName'] ?? '');
                $valueB = strtolower($b['todaName'] ?? '');
                break;
            case 'phone':
                $valueA = strtolower($a['phone'] ?? '');
                $valueB = strtolower($b['phone'] ?? '');
                break;
            default:
                $valueA = strtolower($a['name'] ?? '');
                $valueB = strtolower($b['name'] ?? '');
        }
        
        if ($sortOrder === 'asc') {
            return strcmp($valueA, $valueB);
        } else {
            return strcmp($valueB, $valueA);
        }
    });
    
    return $sortedDrivers;
}

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
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($pageTitle); ?> - Kaltrike Admin</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel=\"stylesheet\" href=\"assets/styles.css\">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
        
        .logo i {
            font-size: 24px;
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
        
        .add-driver-btn {
            background: #27ae60;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .add-driver-btn:hover {
            background: #219653;
            transform: translateY(-2px);
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
        .stat-card:nth-child(3) { border-top-color: #e74c3c; }
        .stat-card:nth-child(4) { border-top-color: #f39c12; }
        
        .stat-icon {
            font-size: 30px;
            margin-bottom: 15px;
            opacity: 0.8;
        }
        
        .stat-card:nth-child(1) .stat-icon { color: #3498db; }
        .stat-card:nth-child(2) .stat-icon { color: #27ae60; }
        .stat-card:nth-child(3) .stat-icon { color: #e74c3c; }
        .stat-card:nth-child(4) .stat-icon { color: #f39c12; }
        
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
        
        /* Chart Container */
        .chart-container {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 30px;
        }
        
        .section-title {
            color: #2c3e50;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #f0f0f0;
            font-size: 18px;
            font-weight: 600;
        }
        
        /* Drivers Table */
        .drivers-table-container {
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
        
        .driver-count {
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
        
        /* Driver Info */
        .driver-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .driver-avatar {
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
        
        .driver-details {
            display: flex;
            flex-direction: column;
        }
        
        .driver-name {
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 3px;
        }
        
        .driver-id {
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
        
        .status-validated {
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
        
        .btn-validate:hover {
            background-color: #27ae60;
            color: white;
            border-color: #27ae60;
        }
        
        .btn-delete:hover {
            background-color: #e74c3c;
            color: white;
            border-color: #e74c3c;
        }
        
        /* Plate Number Badge */
        .plate-badge {
            background: #e8f4fc;
            color: #3498db;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
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
        
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
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
            border-radius: 10px;
            width: 90%;
            max-width: 500px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.2);
            animation: slideIn 0.3s;
        }
        
        @keyframes slideIn {
            from { transform: translateY(-50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        
        .modal-header {
            background: #3498db;
            color: white;
            padding: 20px 25px;
            border-radius: 10px 10px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h3 {
            margin: 0;
            font-size: 18px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .close-modal {
            background: none;
            border: none;
            color: white;
            font-size: 24px;
            cursor: pointer;
            padding: 0;
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            transition: background 0.3s;
        }
        
        .close-modal:hover {
            background: rgba(255,255,255,0.2);
        }
        
        .modal-body {
            padding: 25px;
            max-height: 70vh;
            overflow-y: auto;
        }
        
        /* Form Styles */
        .form-step {
            display: none;
        }
        
        .form-step.active {
            display: block;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #2c3e50;
            font-weight: 600;
            font-size: 14px;
        }
        
        .form-group input,
        .form-group select {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: all 0.3s;
            background: white;
        }
        
        .form-group input:focus,
        .form-group select:focus {
            border-color: #3498db;
            outline: none;
            box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
        }
        
        .form-actions {
            display: flex;
            justify-content: space-between;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
        
        .btn-prev,
        .btn-next,
        .btn-submit {
            padding: 12px 25px;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-prev {
            background-color: #95a5a6;
            color: white;
        }
        
        .btn-prev:hover {
            background-color: #7f8c8d;
            transform: translateY(-2px);
        }
        
        .btn-next {
            background-color: #3498db;
            color: white;
        }
        
        .btn-next:hover {
            background-color: #2980b9;
            transform: translateY(-2px);
        }
        
        .btn-submit {
            background-color: #27ae60;
            color: white;
        }
        
        .btn-submit:hover {
            background-color: #219653;
            transform: translateY(-2px);
        }
        
        /* Step Indicator */
        .step-indicator {
            display: flex;
            justify-content: center;
            margin-bottom: 30px;
            gap: 20px;
        }
        
        .step {
            display: flex;
            align-items: center;
            color: #bdc3c7;
            font-size: 14px;
        }
        
        .step.active {
            color: #3498db;
        }
        
        .step-number {
            width: 30px;
            height: 30px;
            border-radius: 50%;
            background-color: #bdc3c7;
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 8px;
            font-weight: bold;
            font-size: 14px;
        }
        
        .step.active .step-number {
            background-color: #3498db;
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
            
            .control-buttons {
                width: 100%;
                justify-content: space-between;
            }
            
            table {
                display: block;
                overflow-x: auto;
            }
            
            .modal-content {
                width: 95%;
                margin: 20px auto;
            }
        }
        
        @media (max-width: 480px) {
            .header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .action-buttons {
                flex-direction: column;
                width: 100%;
            }
            
            .action-btn {
                width: 100%;
                justify-content: center;
            }
            
            .control-buttons {
                flex-direction: column;
                gap: 10px;
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
            <h1><i class="fas fa-users"></i> <?php echo htmlspecialchars($pageTitle); ?></h1>
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
                <h2>Driver List <span>(<?php echo $registeredDriverCount; ?> registered drivers<?php echo $selectedTodaId ? ' in ' . htmlspecialchars(getTodaName($selectedTodaId)) : ''; ?>)</span></h2>
            </div>
            <div class="control-buttons">
                <div class="sort-container">
                    <button class="sort-btn" onclick="toggleSortDropdown()">
                        <span><i class="fas fa-sort-amount-down"></i> Sort</span>
                        <i class="fas fa-chevron-down"></i>
                    </button>
                    <div class="sort-dropdown" id="sortDropdown">
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
                        <div class="sort-option <?php echo $sortBy == 'status' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('status', 'asc')">
                            <i class="fas fa-sort"></i>
                            <span>Status (A-Z)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'status' && $sortOrder == 'desc' ? 'active' : ''; ?>" 
                             onclick="sortBy('status', 'desc')">
                            <i class="fas fa-sort"></i>
                            <span>Status (Z-A)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'permit' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('permit', 'asc')">
                            <i class="fas fa-id-card"></i>
                            <span>Permit (A-Z)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'vehicle' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('vehicle', 'asc')">
                            <i class="fas fa-car"></i>
                            <span>Vehicle (A-Z)</span>
                        </div>
                    </div>
                </div>
                <?php if (hasPermission(PERM_DRIVERS_MANAGE)): ?>
                <button class="add-driver-btn" onclick="openAddDriverModal()">
                    <i class="fas fa-plus"></i> Add Driver
                </button>
                <?php endif; ?>
            </div>
        </div>
        
        <!-- Search Box -->
        <div class="search-container">
            <form method="GET" action="" id="searchForm">
                <i class="fas fa-search search-icon"></i>
                <input type="text" name="search" class="search-box" 
                       placeholder="Search drivers by name, phone, or permit number..."
                       value="<?php echo isset($_GET['search']) ? htmlspecialchars($_GET['search']) : ''; ?>">
<?php if (!$isScopedTODA): ?>
<select name="toda_id" class="filter-input" style="width: 220px; margin-left: 10px;">
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
        
        <!-- Statistics Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-users"></i>
                </div>
                <div class="stat-number"><?php echo $stats['totalDrivers']; ?></div>
                <div class="stat-label">Registered Drivers</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-user-check"></i>
                </div>
                <div class="stat-number"><?php echo $stats['activeDrivers']; ?></div>
                <div class="stat-label">Active Accounts</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-clock"></i>
                </div>
                <div class="stat-number"><?php echo $stats['pendingDrivers']; ?></div>
                <div class="stat-label">Pending Approval</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-shield-alt"></i>
                </div>
                <div class="stat-number"><?php echo $stats['validatedDrivers']; ?></div>
                <div class="stat-label">Validated</div>
            </div>
        </div>
        
        <!-- Drivers Table -->
        <div class="drivers-table-container">
            <div class="table-header">
                <h3>All Drivers</h3>
                <div style="display:flex; align-items:center; gap:12px; flex-wrap:wrap;">
                <div class="driver-count">
                    <?php 
                    if (isset($_GET['search']) && !empty($_GET['search'])) {
                        echo $driverPagination['total_items'] . " drivers found";
                    } else {
                        echo "Showing " . ($driverPagination['total_items'] > 0 ? ($driverPagination['offset'] + 1) : 0) . "-" . min($driverPagination['offset'] + $driverPagination['per_page'], $driverPagination['total_items']) . " of " . $driverPagination['total_items'] . " drivers";
                    }
                    ?>
                </div>
                <?php if (hasPermission(PERM_DRIVERS_MANAGE)): ?>
                <label style="display:flex; align-items:center; gap:8px; font-size:13px; color:#2c3e50;">
                    <input type="checkbox" id="selectAllDrivers"> Select All
                </label>
                <button type="button" class="action-btn btn-delete" onclick="submitBulkDriverDelete()">
                    <i class="fas fa-trash"></i> Delete Selected
                </button>
                <?php endif; ?>
                </div>
            </div>

            <form id="bulkDriverDeleteForm" method="POST" style="display:none;">
                <input type="hidden" name="action" value="bulk_delete">
                <div id="bulkDriverDeleteInputs"></div>
            </form>
            
            <div style="overflow-x: auto;">
                <table>
                    <thead>
                        <tr>
                            <?php if (hasPermission(PERM_DRIVERS_MANAGE)): ?>
                            <th style="width:54px;">
                                <input type="checkbox" id="selectAllDriversHeader" aria-label="Select all drivers">
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
                            <th onclick="sortBy('phone', '<?php echo $sortBy == 'phone' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Contact</span>
                                    <i class="fas <?php echo getSortIcon('phone', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('permit', '<?php echo $sortBy == 'permit' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Permit</span>
                                    <i class="fas <?php echo getSortIcon('permit', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('vehicle', '<?php echo $sortBy == 'vehicle' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Vehicle</span>
                                    <i class="fas <?php echo getSortIcon('vehicle', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
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
                        if (!empty($driversToDisplay)) {
                            foreach ($driversToDisplay as $driverId => $driver) {
                                $firstLetter = strtoupper(substr($driver['name'] ?? '?', 0, 1));
                                $status = $driver['accountStatus'] ?? 'pending';
                                $statusClass = 'status-' . $status;
                        ?>
                        <tr>
                            <?php if (hasPermission(PERM_DRIVERS_MANAGE)): ?>
                            <td>
                                <input type="checkbox" class="driver-row-select" value="<?php echo htmlspecialchars($driverId); ?>" aria-label="Select driver <?php echo htmlspecialchars($driver['name'] ?? ''); ?>">
                            </td>
                            <?php endif; ?>
                            <td>
                                <div class="driver-info">
                                    <div class="driver-avatar"><?php echo $firstLetter; ?></div>
                                    <div class="driver-details">
                                        <div class="driver-name"><?php echo htmlspecialchars($driver['name'] ?? 'N/A'); ?></div>
                                        <div class="driver-id">ID: <?php echo substr($driverId, 0, 8); ?>...</div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div style="font-weight: 600; color: #2c3e50;">
                                    <?php echo htmlspecialchars($driver['todaName'] ?? getTodaName($driver['todaId'] ?? null)); ?>
                                </div>
                                <?php if (hasPermission(PERM_DRIVERS_MANAGE)): ?>
                                    <?php $driverTodaId = $driver['todaId'] ?? null; ?>
                                    <?php if (isSuperAdmin()): ?>
                                        <form method="POST" style="margin-top:6px; display:flex; gap:6px; align-items:center;">
                                            <input type="hidden" name="action" value="assign_toda">
                                            <input type="hidden" name="driver_id" value="<?php echo htmlspecialchars($driverId); ?>">
                                            <select name="toda_id" style="padding:6px; border:1px solid #ddd; border-radius:6px; font-size:12px;">
                                                <option value="">Select TODA</option>
                                                <?php if (is_array($todas) && !empty($todas)): ?>
                                                    <?php foreach ($todas as $tid => $td): ?>
                                                        <option value="<?php echo htmlspecialchars($tid); ?>" <?php echo ((string)$driverTodaId === (string)$tid) ? 'selected' : ''; ?>>
                                                            <?php echo htmlspecialchars($td['name'] ?? $tid); ?>
                                                        </option>
                                                    <?php endforeach; ?>
                                                <?php endif; ?>
                                            </select>
                                            <button type="submit" style="padding:6px 10px; border:none; border-radius:6px; background:#3498db; color:#fff; font-size:12px; cursor:pointer;">Assign</button>
                                        </form>
                                    <?php else: ?>
                                        <?php if (empty($driverTodaId)): ?>
                                            <form method="POST" style="margin-top:6px;">
                                                <input type="hidden" name="action" value="assign_toda">
                                                <input type="hidden" name="driver_id" value="<?php echo htmlspecialchars($driverId); ?>">
                                                <input type="hidden" name="toda_id" value="<?php echo htmlspecialchars(currentAdminTodaId()); ?>">
                                                <button type="submit" style="padding:6px 10px; border:none; border-radius:6px; background:#27ae60; color:#fff; font-size:12px; cursor:pointer;">Assign to My TODA</button>
                                            </form>
                                        <?php endif; ?>
                                    <?php endif; ?>
                                <?php endif; ?>
                            </td>
                            <td>
                                <div style="font-weight: 600;"><?php echo htmlspecialchars($driver['phone'] ?? 'N/A'); ?></div>
                                <div style="color: #7f8c8d; font-size: 13px;"><?php echo htmlspecialchars($driver['email'] ?? 'N/A'); ?></div>
                            </td>
                            <td>
                                <div style="font-weight: 600; color: #2c3e50;"><?php echo htmlspecialchars($driver['permitNumber'] ?? 'N/A'); ?></div>
                            </td>
                            <td>
                                <div class="plate-badge"><?php echo htmlspecialchars($driver['plateNumber'] ?? 'N/A'); ?></div>
                            </td>
                            <td>
                                <span class="status-badge <?php echo $statusClass; ?>">
                                    <?php echo ucfirst($status); ?>
                                </span>
                            </td>
                            <td>
                                <div class="action-buttons">
                                    <button class="action-btn btn-view" onclick="viewDriverDetails('<?php echo $driverId; ?>')">
                                        <i class="fas fa-eye"></i> Details
                                    </button>
                                    <?php if (hasPermission(PERM_VERIFICATION_VIEW)): ?>
                                    <button class="action-btn btn-validate" onclick="viewDriverValidation('<?php echo $driverId; ?>')">
                                        <i class="fas fa-user-check"></i> <?php echo hasPermission(PERM_VERIFICATION_MANAGE) ? 'Validate' : 'View Validation'; ?>
                                    </button>
                                    <?php endif; ?>
                                    <?php if (hasPermission(PERM_DRIVERS_MANAGE)): ?>
                                    <button class="action-btn btn-delete" onclick="deleteDriver('<?php echo $driverId; ?>')">
                                        <i class="fas fa-trash"></i> Delete
                                    </button>
                                    <?php endif; ?>
                                </div>
                            </td>
                        </tr>
                        <?php 
                            }
                        } else {
                            echo '<tr><td colspan="8" class="no-data">
                                <i class="fas fa-users-slash"></i><br>
                                <div style="margin-top: 10px; font-size: 16px;">';
                            
                            if (isset($_GET['search']) && !empty($_GET['search'])) {
                                echo 'No drivers found for "' . htmlspecialchars($_GET['search']) . '"';
                            } else {
                                echo 'No drivers found. Add your first driver!';
                            }
                            
                            echo '</div></td></tr>';
                        }
                        ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    
    <!-- Add Driver Modal -->
    <div id="addDriverModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class="fas fa-user-plus"></i> Add New Driver</h3>
                <button class="close-modal" onclick="closeModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div class="step-indicator">
                    <div class="step active" id="step1">
                        <div class="step-number">1</div>
                        <div>Personal Info</div>
                    </div>
                    <div class="step" id="step2">
                        <div class="step-number">2</div>
                        <div>Vehicle Details</div>
                    </div>
                    <div class="step" id="step3">
                        <div class="step-number">3</div>
                        <div>Account Setup</div>
                    </div>
                </div>
                
                <form id="driverForm" method="POST" action="">
                    <input type="hidden" name="action" value="add">
                    
                    <!-- Step 1: Personal Information -->
                    <div class="form-step active" id="formStep1">
                        <div class="form-group">
                            <label for="fullName"><i class="fas fa-user"></i> Full Name *</label>
                            <input type="text" id="fullName" name="fullName" required placeholder="Enter driver's full name">
                        </div>
                        
                        <div class="form-group">
                            <label for="email"><i class="fas fa-envelope"></i> Email Address *</label>
                            <input type="email" id="email" name="email" required placeholder="Enter email address">
                        </div>
                        
                        <div class="form-group">
                            <label for="permitNumber"><i class="fas fa-id-card"></i> Permit Number *</label>
                            <input type="text" id="permitNumber" name="permitNumber" required placeholder="Enter permit number">
                        </div>
                        
                        <div class="form-group">
                            <label for="phone"><i class="fas fa-phone"></i> Phone Number *</label>
                            <input type="tel" id="phone" name="phone" required placeholder="Enter phone number">
                        </div>
                        
                        <div class="form-group">
                            <label for="password"><i class="fas fa-lock"></i> Password *</label>
                            <input type="password" id="password" name="password" required placeholder="Enter password" minlength="6">
                            <small style="color: #7f8c8d; display: block; margin-top: 5px; font-size: 12px;">
                                Minimum 6 characters
                            </small>
                        </div>
                        
                        <div class="form-actions">
                            <div></div>
                            <button type="button" class="btn-next" onclick="nextStep()">
                                Next <i class="fas fa-arrow-right"></i>
                            </button>
                        </div>
                    </div>
                    
                    <!-- Step 2: Vehicle Details -->
                    <div class="form-step" id="formStep2">
                        <div class="form-group">
                            <label for="vehiclePlate"><i class="fas fa-car"></i> Plate Number *</label>
                            <input type="text" id="vehiclePlate" name="vehiclePlate" required placeholder="Enter vehicle plate number">
                        </div>
                        
                        <div class="form-actions">
                            <button type="button" class="btn-prev" onclick="prevStep()">
                                <i class="fas fa-arrow-left"></i> Previous
                            </button>
                            <button type="button" class="btn-next" onclick="nextStep()">
                                Next <i class="fas fa-arrow-right"></i>
                            </button>
                        </div>
                    </div>
                    
                    <!-- Step 3: Account Creation -->
                    <div class="form-step" id="formStep3">
                        <div class="form-group">
                            <label for="status"><i class="fas fa-user-tag"></i> Account Status</label>
                            <select id="status" name="status">
                                <option value="pending">Pending</option>
                                <option value="active">Active</option>
                                <option value="validated">Validated</option>
                            </select>
                        </div>
                        
                        <div class="form-group" style="background: #f8f9fa; padding: 20px; border-radius: 8px;">
                            <h4 style="margin-top: 0; color: #2c3e50; font-size: 16px;">
                                <i class="fas fa-file-alt"></i> Review Information
                            </h4>
                            <div id="reviewInfo" style="color: #7f8c8d; font-size: 14px; line-height: 1.6;">
                                Please complete previous steps to review information.
                            </div>
                        </div>
                        
                        <div class="form-actions">
                            <button type="button" class="btn-prev" onclick="prevStep()">
                                <i class="fas fa-arrow-left"></i> Previous
                            </button>
                            <button type="submit" class="btn-submit">
                                <i class="fas fa-user-plus"></i> Create Driver Account
                            </button>
                        </div>
                    </div>
                </form>
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
        const url = new URL(window.location.href);
        url.searchParams.set('sort', column);
        url.searchParams.set('order', order);
        window.location.href = url.toString();
    }
    
    // Close dropdown when clicking outside
    document.addEventListener('click', function(event) {
        const dropdown = document.getElementById('sortDropdown');
        const sortBtn = document.querySelector('.sort-btn');
        
        if (!sortBtn.contains(event.target) && !dropdown.contains(event.target)) {
            dropdown.classList.remove('show');
        }
    });
    
    // Modal Functions
    function openAddDriverModal() {
        document.getElementById('addDriverModal').style.display = 'block';
        resetForm();
    }
    
    function closeModal() {
        document.getElementById('addDriverModal').style.display = 'none';
    }
    
    // Close modal when clicking outside
    window.onclick = function(event) {
        const modal = document.getElementById('addDriverModal');
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
    
    // Multi-step Form Functions
    let currentStep = 1;
    
    function nextStep() {
        // Validate current step before proceeding
        if (validateStep(currentStep)) {
            document.getElementById('formStep' + currentStep).classList.remove('active');
            document.getElementById('step' + currentStep).classList.remove('active');
            
            currentStep++;
            
            document.getElementById('formStep' + currentStep).classList.add('active');
            document.getElementById('step' + currentStep).classList.add('active');
            
            // Update review info on step 3
            if (currentStep === 3) {
                updateReviewInfo();
            }
        }
    }
    
    function prevStep() {
        document.getElementById('formStep' + currentStep).classList.remove('active');
        document.getElementById('step' + currentStep).classList.remove('active');
        
        currentStep--;
        
        document.getElementById('formStep' + currentStep).classList.add('active');
        document.getElementById('step' + currentStep).classList.add('active');
    }
    
    function validateStep(step) {
        let isValid = true;
        const errorColor = '#e74c3c';
        const normalColor = '#ddd';
        
        if (step === 1) {
            const requiredFields = ['fullName', 'email', 'permitNumber', 'phone', 'password'];
            requiredFields.forEach(fieldId => {
                const field = document.getElementById(fieldId);
                if (!field.value.trim()) {
                    field.style.borderColor = errorColor;
                    isValid = false;
                } else {
                    field.style.borderColor = normalColor;
                }
            });
            
            // Validate email format
            const email = document.getElementById('email');
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (email.value && !emailRegex.test(email.value)) {
                email.style.borderColor = errorColor;
                isValid = false;
            }
            
            // Validate password length
            const password = document.getElementById('password');
            if (password.value.length < 6) {
                password.style.borderColor = errorColor;
                isValid = false;
            }
        }
        
        if (step === 2) {
            const requiredFields = ['vehiclePlate'];
            requiredFields.forEach(fieldId => {
                const field = document.getElementById(fieldId);
                if (!field.value.trim()) {
                    field.style.borderColor = errorColor;
                    isValid = false;
                } else {
                    field.style.borderColor = normalColor;
                }
            });
        }
        
        return isValid;
    }
    
    function updateReviewInfo() {
        const reviewDiv = document.getElementById('reviewInfo');
        const data = {
            name: document.getElementById('fullName').value,
            email: document.getElementById('email').value,
            phone: document.getElementById('phone').value,
            permit: document.getElementById('permitNumber').value,
            vehiclePlate: document.getElementById('vehiclePlate').value,
            status: document.getElementById('status').value
        };
        
        reviewDiv.innerHTML = `
            <div><strong>Name:</strong> ${data.name}</div>
            <div><strong>Email:</strong> ${data.email}</div>
            <div><strong>Phone:</strong> ${data.phone}</div>
            <div><strong>Permit #:</strong> ${data.permit}</div>
            <div><strong>Plate Number:</strong> ${data.vehiclePlate}</div>
            <div><strong>Status:</strong> <span class="status-badge status-${data.status}">${data.status}</span></div>
        `;
    }
    
    function resetForm() {
        currentStep = 1;
        document.querySelectorAll('.form-step').forEach(step => step.classList.remove('active'));
        document.querySelectorAll('.step').forEach(step => step.classList.remove('active'));
        
        document.getElementById('formStep1').classList.add('active');
        document.getElementById('step1').classList.add('active');
        
        document.getElementById('driverForm').reset();
        document.getElementById('reviewInfo').innerHTML = 'Please complete previous steps to review information.';
        
        // Reset border colors
        document.querySelectorAll('.form-group input, .form-group select').forEach(field => {
            field.style.borderColor = '#ddd';
        });
    }
    
    // Driver Actions
    function viewDriverDetails(driverId) {
        window.location.href = 'driver_details.php?id=' + encodeURIComponent(driverId);
    }
    
    function viewDriverValidation(driverId) {
        window.location.href = 'driver_validation.php?id=' + encodeURIComponent(driverId);
    }
    
    function validateDriver(driverId) {
        if (confirm('Are you sure you want to validate this driver? This will approve their account.')) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '';
            
            const actionInput = document.createElement('input');
            actionInput.type = 'hidden';
            actionInput.name = 'action';
            actionInput.value = 'validate';
            form.appendChild(actionInput);
            
            const idInput = document.createElement('input');
            idInput.type = 'hidden';
            idInput.name = 'driver_id';
            idInput.value = driverId;
            form.appendChild(idInput);
            
            document.body.appendChild(form);
            form.submit();
        }
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

    function submitBulkDriverDelete() {
        const selected = Array.from(document.querySelectorAll('.driver-row-select:checked')).map((row) => row.value);
        if (!selected.length) {
            alert('Please select at least one driver.');
            return;
        }

        if (!confirm('Delete the selected driver record(s)? This action cannot be undone.')) {
            return;
        }

        const container = document.getElementById('bulkDriverDeleteInputs');
        container.innerHTML = '';
        selected.forEach((id) => {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'selected_ids[]';
            input.value = id;
            container.appendChild(input);
        });
        document.getElementById('bulkDriverDeleteForm').submit();
    }

    syncBulkSelection('#selectAllDrivers', '.driver-row-select');
    syncBulkSelection('#selectAllDriversHeader', '.driver-row-select');

    function deleteDriver(driverId) {
        if (confirm('⚠️ WARNING: Are you sure you want to delete this driver?\n\nThis action cannot be undone and will permanently remove all driver data.')) {
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
            idInput.name = 'driver_id';
            idInput.value = driverId;
            form.appendChild(idInput);
            
            document.body.appendChild(form);
            form.submit();
        }
    }
    
    // Handle form submission
    document.getElementById('driverForm').addEventListener('submit', function(e) {
        if (!validateStep(3)) {
            e.preventDefault();
            alert('Please fill in all required fields correctly.');
        }
    });
    
    // Add real-time validation
    document.querySelectorAll('#driverForm input, #driverForm select').forEach(field => {
        field.addEventListener('blur', function() {
            if (!this.value.trim() && this.hasAttribute('required')) {
                this.style.borderColor = '#e74c3c';
            } else {
                this.style.borderColor = '#ddd';
            }
        });
        
        field.addEventListener('input', function() {
            this.style.borderColor = '#ddd';
        });
    });
    
    // Search box auto-submit with slight delay
    let searchTimeout;
    document.querySelector('.search-box').addEventListener('input', function() {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
            if (this.value.trim()) {
                document.getElementById('searchForm').submit();
            }
        }, 500);
    });
    
    // Handle Enter key in search
    document.querySelector('.search-box').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            document.getElementById('searchForm').submit();
        }
    });
    </script>
    <?php if (($driverPagination['total_pages'] ?? 1) > 1): ?>
    <div style="padding:0 25px 25px; margin-left:250px;">
        <div style="display:flex; justify-content:space-between; align-items:center; gap:12px; flex-wrap:wrap; background:#fff; border-radius:12px; padding:14px 18px; box-shadow:0 2px 10px rgba(0,0,0,0.08);">
            <div style="font-size:13px; color:#64748b;">Page <?php echo $driverPagination['current_page']; ?> of <?php echo $driverPagination['total_pages']; ?></div>
            <div style="display:flex; gap:8px; flex-wrap:wrap;">
                <?php if ($driverPagination['has_previous']): ?><a class="action-btn btn-view" href="<?php echo htmlspecialchars(buildQueryUrl(['page' => $driverPagination['current_page'] - 1])); ?>">Previous</a><?php endif; ?>
                <?php if ($driverPagination['has_next']): ?><a class="action-btn btn-view" href="<?php echo htmlspecialchars(buildQueryUrl(['page' => $driverPagination['current_page'] + 1])); ?>">Next</a><?php endif; ?>
            </div>
        </div>
    </div>
    <?php endif; ?>
</body>
</html>