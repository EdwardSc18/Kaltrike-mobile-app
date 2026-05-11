<?php
// commuter_details.php - Commuter Details View
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_COMMUTERS_VIEW);

// Get commuter ID from URL
$commuterId = $_GET['id'] ?? '';
if (empty($commuterId)) {
    header('Location: commuters.php');
    exit();
}

// Get commuter data
$commuter = getCommuterById($commuterId);

if (!$commuter) {
    header('Location: commuters.php');
    exit();
}

// Get commuter data
$commuterPhone = $commuter['phone'] ?? '';
$commuterRides = getCommuterRides($commuterPhone);
$rideStats = getCommuterRideStatistics($commuterPhone);

// Format commuter data for display
$fullName = trim(($commuter['name'] ?? '') . ' ' . ($commuter['lastName'] ?? ''));
if (empty($fullName)) {
    $fullName = 'Unnamed User';
}

$status = $commuter['accountStatus'] ?? 'inactive';
$statusClass = 'status-' . $status;

// Format dates - FIXED VERSION
function formatDisplayDate($timestamp) {
    if (empty($timestamp)) {
        return 'N/A';
    }
    
    if (is_numeric($timestamp)) {
        // Check if timestamp is in milliseconds
        if ($timestamp > 1000000000000) {
            $timestamp = $timestamp / 1000;
        }
        // Use floor() to safely convert float to int for date() function
        return date('F j, Y g:i A', floor($timestamp));
    }
    
    return $timestamp;
}

$createdAt = formatDisplayDate($commuter['createdAt'] ?? null);
$updatedAt = formatDisplayDate($commuter['updatedAt'] ?? null);
$termsAgreedAt = formatDisplayDate($commuter['termsAgreedAt'] ?? null);

// Get additional trip data if available
$additionalTrips = [];
$tripCollections = ['trips', 'TripRequests', 'completedTrips'];
foreach ($tripCollections as $collection) {
    $tripsData = firebaseGet($collection);
    if (!empty($tripsData) && is_array($tripsData)) {
        foreach ($tripsData as $tripId => $trip) {
            if ((isset($trip['userPhone']) && $trip['userPhone'] == $commuterPhone) || 
                (isset($trip['commuterId']) && $trip['commuterId'] == $commuterId)) {
                $trip['id'] = $tripId;
                $additionalTrips[] = $trip;
            }
        }
    }
}

// Merge additional trips if no rides found
if (empty($commuterRides) && !empty($additionalTrips)) {
    $commuterRides = array_merge($commuterRides, $additionalTrips);
}

// Helper function to format ride timestamps
function formatRideTime($timestamp) {
    if (empty($timestamp)) {
        return 'N/A';
    }
    
    if (is_numeric($timestamp)) {
        // Check if timestamp is in milliseconds
        if ($timestamp > 1000000000000) {
            $timestamp = $timestamp / 1000;
        }
        // Use floor() to safely convert float to int
        return date('M d, Y g:i A', floor($timestamp));
    }
    
    return $timestamp;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Commuter Details - Kaltrike Admin</title>
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
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .back-btn {
            background: #3498db;
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
            text-decoration: none;
        }
        
        .back-btn:hover {
            background: #2980b9;
            transform: translateY(-2px);
        }
        
        /* Commuter Profile */
        .profile-container {
            display: grid;
            grid-template-columns: 1fr 2fr;
            gap: 30px;
            margin-bottom: 30px;
        }
        
        @media (max-width: 768px) {
            .profile-container {
                grid-template-columns: 1fr;
            }
        }
        
        .profile-card {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
        }
        
        .profile-header {
            text-align: center;
            margin-bottom: 25px;
        }
        
        .profile-avatar {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            background: linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 36px;
            margin: 0 auto 15px;
        }
        
        .profile-name {
            font-size: 22px;
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        
        .profile-id {
            color: #7f8c8d;
            font-size: 14px;
            margin-bottom: 15px;
        }
        
        .status-badge {
            padding: 5px 15px;
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
        
        /* Profile Details */
        .profile-details h3 {
            color: #2c3e50;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #f0f0f0;
            font-size: 18px;
            font-weight: 600;
        }
        
        .detail-group {
            margin-bottom: 15px;
            display: flex;
            align-items: flex-start;
        }
        
        .detail-label {
            width: 120px;
            color: #7f8c8d;
            font-size: 14px;
            font-weight: 600;
        }
        
        .detail-value {
            flex: 1;
            color: #2c3e50;
            font-size: 14px;
        }
        
        .detail-value strong {
            font-weight: 600;
        }
        
        /* Statistics Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            border-radius: 10px;
            padding: 20px;
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
        .stat-card:nth-child(5) { border-top-color: #9b59b6; }
        .stat-card:nth-child(6) { border-top-color: #1abc9c; }
        
        .stat-icon {
            font-size: 24px;
            margin-bottom: 10px;
            opacity: 0.8;
        }
        
        .stat-card:nth-child(1) .stat-icon { color: #3498db; }
        .stat-card:nth-child(2) .stat-icon { color: #27ae60; }
        .stat-card:nth-child(3) .stat-icon { color: #e74c3c; }
        .stat-card:nth-child(4) .stat-icon { color: #f39c12; }
        .stat-card:nth-child(5) .stat-icon { color: #9b59b6; }
        .stat-card:nth-child(6) .stat-icon { color: #1abc9c; }
        
        .stat-number {
            font-size: 24px;
            font-weight: bold;
            color: #2c3e50;
            margin: 5px 0;
            line-height: 1;
        }
        
        .stat-label {
            color: #7f8c8d;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 600;
        }
        
        /* Rides Table */
        .rides-table-container {
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
        
        .ride-count {
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
        
        .ride-status-badge {
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            display: inline-block;
        }
        
        .status-ended, .status-completed {
            background-color: #d5f4e6;
            color: #27ae60;
        }
        
        .status-pending, .status-requested, .status-accepted, .status-ongoing {
            background-color: #fff3cd;
            color: #856404;
        }
        
        .status-cancelled, .status-canceled {
            background-color: #fdecea;
            color: #e74c3c;
        }
        
        .status-unknown {
            background-color: #e0e0e0;
            color: #7f8c8d;
        }
        
        .no-data {
            text-align: center;
            padding: 40px 20px;
            color: #7f8c8d;
        }
        
        .no-data i {
            font-size: 36px;
            margin-bottom: 15px;
            color: #bdc3c7;
        }
        
        /* Action Buttons */
        .action-buttons {
            display: flex;
            gap: 8px;
            justify-content: center;
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
            text-decoration: none;
        }
        
        .action-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 3px 8px rgba(0,0,0,0.1);
        }
        
        .btn-edit:hover {
            background-color: #3498db;
            color: white;
            border-color: #3498db;
        }
        
        .btn-delete:hover {
            background-color: #e74c3c;
            color: white;
            border-color: #e74c3c;
        }
        
        /* Responsive Design */
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
            
            .header {
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
            .stats-grid {
                grid-template-columns: 1fr;
            }
            
            .action-buttons {
                flex-direction: column;
                width: 100%;
            }
            
            .action-btn {
                width: 100%;
                justify-content: center;
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
            <h1><i class="fas fa-user-friends"></i> Commuter Details</h1>
            <a href="commuters.php" class="back-btn">
                <i class="fas fa-arrow-left"></i> Back to Commuters
            </a>
        </div>
        
        <!-- Profile Section -->
        <div class="profile-container">
            <!-- Profile Card -->
            <div class="profile-card">
                <div class="profile-header">
                    <div class="profile-avatar">
                        <?php echo strtoupper(substr($commuter['name'] ?? '?', 0, 1)); ?>
                    </div>
                    <div class="profile-name"><?php echo htmlspecialchars($fullName); ?></div>
                    <div class="profile-id">ID: <?php echo htmlspecialchars(substr($commuterId, 0, 12)); ?></div>
                    <span class="status-badge <?php echo $statusClass; ?>">
                        <?php echo ucfirst($status); ?> Commuter
                    </span>
                </div>
                
                <div class="action-buttons" style="justify-content: center; margin-top: 20px;">
                    <a href="commuters.php?search=<?php echo urlencode($commuter['phone'] ?? ''); ?>" class="action-btn btn-edit">
                        <i class="fas fa-search"></i> Find All Rides
                    </a>
                </div>
            </div>
            
            <!-- Profile Details -->
            <div class="profile-card">
                <h3>Account Information</h3>
                <div class="profile-details">
                    <div class="detail-group">
                        <div class="detail-label">Full Name:</div>
                        <div class="detail-value">
                            <strong><?php echo htmlspecialchars($fullName); ?></strong>
                        </div>
                    </div>
                    
                    <div class="detail-group">
                        <div class="detail-label">Email:</div>
                        <div class="detail-value"><?php echo htmlspecialchars($commuter['email'] ?? 'N/A'); ?></div>
                    </div>
                    
                    <div class="detail-group">
                        <div class="detail-label">Phone:</div>
                        <div class="detail-value"><?php echo htmlspecialchars($commuter['phone'] ?? 'N/A'); ?></div>
                    </div>
                    
                    <div class="detail-group">
                        <div class="detail-label">User Type:</div>
                        <div class="detail-value"><?php echo htmlspecialchars($commuter['userType'] ?? 'commuter'); ?></div>
                    </div>
                    
                    <div class="detail-group">
                        <div class="detail-label">Account Status:</div>
                        <div class="detail-value">
                            <span class="status-badge <?php echo $statusClass; ?>" style="display: inline-block; margin: 0;">
                                <?php echo ucfirst($status); ?>
                            </span>
                        </div>
                    </div>
                    
                    <div class="detail-group">
                        <div class="detail-label">Terms Agreed:</div>
                        <div class="detail-value">
                            <?php echo isset($commuter['termsAgreed']) && $commuter['termsAgreed'] ? 'Yes' : 'No'; ?>
                            <?php if (isset($commuter['termsAgreedAt'])): ?>
                                <br><small style="color: #7f8c8d;">on <?php echo $termsAgreedAt; ?></small>
                            <?php endif; ?>
                        </div>
                    </div>
                    
                    <div class="detail-group">
                        <div class="detail-label">Created At:</div>
                        <div class="detail-value"><?php echo $createdAt; ?></div>
                    </div>
                    
                    <div class="detail-group">
                        <div class="detail-label">Last Updated:</div>
                        <div class="detail-value"><?php echo $updatedAt; ?></div>
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
                <div class="stat-number"><?php echo $rideStats['totalRides']; ?></div>
                <div class="stat-label">Total Rides</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-check-circle"></i>
                </div>
                <div class="stat-number"><?php echo $rideStats['completedRides']; ?></div>
                <div class="stat-label">Completed</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-times-circle"></i>
                </div>
                <div class="stat-number"><?php echo $rideStats['cancelledRides']; ?></div>
                <div class="stat-label">Cancelled</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-clock"></i>
                </div>
                <div class="stat-number"><?php echo $rideStats['pendingRides']; ?></div>
                <div class="stat-label">Pending</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-money-bill-wave"></i>
                </div>
                <div class="stat-number">₱<?php echo number_format($rideStats['totalSpent'], 2); ?></div>
                <div class="stat-label">Total Spent</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-star"></i>
                </div>
                <div class="stat-number"><?php echo $rideStats['averageRating']; ?></div>
                <div class="stat-label">Avg Rating</div>
            </div>
        </div>
        
        <!-- Rides History -->
        <div class="rides-table-container">
            <div class="table-header">
                <h3>Ride History</h3>
                <div class="ride-count">
                    <?php echo count($commuterRides); ?> rides found
                </div>
            </div>
            
            <div style="overflow-x: auto;">
                <table>
                    <thead>
                        <tr>
                            <th>Ride ID</th>
                            <th>Pickup Location</th>
                            <th>Destination</th>
                            <th>Date & Time</th>
                            <th>Fare</th>
                            <th>Status</th>
                            <th>Driver</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php
                        if (!empty($commuterRides)) {
                            foreach ($commuterRides as $ride) {
                                $rideId = $ride['id'] ?? '';
                                $pickup = $ride['pickUpLocation'] ?? $ride['pickupLocation'] ?? $ride['pickup'] ?? 'N/A';
                                $destination = $ride['destinationLocation'] ?? $ride['destination'] ?? 'N/A';
                                
                                // Format time using helper function
                                $time = 'N/A';
                                if (isset($ride['timestamp'])) {
                                    $time = formatRideTime($ride['timestamp']);
                                } elseif (isset($ride['time'])) {
                                    $time = formatRideTime($ride['time']);
                                }
                                
                                // Format fare
                                $fare = 'N/A';
                                if (isset($ride['fareAmount'])) {
                                    $fare = '₱' . number_format($ride['fareAmount'], 2);
                                } elseif (isset($ride['fare'])) {
                                    $fare = '₱' . number_format($ride['fare'], 2);
                                }
                                
                                // Get status
                                $status = $ride['status'] ?? 'unknown';
                                $statusLower = strtolower($status);
                                $statusClass = 'status-unknown';
                                
                                if ($statusLower == 'ended' || $statusLower == 'completed') {
                                    $statusClass = 'status-ended';
                                } elseif ($statusLower == 'cancelled' || $statusLower == 'canceled') {
                                    $statusClass = 'status-cancelled';
                                } elseif (in_array($statusLower, ['pending', 'requested', 'accepted', 'ongoing'])) {
                                    $statusClass = 'status-pending';
                                }
                                
                                // Get driver info
                                $driverName = isset($ride['driverName']) ? $ride['driverName'] : (isset($ride['driverPhone']) ? $ride['driverPhone'] : 'N/A');
                        ?>
                        <tr>
                            <td>
                                <div style="font-weight: 600; color: #2c3e50;"><?php echo htmlspecialchars(substr($rideId, 0, 8)); ?>...</div>
                            </td>
                            <td>
                                <div style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                                    <?php echo htmlspecialchars($pickup); ?>
                                </div>
                            </td>
                            <td>
                                <div style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                                    <?php echo htmlspecialchars($destination); ?>
                                </div>
                            </td>
                            <td><?php echo htmlspecialchars($time); ?></td>
                            <td>
                                <div style="font-weight: 600; color: #27ae60;"><?php echo $fare; ?></div>
                            </td>
                            <td>
                                <span class="ride-status-badge <?php echo $statusClass; ?>">
                                    <?php echo ucfirst($status); ?>
                                </span>
                            </td>
                            <td>
                                <div style="color: #3498db; font-weight: 600;"><?php echo htmlspecialchars($driverName); ?></div>
                            </td>
                        </tr>
                        <?php 
                            }
                        } else {
                            echo '<tr><td colspan="7" class="no-data">
                                <i class="fas fa-car"></i><br>
                                <div style="margin-top: 10px; font-size: 16px;">No ride history found for this commuter.</div>
                                </td></tr>';
                        }
                        ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    
    <script>
    // Function to confirm delete
    function confirmDelete() {
        return confirm('⚠️ WARNING: Are you sure you want to delete this commuter?\n\nThis action cannot be undone and will permanently remove all commuter data.');
    }
    
    // Auto-hide any messages
    setTimeout(function() {
        const messages = document.querySelectorAll('.message-box');
        messages.forEach(function(msg) {
            msg.style.opacity = '0';
            msg.style.transition = 'opacity 0.5s';
            setTimeout(() => {
                msg.style.display = 'none';
            }, 500);
        });
    }, 5000);
    </script>
</body>
</html>