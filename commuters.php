<?php
// commuters.php - Commuter Management System
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_COMMUTERS_VIEW);

// Handle form submissions
$message = '';
$messageType = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $commuterId = $_POST['commuter_id'] ?? '';
    
    if ($_POST['action'] === 'delete' && !empty($commuterId)) {
        if (deleteCommuter($commuterId)) {
            $message = "Commuter deleted successfully!";
            $messageType = 'success';
        } else {
            $message = "Failed to delete commuter!";
            $messageType = 'error';
        }
    } elseif ($_POST['action'] === 'bulk_delete') {
        if (!isSuperAdmin()) {
            $message = "Only the super admin can bulk delete commuters.";
            $messageType = 'error';
        } else {
            $bulkDeleteResult = bulkDeleteRecords($_POST['selected_ids'] ?? [], 'deleteCommuter');
            if ($bulkDeleteResult['requested'] === 0) {
                $message = "Please select at least one commuter to delete!";
                $messageType = 'error';
            } elseif ($bulkDeleteResult['failed'] === 0) {
                $message = "Deleted " . $bulkDeleteResult['deleted'] . " commuter(s) successfully!";
                $messageType = 'success';
            } else {
                $message = "Deleted " . $bulkDeleteResult['deleted'] . " commuter(s). Failed to delete " . $bulkDeleteResult['failed'] . " selected record(s).";
                $messageType = $bulkDeleteResult['deleted'] > 0 ? 'success' : 'error';
            }
        }
    }
}

// Get statistics
$stats = getCommuterStatistics();

// Check for search
if (isset($_GET['search']) && !empty($_GET['search'])) {
    $searchTerm = trim($_GET['search']);
    $commutersToDisplay = searchCommuters($searchTerm);
} else {
    $commutersToDisplay = getAllCommuters();
}

// Handle sorting
$sortBy = $_GET['sort'] ?? 'name';
$sortOrder = $_GET['order'] ?? 'asc';

// Apply sorting to commuters
if (!empty($commutersToDisplay)) {
    $commutersToDisplay = sortCommuters($commutersToDisplay, $sortBy, $sortOrder);
}

$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = max(10, min(100, (int)($_GET['per_page'] ?? 20)));
$commuterPaginationResult = paginateAssociativeArray($commutersToDisplay, $page, $perPage);
$commutersToDisplay = $commuterPaginationResult['items'];
$commuterPagination = $commuterPaginationResult['pagination'];

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

// Function to safely format dates from Firebase timestamps
function formatFirebaseDate($timestamp, $format = 'M d, Y') {
    if (empty($timestamp) || !is_numeric($timestamp)) {
        return 'N/A';
    }
    
    // Check if timestamp is in milliseconds (Firebase often uses milliseconds)
    if ($timestamp > 1000000000000) {
        $timestamp = $timestamp / 1000;
    }
    
    // Use floor() to avoid float to int conversion warning
    return date($format, floor($timestamp));
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Commuters - Kaltrike Admin</title>
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
        
        .stat-icon {
            font-size: 30px;
            margin-bottom: 15px;
            opacity: 0.8;
        }
        
        .stat-card:nth-child(1) .stat-icon { color: #3498db; }
        .stat-card:nth-child(2) .stat-icon { color: #27ae60; }
        .stat-card:nth-child(3) .stat-icon { color: #9b59b6; }
        
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
        
        /* Commuters Table */
        .commuters-table-container {
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
        
        .commuter-count {
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
        
        /* Commuter Info */
        .commuter-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .commuter-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 16px;
            flex-shrink: 0;
        }
        
        .commuter-details {
            display: flex;
            flex-direction: column;
        }
        
        .commuter-name {
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 3px;
        }
        
        .commuter-id {
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
        
        .btn-delete:hover {
            background-color: #e74c3c;
            color: white;
            border-color: #e74c3c;
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
            <h1><i class="fas fa-user-friends"></i> Commuters Management</h1>
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
                <h2>Commuters List <span>(<?php echo $stats['totalCommuters']; ?> commuters)</span></h2>
            </div>
            <div class="control-buttons">
                <div class="sort-container">
                    <button class="sort-btn" onclick="toggleSortDropdown()">
                        <span><i class="fas fa-sort-amount-down"></i> Sort</span>
                        <i class="fas fa-chevron-down"></i>
                    </button>
                    <div class="sort-dropdown" id="sortDropdown">
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
                        <div class="sort-option <?php echo $sortBy == 'email' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('email', 'asc')">
                            <i class="fas fa-envelope"></i>
                            <span>Email (A-Z)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'phone' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('phone', 'asc')">
                            <i class="fas fa-phone"></i>
                            <span>Phone (A-Z)</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'date' && $sortOrder == 'desc' ? 'active' : ''; ?>" 
                             onclick="sortBy('date', 'desc')">
                            <i class="fas fa-calendar"></i>
                            <span>Newest First</span>
                        </div>
                        <div class="sort-option <?php echo $sortBy == 'date' && $sortOrder == 'asc' ? 'active' : ''; ?>" 
                             onclick="sortBy('date', 'asc')">
                            <i class="fas fa-calendar"></i>
                            <span>Oldest First</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Statistics Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-users"></i>
                </div>
                <div class="stat-number"><?php echo $stats['totalUsers']; ?></div>
                <div class="stat-label">Total Users</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-user-friends"></i>
                </div>
                <div class="stat-number"><?php echo $stats['totalCommuters']; ?></div>
                <div class="stat-label">Total Commuters</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-user-check"></i>
                </div>
                <div class="stat-number"><?php echo $stats['activeCommuters']; ?></div>
                <div class="stat-label">Active Commuters</div>
            </div>
        </div>
        
        <!-- Search Box -->
        <div class="search-container">
            <form method="GET" action="" id="searchForm">
                <i class="fas fa-search search-icon"></i>
                <input type="text" name="search" class="search-box" 
                       placeholder="Search commuters by name, phone, or email..."
                       value="<?php echo isset($_GET['search']) ? htmlspecialchars($_GET['search']) : ''; ?>">
                <input type="hidden" name="sort" value="<?php echo htmlspecialchars($sortBy); ?>">
                <input type="hidden" name="order" value="<?php echo htmlspecialchars($sortOrder); ?>">
            </form>
        </div>
        
        <!-- Commuters Table -->
        <div class="commuters-table-container">
            <div class="table-header">
                <h3>All Commuters</h3>
                <div style="display:flex; align-items:center; gap:12px; flex-wrap:wrap;">
                <div class="commuter-count">
                    <?php 
                    if (isset($_GET['search']) && !empty($_GET['search'])) {
                        echo $commuterPagination['total_items'] . " commuters found";
                    } else {
                        echo "Showing " . ($commuterPagination['total_items'] > 0 ? ($commuterPagination['offset'] + 1) : 0) . "-" . min($commuterPagination['offset'] + $commuterPagination['per_page'], $commuterPagination['total_items']) . " of " . $commuterPagination['total_items'] . " commuters";
                    }
                    ?>
                </div>
                <?php if (isSuperAdmin()): ?>
                <label style="display:flex; align-items:center; gap:8px; font-size:13px; color:#2c3e50;">
                    <input type="checkbox" id="selectAllCommuters"> Select All
                </label>
                <button type="button" class="action-btn btn-delete" onclick="submitBulkCommuterDelete()">
                    <i class="fas fa-trash"></i> Delete Selected
                </button>
                <?php endif; ?>
                </div>
            </div>

            <form id="bulkCommuterDeleteForm" method="POST" style="display:none;">
                <input type="hidden" name="action" value="bulk_delete">
                <div id="bulkCommuterDeleteInputs"></div>
            </form>
            
            <div style="overflow-x: auto;">
                <table>
                    <thead>
                        <tr>
                            <?php if (isSuperAdmin()): ?>
                            <th style="width:54px;">
                                <input type="checkbox" id="selectAllCommutersHeader" aria-label="Select all commuters">
                            </th>
                            <?php endif; ?>
                            <th onclick="sortBy('name', '<?php echo $sortBy == 'name' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Commuter</span>
                                    <i class="fas <?php echo getSortIcon('name', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('phone', '<?php echo $sortBy == 'phone' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Phone</span>
                                    <i class="fas <?php echo getSortIcon('phone', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('email', '<?php echo $sortBy == 'email' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Email</span>
                                    <i class="fas <?php echo getSortIcon('email', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('status', '<?php echo $sortBy == 'status' && $sortOrder == 'asc' ? 'desc' : 'asc'; ?>')">
                                <div class="sortable-header">
                                    <span>Status</span>
                                    <i class="fas <?php echo getSortIcon('status', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th onclick="sortBy('date', '<?php echo $sortBy == 'date' && $sortOrder == 'desc' ? 'asc' : 'desc'; ?>')">
                                <div class="sortable-header">
                                    <span>Joined Date</span>
                                    <i class="fas <?php echo getSortIcon('date', $sortBy, $sortOrder); ?> sort-icon"></i>
                                </div>
                            </th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php
                        if (!empty($commutersToDisplay)) {
                            foreach ($commutersToDisplay as $userId => $commuter) {
                                $firstLetter = strtoupper(substr($commuter['name'] ?? '?', 0, 1));
                                $status = $commuter['accountStatus'] ?? 'inactive';
                                $statusClass = 'status-' . $status;
                                $fullName = trim(($commuter['name'] ?? '') . ' ' . ($commuter['lastName'] ?? ''));
                                
                                // Format date using the helper function
                                $joinedDate = formatFirebaseDate($commuter['createdAt'] ?? null);
                        ?>
                        <tr>
                            <?php if (isSuperAdmin()): ?>
                            <td>
                                <input type="checkbox" class="commuter-row-select" value="<?php echo htmlspecialchars($userId); ?>" aria-label="Select commuter <?php echo htmlspecialchars($commuter['name'] ?? ''); ?>">
                            </td>
                            <?php endif; ?>
                            <td>
                                <div class="commuter-info">
                                    <div class="commuter-avatar"><?php echo htmlspecialchars($firstLetter); ?></div>
                                    <div class="commuter-details">
                                        <div class="commuter-name"><?php echo htmlspecialchars($fullName ?: 'Unnamed User'); ?></div>
                                        <div class="commuter-id">ID: <?php echo htmlspecialchars(substr($userId, 0, 8) . '...'); ?></div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div style="font-weight: 600;"><?php echo htmlspecialchars($commuter['phone'] ?? 'N/A'); ?></div>
                            </td>
                            <td>
                                <div style="color: #2c3e50;"><?php echo htmlspecialchars($commuter['email'] ?? 'N/A'); ?></div>
                            </td>
                            <td>
                                <span class="status-badge <?php echo $statusClass; ?>">
                                    <?php echo ucfirst($status); ?>
                                </span>
                            </td>
                            <td>
                                <div style="color: #7f8c8d; font-size: 13px;">
                                    <?php echo $joinedDate; ?>
                                </div>
                            </td>
                            <td>
                                <div class="action-buttons">
                                    <button class="action-btn btn-view" onclick="viewCommuterDetails('<?php echo $userId; ?>')">
                                        <i class="fas fa-eye"></i> View
                                    </button>
                                    <button class="action-btn btn-delete" onclick="deleteCommuter('<?php echo $userId; ?>')">
                                        <i class="fas fa-trash"></i> Delete
                                    </button>
                                </div>
                            </td>
                        </tr>
                        <?php 
                            }
                        } else {
                            echo '<tr><td colspan="7" class="no-data">
                                <i class="fas fa-user-friends"></i><br>
                                <div style="margin-top: 10px; font-size: 16px;">';
                            
                            if (isset($_GET['search']) && !empty($_GET['search'])) {
                                echo 'No commuters found for "' . htmlspecialchars($_GET['search']) . '"';
                            } else {
                                echo 'No commuters found in the system.';
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
        
        if (sortBtn && !sortBtn.contains(event.target) && dropdown && !dropdown.contains(event.target)) {
            dropdown.classList.remove('show');
        }
    });
    
    // Commuter Actions
    function viewCommuterDetails(commuterId) {
        window.location.href = 'commuter_details.php?id=' + encodeURIComponent(commuterId);
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

    function submitBulkCommuterDelete() {
        const selected = Array.from(document.querySelectorAll('.commuter-row-select:checked')).map((row) => row.value);
        if (!selected.length) {
            alert('Please select at least one commuter.');
            return;
        }

        if (!confirm('Delete the selected commuter record(s)? This action cannot be undone.')) {
            return;
        }

        const container = document.getElementById('bulkCommuterDeleteInputs');
        container.innerHTML = '';
        selected.forEach((id) => {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'selected_ids[]';
            input.value = id;
            container.appendChild(input);
        });
        document.getElementById('bulkCommuterDeleteForm').submit();
    }

    syncBulkSelection('#selectAllCommuters', '.commuter-row-select');
    syncBulkSelection('#selectAllCommutersHeader', '.commuter-row-select');

    function deleteCommuter(commuterId) {
        if (confirm('⚠️ WARNING: Are you sure you want to delete this commuter?\n\nThis action cannot be undone and will permanently remove all commuter data.')) {
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
            idInput.name = 'commuter_id';
            idInput.value = commuterId;
            form.appendChild(idInput);
            
            document.body.appendChild(form);
            form.submit();
        }
    }
    
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
    <?php if (($commuterPagination['total_pages'] ?? 1) > 1): ?>
    <div style="padding:0 25px 25px; margin-left:250px;">
        <div style="display:flex; justify-content:space-between; align-items:center; gap:12px; flex-wrap:wrap; background:#fff; border-radius:12px; padding:14px 18px; box-shadow:0 2px 10px rgba(0,0,0,0.08);">
            <div style="font-size:13px; color:#64748b;">Page <?php echo $commuterPagination['current_page']; ?> of <?php echo $commuterPagination['total_pages']; ?></div>
            <div style="display:flex; gap:8px; flex-wrap:wrap;">
                <?php if ($commuterPagination['has_previous']): ?><a class="action-btn btn-view" href="<?php echo htmlspecialchars(buildQueryUrl(['page' => $commuterPagination['current_page'] - 1])); ?>">Previous</a><?php endif; ?>
                <?php if ($commuterPagination['has_next']): ?><a class="action-btn btn-view" href="<?php echo htmlspecialchars(buildQueryUrl(['page' => $commuterPagination['current_page'] + 1])); ?>">Next</a><?php endif; ?>
            </div>
        </div>
    </div>
    <?php endif; ?>
</body>
</html>