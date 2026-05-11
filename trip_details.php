<?php
// trip_details.php - Trip Complete Details View
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_TRIPS_VIEW);


$tripId = $_GET['id'] ?? '';
if (empty($tripId)) {
    header('Location: trips.php');
    exit();
}

// Get trip with improved error handling and debugging
$trip = getTripById($tripId);

// If not found by direct method, try to find in all trips
if (!$trip || !is_array($trip) || empty($trip)) {
    // Debug: Try to find the trip manually
    error_log("TRIP DETAILS DEBUG: Trip ID from URL: $tripId - Not found via getTripById");
    
    // Get all trips to see what we have
    $allTrips = getAllTrips();
    error_log("TRIP DETAILS DEBUG: Total trips in system: " . count($allTrips));
    
    // Check if trip exists in all trips
    if (isset($allTrips[$tripId])) {
        error_log("TRIP DETAILS DEBUG: Found trip in getAllTrips array!");
        $trip = $allTrips[$tripId];
    } else {
        // Try to find by case-insensitive match
        foreach ($allTrips as $id => $tripDataCandidate) {
            if (strcasecmp($id, $tripId) === 0) {
                error_log("TRIP DETAILS DEBUG: Found case-insensitive match: $id");
                $tripId = $id; // Update tripId to the correct case
                $trip = $tripDataCandidate;
                break;
            }
        }
        
        // If still not found, try partial match
        if (!$trip) {
            foreach ($allTrips as $id => $tripDataCandidate) {
                if (strpos($id, $tripId) !== false || strpos($tripId, $id) !== false) {
                    error_log("TRIP DETAILS DEBUG: Found partial match: $id");
                    $tripId = $id; // Update tripId to the correct case
                    $trip = $tripDataCandidate;
                    break;
                }
            }
        }
    }
}

// Final check if trip was found
if (!$trip || !is_array($trip) || empty($trip)) {
    error_log("TRIP DETAILS DEBUG: Trip still not found after all attempts");
    echo "<script>
            alert('Trip not found with ID: " . addslashes($tripId) . "\\n\\nPlease check the trip ID and try again.');
            window.location.href = 'trips.php';
          </script>";
    exit();
}

// Format trip data from helper
$tripData = formatTripData($trip, $tripId);

if (isTodaScopedAdmin()) {
    requireTodaAccess(getTripTodaId($trip));
}

// Ensure required keys exist with sensible defaults to avoid undefined index warnings
$tripDataDefaults = [
    'passengerName'      => 'Unknown Passenger',
    'passengerPhone'     => 'N/A',
    'driverName'         => 'Unknown Driver',
    'driverPhone'        => 'N/A',
    'originAddress'      => 'N/A',
    'destinationAddress' => 'N/A',
    'formattedTime'      => 'N/A',
    'fare'               => '₱0.00',
    'fareAmount'         => 0,
    'statusClass'        => 'status-unknown',
    'statusText'         => 'Unknown',
    'status'             => 'unknown',
    'passengerCount'     => 1,
    'rideSharing'        => 'No',
    'tripDuration'       => 'N/A',
    'vehicleDetails'     => 'N/A',
    'paymentCompleted'   => 'No',
    'isRated'            => false,
    'rating'             => 0,
];

if (!is_array($tripData)) {
    $tripData = [];
}
$tripData = array_merge($tripDataDefaults, $tripData);

// Debug: Check what data we have
error_log("Trip details for ID: $tripId - Data: " . print_r($trip, true));

// Get driver and commuter details with better matching
$driver   = null;
$commuter = null;

// Method 1: Try to find driver by phone (most reliable)
if (!empty($tripData['driverPhone']) && $tripData['driverPhone'] !== 'N/A') {
    $allDrivers = getAllDrivers();
    foreach ($allDrivers as $driverId => $driverData) {
        if (is_array($driverData)) {
            $driverPhone = $driverData['phone'] ?? '';
            if (!empty($driverPhone) && $driverPhone === $tripData['driverPhone']) {
                $driver        = $driverData;
                $driver['id']  = $driverId;
                break;
            }
        }
    }
}

// Method 2: Try to find driver by name if phone match failed
if (!$driver && !empty($tripData['driverName']) && $tripData['driverName'] !== 'Unknown Driver') {
    $allDrivers = getAllDrivers();
    foreach ($allDrivers as $driverId => $driverData) {
        if (is_array($driverData)) {
            $driverName = $driverData['name'] ?? '';
            if (!empty($driverName) && stripos($tripData['driverName'], $driverName) !== false) {
                $driver       = $driverData;
                $driver['id'] = $driverId;
                break;
            }
        }
    }
}

// Try to find commuter by phone
if (!empty($tripData['passengerPhone']) && $tripData['passengerPhone'] !== 'N/A') {
    $allUsers = getAllUsers(); // Use getAllUsers instead of getAllCommuters for broader search
    if (is_array($allUsers)) {
        foreach ($allUsers as $userId => $userData) {
            if (is_array($userData)) {
                $userPhone = $userData['phone'] ?? '';
                if (!empty($userPhone) && $userPhone === $tripData['passengerPhone']) {
                    $commuter       = $userData;
                    $commuter['id'] = $userId;
                    break;
                }
            }
        }
    }
}

// Format timestamps with better handling
function formatDetailTime($timestamp) {
    if (empty($timestamp) || $timestamp === 'N/A') {
        return 'N/A';
    }
    
    // If it's already a formatted string, return it
    if (is_string($timestamp) && !is_numeric($timestamp)) {
        if (preg_match('/^\d{4}-\d{2}-\d{2}/', $timestamp)) {
            // It's already in date format
            try {
                $date = new DateTime($timestamp);
                return $date->format('F j, Y h:i:s A');
            } catch (Exception $e) {
                return $timestamp;
            }
        }
        return $timestamp;
    }
    
    // Convert to integer safely
    $timestamp = (int)$timestamp;
    
    // Check if timestamp is in milliseconds
    if ($timestamp > 1000000000000) {
        $timestamp = (int)($timestamp / 1000);
    }
    
    // Check if timestamp is valid (not 0 or negative)
    if ($timestamp <= 0) {
        return 'N/A';
    }
    
    return date('F j, Y h:i:s A', $timestamp);
}

// Format timestamps from trip data / raw trip
$timeFields     = ['time', 'timestamp', 'createdAt', 'accepted_at', 'completed_at', 'lastUpdated', 'startTime', 'endTime'];
$formattedTimes = [];

foreach ($timeFields as $field) {
    $value                 = $trip[$field] ?? '';
    $formattedTimes[$field] = formatDetailTime($value);
}

// Set main timestamps
$createdAt   = $formattedTimes['time']        ?? $formattedTimes['timestamp'] ?? $formattedTimes['createdAt'] ?? 'N/A';
$acceptedAt  = $formattedTimes['accepted_at'] ?? 'N/A';
$completedAt = $formattedTimes['completed_at'] ?? $formattedTimes['endTime'] ?? 'N/A';
$updatedAt   = $formattedTimes['lastUpdated'] ?? 'N/A';

// Get additional trip data with defaults
$addons   = $trip['addons']        ?? $trip['addOns']         ?? 'None';
$discount = $trip['discount']      ?? $trip['discountAmount'] ?? 'None';
$rating   = $trip['rating']        ?? $trip['driverRating']   ?? $trip['passengerRating'] ?? $tripData['rating'] ?? 0;
$comments = $trip['comments']      ?? $trip['adminNote']      ?? $trip['note'] ?? $trip['notes'] ?? '';

// Calculate trip duration (safe)
$tripDuration = $tripData['tripDuration'] ?? 'N/A';

// Get location coordinates
$originCoords      = is_array($trip['origin']      ?? null) ? $trip['origin']      : [];
$destinationCoords = is_array($trip['destination'] ?? null) ? $trip['destination'] : [];

// Check if trip was created by admin
$isAdminCreated = isset($trip['adminCreated']) && ($trip['adminCreated'] === true || strtolower((string)$trip['adminCreated']) === 'true');
$createdBy      = $trip['adminCreatedBy'] ?? ($trip['adminUpdatedBy'] ?? 'System');

// Get vehicle details (safe)
$vehicleDetails = $tripData['vehicleDetails'] ?? 'N/A';
if ($vehicleDetails === 'N/A') {
    // Try alternative field names
    $vehicleDetails = $trip['vehicle'] ?? $trip['vehicleType'] ?? $trip['vehicle_model'] ?? 'N/A';
}

// Get payment status (safe)
$paymentCompleted = $tripData['paymentCompleted'] ?? 'No';
if ($paymentCompleted === 'No') {
    // Try alternative field names
    $paymentStatus = $trip['paymentStatus'] ?? $trip['payment'] ?? '';
    if (!empty($paymentStatus)) {
        $paymentCompleted = (strtolower((string)$paymentStatus) === 'completed' || $paymentStatus === true || $paymentStatus === 'true') ? 'Yes' : 'No';
    }
}

// Safe passenger count
$passengerCount = $tripData['passengerCount'] ?? ($trip['passengerCount'] ?? ($trip['pax'] ?? 1));
if (!is_numeric($passengerCount) || (int)$passengerCount < 1) {
    $passengerCount = 1;
} else {
    $passengerCount = (int)$passengerCount;
}

// Safe ridesharing flag
$rideSharingRaw = $tripData['rideSharing'] ?? ($trip['rideSharing'] ?? ($trip['isRideshare'] ?? 'No'));
$rideSharing    = in_array(strtolower((string)$rideSharingRaw), ['yes', 'true', '1', 'enabled', 'rideshare'], true)
    ? 'Yes'
    : 'No';

// Make sure status fields are set
$tripData['statusClass'] = $tripData['statusClass'] ?? 'status-unknown';
$tripData['statusText']  = $tripData['statusText']  ?? 'Unknown';
$tripData['status']      = $tripData['status']      ?? 'unknown';

// Normalize rating values in $tripData so rating UI uses consistent value
$tripData['rating']  = (float)$rating;
$tripData['isRated'] = $tripData['isRated'] ?? ($tripData['rating'] > 0);

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trip Details - Kaltrike Admin</title>
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
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
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
        
        .header-actions {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .btn {
            padding: 10px 20px;
            border-radius: 6px;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
            border: none;
        }
        
        .btn-back {
            background: #3498db;
            color: white;
        }
        
        .btn-back:hover {
            background: #2980b9;
            transform: translateY(-2px);
        }
        
        .btn-print {
            background: #27ae60;
            color: white;
        }
        
        .btn-print:hover {
            background: #219653;
            transform: translateY(-2px);
        }
        
        .btn-edit {
            background: #f39c12;
            color: white;
        }
        
        .btn-edit:hover {
            background: #d68910;
            transform: translateY(-2px);
        }
        
        .btn-delete {
            background: #e74c3c;
            color: white;
        }
        
        .btn-delete:hover {
            background: #c0392b;
            transform: translateY(-2px);
        }
        
        .details-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 30px;
            margin-bottom: 30px;
        }
        
        @media (max-width: 992px) {
            .details-grid {
                grid-template-columns: 1fr;
            }
        }
        
        .main-details {
            display: flex;
            flex-direction: column;
            gap: 30px;
        }
        
        .card {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
        }
        
        .trip-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 20px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .trip-id {
            font-family: 'Courier New', monospace;
            font-size: 18px;
            color: #7f8c8d;
            background: #f8f9fa;
            padding: 10px 15px;
            border-radius: 6px;
            word-break: break-all;
        }
        
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
            background-color: #fdecea;
            color: #e74c3c;
        }
        
        .status-unknown {
            background-color: #e0e0e0;
            color: #7f8c8d;
        }
        
        .section-title {
            color: #2c3e50;
            margin-bottom: 20px;
            font-size: 20px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .info-item {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        
        .info-label {
            color: #7f8c8d;
            font-size: 14px;
            margin-bottom: 8px;
            display: block;
            font-weight: 600;
        }
        
        .info-value {
            color: #2c3e50;
            font-weight: 600;
            font-size: 16px;
        }
        
        .info-value-large {
            font-size: 24px;
            color: #2c3e50;
            font-weight: 700;
        }
        
        .fare-amount {
            font-size: 36px;
            font-weight: bold;
            color: #27ae60;
            text-align: center;
            margin: 20px 0;
        }
        
        .route-visual {
            display: flex;
            align-items: center;
            gap: 20px;
            margin-top: 20px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
        }
        
        .route-step {
            display: flex;
            align-items: center;
            gap: 15px;
            flex: 1;
        }
        
        .route-icon {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: #3498db;
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            flex-shrink: 0;
        }
        
        .route-details {
            flex: 1;
        }
        
        .route-title {
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        
        .route-address {
            color: #7f8c8d;
            font-size: 14px;
        }
        
        .route-line {
            width: 40px;
            height: 2px;
            background: #3498db;
            opacity: 0.5;
        }
        
        .user-card {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 30px;
        }
        
        .user-header {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 1px solid #eee;
        }
        
        .user-avatar {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 24px;
        }
        
        .user-info h3 {
            color: #2c3e50;
            margin-bottom: 5px;
            font-size: 18px;
        }
        
        .user-info p {
            color: #7f8c8d;
            font-size: 14px;
        }
        
        .user-details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .user-detail-item {
            padding: 15px;
            background: #f8f9fa;
            border-radius: 6px;
        }
        
        .user-detail-label {
            color: #7f8c8d;
            font-size: 12px;
            margin-bottom: 5px;
            display: block;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .user-detail-value {
            color: #2c3e50;
            font-weight: 600;
            font-size: 14px;
        }
        
        .rating-stars {
            font-size: 20px;
            color: #f39c12;
            margin: 10px 0;
        }
        
        .admin-badge {
            background: #9b59b6;
            color: white;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            display: inline-block;
            margin-left: 10px;
        }
        
        .coordinate-box {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 6px;
            font-family: 'Courier New', monospace;
            font-size: 12px;
            color: #7f8c8d;
            margin-top: 10px;
        }
        
        .footer-info {
            color: #7f8c8d;
            font-size: 14px;
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
        
        /* Responsive Design */
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .header-actions {
                width: 100%;
                justify-content: space-between;
            }
            
            .btn {
                flex: 1;
                min-width: 120px;
                justify-content: center;
            }
            
            .trip-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .route-visual {
                flex-direction: column;
                gap: 15px;
            }
            
            .route-line {
                width: 2px;
                height: 30px;
            }
        }
        
        /* Print Styles */
        @media print {
            body {
                background: white;
                font-size: 12px;
            }
            
            .header-actions,
            .btn-print,
            .btn-edit,
            .btn-delete {
                display: none !important;
            }
            
            .card, .user-card {
                box-shadow: none;
                border: 1px solid #ddd;
                padding: 15px;
                margin-bottom: 15px;
            }
            
            .btn-back {
                display: none;
            }
            
            .container {
                max-width: 100%;
                padding: 10px;
                margin: 0;
            }
            
            .details-grid {
                grid-template-columns: 1fr;
                gap: 15px;
            }
            
            .fare-amount {
                font-size: 24px;
            }
            
            .section-title i {
                display: none;
            }
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1><i class="fas fa-car"></i> Trip Complete Details</h1>
            <div class="header-actions">
                <a href="trips.php" class="btn btn-back">
                    <i class="fas fa-arrow-left"></i> Back to Trips
                </a>
                <a href="edit_trip.php?id=<?php echo urlencode($tripId); ?>" class="btn btn-edit">
                    <i class="fas fa-edit"></i> Edit Trip
                </a>
                <button class="btn btn-delete" onclick="deleteTrip(<?php echo htmlspecialchars(json_encode($tripId), ENT_QUOTES, 'UTF-8'); ?>)">
                    <i class="fas fa-trash"></i> Delete Trip
                </button>
                <button class="btn btn-print" onclick="window.print()">
                    <i class="fas fa-print"></i> Print Details
                </button>
            </div>
        </div>
        
        <div class="details-grid">
            <!-- Main Trip Details -->
            <div class="main-details">
                <!-- Trip Overview Card -->
                <div class="card">
                    <div class="trip-header">
                        <div>
                            <div class="trip-id" title="Click to copy" onclick="copyTripId()">TRIP ID: <?php echo htmlspecialchars($tripId, ENT_QUOTES, 'UTF-8'); ?></div>
                            <?php if ($isAdminCreated): ?>
                            <div style="margin-top: 10px; font-size: 14px; color: #9b59b6;">
                                <i class="fas fa-user-shield"></i> Created by Admin: <?php echo htmlspecialchars($createdBy, ENT_QUOTES, 'UTF-8'); ?>
                            </div>
                            <?php endif; ?>
                        </div>
                        <div class="status-badge <?php echo htmlspecialchars($tripData['statusClass'], ENT_QUOTES, 'UTF-8'); ?>">
                            <?php echo htmlspecialchars($tripData['statusText'], ENT_QUOTES, 'UTF-8'); ?>
                        </div>
                    </div>
                    
                    <div class="fare-amount">
                        ₱<?php echo number_format((float)$tripData['fareAmount'], 2); ?>
                    </div>
                    
                    <div class="info-grid">
                        <div class="info-item">
                            <span class="info-label">Created At</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$createdAt, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        
                        <?php if ($acceptedAt !== 'N/A'): ?>
                        <div class="info-item">
                            <span class="info-label">Accepted At</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$acceptedAt, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <?php if ($completedAt !== 'N/A'): ?>
                        <div class="info-item">
                            <span class="info-label">Completed At</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$completedAt, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <?php if ($tripDuration !== 'N/A'): ?>
                        <div class="info-item">
                            <span class="info-label">Trip Duration</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$tripDuration, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <div class="info-item">
                            <span class="info-label">Passenger Count</span>
                            <span class="info-value">
                                <?php echo htmlspecialchars((string)$passengerCount, ENT_QUOTES, 'UTF-8'); ?> 
                                <?php if ($rideSharing === 'Yes'): ?>
                                <span class="admin-badge">Ridesharing</span>
                                <?php endif; ?>
                            </span>
                        </div>
                        
                        <div class="info-item">
                            <span class="info-label">Payment Status</span>
                            <span class="info-value">
                                <?php echo $paymentCompleted === 'Yes' ? 
                                    '<span style="color: #27ae60;">Completed</span>' : 
                                    '<span style="color: #e74c3c;">Pending</span>'; ?>
                            </span>
                        </div>
                    </div>
                    
                    <!-- Route Information -->
                    <h3 class="section-title"><i class="fas fa-route"></i> Route Information</h3>
                    <div class="route-visual">
                        <div class="route-step">
                            <div class="route-icon">
                                <i class="fas fa-map-marker-alt"></i>
                            </div>
                            <div class="route-details">
                                <div class="route-title">Pickup Location</div>
                                <div class="route-address"><?php echo htmlspecialchars((string)$tripData['originAddress'], ENT_QUOTES, 'UTF-8'); ?></div>
                                <?php if (!empty($originCoords)): ?>
                                <div class="coordinate-box">
                                    <?php 
                                    $lat = $originCoords['latitude'] ?? $originCoords['lat'] ?? 'N/A';
                                    $lng = $originCoords['longitude'] ?? $originCoords['lng'] ?? 'N/A';
                                    ?>
                                    Lat: <?php echo htmlspecialchars((string)$lat, ENT_QUOTES, 'UTF-8'); ?>, 
                                    Lng: <?php echo htmlspecialchars((string)$lng, ENT_QUOTES, 'UTF-8'); ?>
                                </div>
                                <?php endif; ?>
                            </div>
                        </div>
                        
                        <div class="route-line"></div>
                        
                        <div class="route-step">
                            <div class="route-icon">
                                <i class="fas fa-flag-checkered"></i>
                            </div>
                            <div class="route-details">
                                <div class="route-title">Destination</div>
                                <div class="route-address"><?php echo htmlspecialchars((string)$tripData['destinationAddress'], ENT_QUOTES, 'UTF-8'); ?></div>
                                <?php if (!empty($destinationCoords)): ?>
                                <div class="coordinate-box">
                                    <?php 
                                    $lat = $destinationCoords['latitude'] ?? $destinationCoords['lat'] ?? 'N/A';
                                    $lng = $destinationCoords['longitude'] ?? $destinationCoords['lng'] ?? 'N/A';
                                    ?>
                                    Lat: <?php echo htmlspecialchars((string)$lat, ENT_QUOTES, 'UTF-8'); ?>, 
                                    Lng: <?php echo htmlspecialchars((string)$lng, ENT_QUOTES, 'UTF-8'); ?>
                                </div>
                                <?php endif; ?>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Additional Information -->
                    <h3 class="section-title"><i class="fas fa-info-circle"></i> Additional Information</h3>
                    <div class="info-grid">
                        <?php if ($addons !== 'None'): ?>
                        <div class="info-item">
                            <span class="info-label">Add-ons</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$addons, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <?php if ($discount !== 'None'): ?>
                        <div class="info-item">
                            <span class="info-label">Discount</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$discount, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <?php if ($vehicleDetails !== 'N/A'): ?>
                        <div class="info-item">
                            <span class="info-label">Vehicle Details</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$vehicleDetails, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <?php if ($updatedAt !== 'N/A'): ?>
                        <div class="info-item">
                            <span class="info-label">Last Updated</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$updatedAt, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                    </div>
                    
                    <?php if (!empty($comments)): ?>
                    <div class="info-item" style="margin-top: 20px;">
                        <span class="info-label">Comments/Notes</span>
                        <div style="background: #f8f9fa; padding: 15px; border-radius: 6px; margin-top: 10px; white-space: pre-line;">
                            <?php echo nl2br(htmlspecialchars((string)$comments, ENT_QUOTES, 'UTF-8')); ?>
                        </div>
                    </div>
                    <?php endif; ?>
                </div>
                
                <!-- Driver Information Card -->
                <?php if ($driver): ?>
                <div class="user-card">
                    <div class="user-header">
                        <div class="user-avatar">
                            <?php echo strtoupper(substr($driver['name'] ?? 'D', 0, 1)); ?>
                        </div>
                        <div class="user-info">
                            <h3><?php echo htmlspecialchars($driver['name'] ?? 'Unknown Driver', ENT_QUOTES, 'UTF-8'); ?></h3>
                            <p><i class="fas fa-id-card"></i> Driver ID: <?php echo htmlspecialchars($driver['id'] ?? 'N/A', ENT_QUOTES, 'UTF-8'); ?></p>
                        </div>
                    </div>
                    
                    <div class="user-details">
                        <div class="user-detail-item">
                            <span class="user-detail-label">Phone</span>
                            <span class="user-detail-value"><?php echo htmlspecialchars($driver['phone'] ?? 'N/A', ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        
                        <?php if (!empty($driver['email'])): ?>
                        <div class="user-detail-item">
                            <span class="user-detail-label">Email</span>
                            <span class="user-detail-value"><?php echo htmlspecialchars($driver['email'], ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <?php if (!empty($driver['permitNumber'])): ?>
                        <div class="user-detail-item">
                            <span class="user-detail-label">Permit Number</span>
                            <span class="user-detail-value"><?php echo htmlspecialchars($driver['permitNumber'], ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <?php if (!empty($driver['plateNumber'])): ?>
                        <div class="user-detail-item">
                            <span class="user-detail-label">Plate Number</span>
                            <span class="user-detail-value"><?php echo htmlspecialchars($driver['plateNumber'], ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <div class="user-detail-item">
                            <span class="user-detail-label">Status</span>
                            <span class="user-detail-value">
                                <?php 
                                $driverStatus      = $driver['accountStatus'] ?? ($driver['status'] ?? 'unknown');
                                $driverStatusClass = 'status-unknown';
                                switch (strtolower((string)$driverStatus)) {
                                    case 'active':
                                    case 'validated':
                                        $driverStatusClass = 'status-completed';
                                        break;
                                    case 'pending':
                                        $driverStatusClass = 'status-pending';
                                        break;
                                    case 'inactive':
                                        $driverStatusClass = 'status-cancelled';
                                        break;
                                }
                                ?>
                                <span class="status-badge <?php echo $driverStatusClass; ?>" style="font-size: 11px;">
                                    <?php echo ucfirst((string)$driverStatus); ?>
                                </span>
                            </span>
                        </div>
                        
                        <?php if (isset($driver['earnings'])): ?>
                        <div class="user-detail-item">
                            <span class="user-detail-label">Earnings</span>
                            <span class="user-detail-value">₱<?php echo number_format((float)$driver['earnings'], 2); ?></span>
                        </div>
                        <?php endif; ?>
                    </div>
                    
                    <div style="text-align: center; margin-top: 20px;">
                        <a href="driver_details.php?id=<?php echo urlencode($driver['id']); ?>" class="btn" style="background: #3498db; color: white; display: inline-flex;">
                            <i class="fas fa-external-link-alt"></i> View Driver Profile
                        </a>
                    </div>
                </div>
                <?php endif; ?>
            </div>
            
            <!-- Sidebar Information -->
            <div>
                <!-- Passenger Information Card -->
                <div class="user-card">
                    <div class="user-header">
                        <div class="user-avatar">
                            <?php echo strtoupper(substr($tripData['passengerName'], 0, 1)); ?>
                        </div>
                        <div class="user-info">
                            <h3><?php echo htmlspecialchars($tripData['passengerName'], ENT_QUOTES, 'UTF-8'); ?></h3>
                            <p><i class="fas fa-user"></i> Passenger</p>
                        </div>
                    </div>
                    
                    <div class="user-details">
                        <div class="user-detail-item">
                            <span class="user-detail-label">Phone</span>
                            <span class="user-detail-value"><?php echo htmlspecialchars($tripData['passengerPhone'], ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        
                        <?php if ($commuter && !empty($commuter['email'])): ?>
                        <div class="user-detail-item">
                            <span class="user-detail-label">Email</span>
                            <span class="user-detail-value"><?php echo htmlspecialchars($commuter['email'], ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <?php if ($commuter): ?>
                        <div class="user-detail-item">
                            <span class="user-detail-label">User ID</span>
                            <span class="user-detail-value" style="font-size: 11px; font-family: monospace;">
                                <?php echo htmlspecialchars($commuter['id'] ?? 'N/A', ENT_QUOTES, 'UTF-8'); ?>
                            </span>
                        </div>
                        
                        <?php if (isset($commuter['createdAt'])): ?>
                        <div class="user-detail-item">
                            <span class="user-detail-label">Member Since</span>
                            <span class="user-detail-value">
                                <?php 
                                $memberSince = $commuter['createdAt'];
                                if ($memberSince > 0) {
                                    $timestampMember = ($memberSince > 1000000000000) ? (int)($memberSince / 1000) : (int)$memberSince;
                                    echo date('M Y', $timestampMember);
                                } else {
                                    echo 'N/A';
                                }
                                ?>
                            </span>
                        </div>
                        <?php endif; ?>
                        <?php endif; ?>
                    </div>
                    
                    <!-- Rating -->
                    <?php if (!empty($tripData['isRated'])): ?>
                    <div style="text-align: center; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee;">
                        <div class="user-detail-label">Passenger Rating</div>
                        <div class="rating-stars">
                            <?php
                            $ratingValue  = (float)$tripData['rating'];
                            $fullStars    = floor($ratingValue);
                            $hasHalfStar  = ($ratingValue - $fullStars) >= 0.5;
                            
                            for ($i = 1; $i <= 5; $i++) {
                                if ($i <= $fullStars) {
                                    echo '<i class="fas fa-star"></i>';
                                } elseif ($hasHalfStar && $i == $fullStars + 1) {
                                    echo '<i class="fas fa-star-half-alt"></i>';
                                } else {
                                    echo '<i class="far fa-star"></i>';
                                }
                            }
                            ?>
                        </div>
                        <div style="font-weight: 600; color: #2c3e50; font-size: 18px;">
                            <?php echo number_format($ratingValue, 1); ?>/5
                        </div>
                    </div>
                    <?php endif; ?>
                    
                    <?php if ($commuter): ?>
                    <div style="text-align: center; margin-top: 20px;">
                        <a href="commuter_details.php?id=<?php echo urlencode($commuter['id']); ?>" class="btn" style="background: #9b59b6; color: white; display: inline-flex;">
                            <i class="fas fa-external-link-alt"></i> View Commuter Profile
                        </a>
                    </div>
                    <?php endif; ?>
                </div>
                
                <!-- Trip Statistics Card -->
                <div class="card">
                    <h3 class="section-title"><i class="fas fa-chart-bar"></i> Trip Statistics</h3>
                    
                    <div class="info-grid" style="grid-template-columns: 1fr;">
                        <div class="info-item">
                            <span class="info-label">Base Fare</span>
                            <span class="info-value-large">₱<?php echo number_format((float)$tripData['fareAmount'], 2); ?></span>
                        </div>
                        
                        <div class="info-item">
                            <span class="info-label">Passenger Type</span>
                            <span class="info-value">
                                <?php echo $rideSharing === 'Yes' ? 'Ridesharing' : 'Regular'; ?>
                            </span>
                        </div>
                        
                        <?php if ($vehicleDetails !== 'N/A'): ?>
                        <div class="info-item">
                            <span class="info-label">Vehicle Type</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$vehicleDetails, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                        
                        <div class="info-item">
                            <span class="info-label">Trip Status</span>
                            <span class="info-value">
                                <span class="status-badge <?php echo htmlspecialchars($tripData['statusClass'], ENT_QUOTES, 'UTF-8'); ?>">
                                    <?php echo htmlspecialchars($tripData['statusText'], ENT_QUOTES, 'UTF-8'); ?>
                                </span>
                            </span>
                        </div>
                        
                        <?php if ($tripDuration !== 'N/A'): ?>
                        <div class="info-item">
                            <span class="info-label">Trip Duration</span>
                            <span class="info-value"><?php echo htmlspecialchars((string)$tripDuration, ENT_QUOTES, 'UTF-8'); ?></span>
                        </div>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="footer-info">
            <i class="fas fa-clock"></i> Printed on <?php echo date('F j, Y h:i:s A'); ?> |
            <i class="fas fa-user-shield"></i> Kaltrike Admin System v2.0
        </div>
    </div>
    
    <script>
    // Delete trip function
    function deleteTrip(tripId) {
        if (confirm('⚠️ WARNING: Are you sure you want to delete this trip?\n\nThis action cannot be undone and will permanently remove all trip data.')) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = 'trips.php';
            
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
    
    // Copy trip ID to clipboard
    function copyTripId() {
        const tripId = <?php echo json_encode($tripId); ?>;
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(tripId).then(() => {
                showNotification('Trip ID copied to clipboard!', 'success');
            }).catch(err => {
                console.error('Failed to copy: ', err);
                // Fallback for older browsers
                copyToClipboardFallback(tripId);
            });
        } else {
            // Fallback for older browsers
            copyToClipboardFallback(tripId);
        }
    }
    
    // Fallback copy method for older browsers
    function copyToClipboardFallback(text) {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.top = '0';
        textArea.style.left = '0';
        textArea.style.opacity = '0';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        
        try {
            const successful = document.execCommand('copy');
            if (successful) {
                showNotification('Trip ID copied to clipboard!', 'success');
            } else {
                showNotification('Failed to copy ID. Please copy manually.', 'error');
            }
        } catch (err) {
            console.error('Fallback copy failed:', err);
            showNotification('Failed to copy ID. Please copy manually.', 'error');
        }
        
        document.body.removeChild(textArea);
    }
    
    // Show notification
    function showNotification(message, type) {
        // Remove existing notifications
        document.querySelectorAll('.alert-message').forEach(el => el.remove());
        
        const notification = document.createElement('div');
        notification.className = `alert-message alert-${type}`;
        notification.innerHTML = `
            <i class="fas fa-${type === 'success' ? 'check' : 'exclamation'}-circle"></i>
            <span>${message}</span>
        `;
        notification.style.position = 'fixed';
        notification.style.top = '20px';
        notification.style.right = '20px';
        notification.style.zIndex = '9999';
        notification.style.maxWidth = '400px';
        notification.style.padding = '15px 20px';
        notification.style.borderRadius = '8px';
        notification.style.color = 'white';
        notification.style.fontWeight = '600';
        notification.style.boxShadow = '0 5px 15px rgba(0,0,0,0.2)';
        notification.style.background = type === 'success' ? 
            'linear-gradient(135deg, #27ae60 0%, #219653 100%)' :
            'linear-gradient(135deg, #e74c3c 0%, #c0392b 100%)';
        
        // Add animation
        notification.style.animation = 'slideInMessage 0.3s ease-out';
        
        // Add animation keyframes if not exists
        if (!document.getElementById('animation-styles')) {
            const style = document.createElement('style');
            style.id = 'animation-styles';
            style.textContent = `
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
            `;
            document.head.appendChild(style);
        }
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transition = 'opacity 0.5s';
            setTimeout(() => {
                if (notification.parentNode) {
                    document.body.removeChild(notification);
                }
            }, 500);
        }, 3000);
    }
    
    // Setup on page load
    document.addEventListener('DOMContentLoaded', function() {
        // Add click event to copy trip ID
        const tripIdElement = document.querySelector('.trip-id');
        if (tripIdElement) {
            tripIdElement.style.cursor = 'pointer';
            tripIdElement.title = 'Click to copy Trip ID';
            tripIdElement.addEventListener('click', copyTripId);
        }
        
        // Add keyboard shortcut for printing (Ctrl + P)
        document.addEventListener('keydown', function(e) {
            if ((e.ctrlKey || e.metaKey) && e.key === 'p') {
                e.preventDefault();
                window.print();
            }
        });
        
        // Add keyboard shortcut for going back (Esc)
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                window.location.href = 'trips.php';
            }
        });
        
        // Add keyboard shortcut for edit (Ctrl + E)
        document.addEventListener('keydown', function(e) {
            if ((e.ctrlKey || e.metaKey) && e.key === 'e') {
                e.preventDefault();
                window.location.href = 'edit_trip.php?id=<?php echo urlencode($tripId); ?>';
            }
        });
    });
    
    // Error handling for missing data
    window.addEventListener('error', function(e) {
        console.error('Page error:', e);
        showNotification('An error occurred while loading trip details', 'error');
    });
    </script>
</body>
</html>
