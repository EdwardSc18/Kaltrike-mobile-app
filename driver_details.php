<?php
// driver_details.php - Driver Complete Details View
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_DRIVERS_VIEW);

$driverId = $_GET['id'] ?? '';
$driver = getDriverById($driverId);

if (!$driver) {
    header('Location: ' . getDriversRouteForCurrentUser());
    exit();
}

if (isTodaScopedAdmin()) {
    requireTodaAccess($driver['todaId'] ?? null);
}

// Format vehicle details
$vehicleDetails = [
    'plateNumber' => $driver['vechicle_details']['plate_number'] ?? $driver['plateNumber'] ?? 'N/A',
    'vehicleType' => $driver['vechicle_details']['type'] ?? $driver['vehicleType'] ?? 'N/A',
    'vehicleColor' => $driver['vechicle_details']['vehicle_color'] ?? $driver['vehicleColor'] ?? 'N/A',
    'vehicleModel' => $driver['vechicle_details']['vehicle_model'] ?? $driver['vehicleModel'] ?? 'N/A',
    'vehiclePermit' => $driver['vechicle_details']['vehicle_permit'] ?? $driver['vehiclePermitNumber'] ?? 'N/A'
];

// Format dates - FIXED: Use proper type casting
$accountCreated = 'N/A';
if (isset($driver['createdAt'])) {
    // Convert to integer to avoid float precision issues
    $timestamp = is_numeric($driver['createdAt']) ? (int)$driver['createdAt'] : 0;
    // Check if it's in milliseconds and convert to seconds
    if ($timestamp > 10000000000) { // If it's likely in milliseconds (after year 2286)
        $timestamp = intval($timestamp / 1000);
    }
    $accountCreated = date('m/d/Y h:i:s A', $timestamp);
} elseif (isset($driver['accountCreated'])) {
    $accountCreated = htmlspecialchars($driver['accountCreated']);
}

$lastUpdated = 'N/A';
if (isset($driver['lastUpdated'])) {
    // Convert to integer to avoid float precision issues
    $timestamp = is_numeric($driver['lastUpdated']) ? (int)$driver['lastUpdated'] : 0;
    // Check if it's in milliseconds and convert to seconds
    if ($timestamp > 10000000000) { // If it's likely in milliseconds (after year 2286)
        $timestamp = intval($timestamp / 1000);
    }
    $lastUpdated = date('m/d/Y h:i:s A', $timestamp);
} elseif (isset($driver['lastUpdatedAt'])) {
    $lastUpdated = htmlspecialchars($driver['lastUpdatedAt']);
}

$validatedInfo = '';
if (isset($driver['validationStatus']) && $driver['validationStatus'] === 'approved') {
    $validatedDate = 'N/A';
    if (isset($driver['validatedAt'])) {
        // Convert to integer to avoid float precision issues
        $timestamp = is_numeric($driver['validatedAt']) ? (int)$driver['validatedAt'] : 0;
        // Check if it's in milliseconds and convert to seconds
        if ($timestamp > 10000000000) { // If it's likely in milliseconds (after year 2286)
            $timestamp = intval($timestamp / 1000);
        }
        $validatedDate = date('m/d/Y h:i:s A', $timestamp);
    }
    $validatedBy = $driver['validatedBy'] ?? 'admin@kaltrike.com';
    $validatedInfo = "Validated: $validatedDate, By: $validatedBy, Status: approved";
}

// Get earnings with proper formatting
$earnings = 0;
if (isset($driver['earnings'])) {
    // Ensure earnings is a valid number
    $earningsValue = $driver['earnings'];
    if (is_numeric($earningsValue)) {
        $earnings = floatval($earningsValue);
    } elseif (is_string($earningsValue) && preg_match('/\d+(\.\d+)?/', $earningsValue, $matches)) {
        $earnings = floatval($matches[0]);
    }
}

// Get driver rides safely
$driverRides = [];
try {
    $driverRides = getDriverRides($driverId);
} catch (Exception $e) {
    // Log error but continue execution
    error_log("Error getting driver rides: " . $e->getMessage());
    $driverRides = [];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Driver Details - Kaltrike Admin</title>
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
            max-width: 1000px;
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
        
        .btn-validate {
            background: #f39c12;
            color: white;
        }
        
        .btn-validate:hover {
            background: #d68910;
            transform: translateY(-2px);
        }
        
        .btn-edit {
            background: #9b59b6;
            color: white;
        }
        
        .btn-edit:hover {
            background: #8e44ad;
            transform: translateY(-2px);
        }
        
        .driver-details-card {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 30px;
        }
        
        .details-title {
            color: #2c3e50;
            margin-bottom: 25px;
            padding-bottom: 15px;
            border-bottom: 2px solid #f0f0f0;
            font-size: 24px;
            font-weight: 600;
            text-align: center;
        }
        
        .section {
            margin-bottom: 30px;
        }
        
        .section-title {
            color: #2c3e50;
            margin-bottom: 15px;
            font-size: 18px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        
        .info-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        
        .info-label {
            color: #7f8c8d;
            font-size: 14px;
            margin-bottom: 5px;
            display: block;
        }
        
        .info-value {
            color: #2c3e50;
            font-weight: 600;
            font-size: 16px;
        }
        
        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }
        
        .status-pending {
            background-color: #fff3cd;
            color: #856404;
        }
        
        .status-active {
            background-color: #d1ecf1;
            color: #0c5460;
        }
        
        .status-validated {
            background-color: #d5f4e6;
            color: #27ae60;
        }
        
        .status-suspended {
            background-color: #f8d7da;
            color: #721c24;
        }
        
        .status-inactive {
            background-color: #e2e3e5;
            color: #383d41;
        }
        
        .divider {
            height: 1px;
            background: #e0e0e0;
            margin: 30px 0;
        }
        
        .footer-info {
            color: #7f8c8d;
            font-size: 14px;
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
        
        /* Print-specific styles */
        @media print {
            body {
                background: white;
            }
            
            .header-actions,
            .btn-print,
            .btn-edit {
                display: none !important;
            }
            
            .driver-details-card {
                box-shadow: none;
                border: 1px solid #ddd;
            }
            
            .btn-back {
                display: none;
            }
            
            .container {
                max-width: 100%;
                padding: 10px;
            }
        }
        
        .validation-info {
            background: #e8f4fc;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
            margin-top: 15px;
        }
        
        .account-id {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            margin-top: 20px;
        }
        
        .account-id-code {
            font-family: 'Courier New', monospace;
            font-size: 18px;
            color: #2c3e50;
            letter-spacing: 2px;
            margin: 10px 0;
            word-break: break-all;
            padding: 10px;
            background: white;
            border-radius: 4px;
        }
        
        /* Driver profile section */
        .driver-profile-header {
            display: flex;
            align-items: center;
            gap: 20px;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .driver-avatar {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 40px;
            font-weight: bold;
        }
        
        .driver-profile-info {
            flex: 1;
        }
        
        .driver-name {
            font-size: 28px;
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        
        .driver-status {
            display: inline-block;
            margin-bottom: 10px;
        }
        
        /* Responsive Design */
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .header-actions {
                flex-wrap: wrap;
                width: 100%;
            }
            
            .btn {
                flex: 1;
                min-width: 120px;
                justify-content: center;
            }
            
            .driver-profile-header {
                flex-direction: column;
                text-align: center;
            }
            
            .info-grid {
                grid-template-columns: 1fr;
            }
        }
        
        /* Alert message */
        .alert-message {
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
            animation: slideIn 0.3s;
        }
        
        .alert-success {
            background-color: #d5f4e6;
            color: #27ae60;
            border-left: 4px solid #27ae60;
        }
        
        .alert-warning {
            background-color: #fff3cd;
            color: #856404;
            border-left: 4px solid #f39c12;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>
    <div class="container">
        <!-- Success Message (if any) -->
        <?php if (isset($_GET['success'])): ?>
        <div class="alert-message alert-success">
            <i class="fas fa-check-circle"></i>
            <span>
                <?php 
                $successMessages = [
                    'validated' => 'Driver validated successfully!',
                    'updated' => 'Driver information updated successfully!',
                    'added' => 'New driver added successfully!'
                ];
                echo htmlspecialchars($successMessages[$_GET['success']] ?? 'Operation completed successfully!');
                ?>
            </span>
        </div>
        <?php endif; ?>
        
        <!-- Header -->
        <div class="header">
            <h1><i class="fas fa-user-circle"></i> Driver Complete Details</h1>
            <div class="header-actions">
                <a href="<?php echo htmlspecialchars(getDriversRouteForCurrentUser()); ?>" class="btn btn-back">
                    <i class="fas fa-arrow-left"></i> Back to Drivers
                </a>
                <?php if (hasPermission(PERM_VERIFICATION_VIEW)): ?>
                <a href="driver_validation.php?id=<?php echo urlencode($driverId); ?>" 
                   class="btn btn-validate">
                    <i class="fas fa-user-check"></i> Validation Review
                </a>
                <?php endif; ?>
                <button class="btn btn-print" onclick="window.print()">
                    <i class="fas fa-print"></i> Print Details
                </button>
            </div>
        </div>
        
        <!-- Driver Profile Header -->
        <div class="driver-profile-header">
            <div class="driver-avatar">
                <?php 
                $driverName = $driver['name'] ?? 'Driver';
                echo strtoupper(substr($driverName, 0, 1)); 
                ?>
            </div>
            <div class="driver-profile-info">
                <div class="driver-name"><?php echo htmlspecialchars($driverName); ?></div>
                <div class="driver-status">
                    <span class="status-badge status-<?php echo htmlspecialchars($driver['accountStatus'] ?? 'pending'); ?>">
                        <?php echo htmlspecialchars(ucfirst($driver['accountStatus'] ?? 'pending')); ?>
                    </span>
                </div>
                <div style="color: #7f8c8d; font-size: 14px;">
                    <i class="fas fa-id-card"></i> Permit: <?php echo htmlspecialchars($driver['permitNumber'] ?? 'N/A'); ?>
                </div>
            </div>
        </div>
        
        <!-- Driver Details Card -->
        <div class="driver-details-card">
            <h2 class="details-title">Driver Information</h2>
            
            <!-- Personal Information Section -->
            <div class="section">
                <h3 class="section-title"><i class="fas fa-user"></i> Personal Information</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">Permit Number:</span>
                        <span class="info-value"><?php echo htmlspecialchars($driver['permitNumber'] ?? 'N/A'); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Email:</span>
                        <span class="info-value"><?php echo htmlspecialchars($driver['email'] ?? 'N/A'); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Full Name:</span>
                        <span class="info-value"><?php echo htmlspecialchars($driver['name'] ?? 'N/A'); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Phone:</span>
                        <span class="info-value"><?php echo htmlspecialchars($driver['phone'] ?? 'N/A'); ?></span>
                    </div>
                </div>
            </div>
            
            <div class="divider"></div>
            
            <!-- Vehicle Details Section -->
            <div class="section">
                <h3 class="section-title"><i class="fas fa-car"></i> Vehicle Details</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">Vehicle Type:</span>
                        <span class="info-value"><?php echo htmlspecialchars($vehicleDetails['vehicleType']); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Plate Number:</span>
                        <span class="info-value"><?php echo htmlspecialchars($vehicleDetails['plateNumber']); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Vehicle Model:</span>
                        <span class="info-value"><?php echo htmlspecialchars($vehicleDetails['vehicleModel']); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Vehicle Color:</span>
                        <span class="info-value"><?php echo htmlspecialchars($vehicleDetails['vehicleColor']); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Vehicle Permit Number:</span>
                        <span class="info-value"><?php echo htmlspecialchars($vehicleDetails['vehiclePermit']); ?></span>
                    </div>
                </div>
            </div>
            
            <div class="divider"></div>
            
            <!-- Account Information Section -->
            <div class="section">
                <h3 class="section-title"><i class="fas fa-user-cog"></i> Account Information</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">Account Status:</span>
                        <span class="info-value">
                            <span class="status-badge status-<?php echo htmlspecialchars($driver['accountStatus'] ?? 'pending'); ?>">
                                <?php echo htmlspecialchars(ucfirst($driver['accountStatus'] ?? 'pending')); ?>
                            </span>
                        </span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Profile Completed:</span>
                        <span class="info-value">
                            <?php echo (isset($driver['isProfileCompleted']) && $driver['isProfileCompleted']) ? 'Yes' : 'No'; ?>
                        </span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Account Created:</span>
                        <span class="info-value"><?php echo htmlspecialchars($accountCreated); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Last Updated:</span>
                        <span class="info-value"><?php echo htmlspecialchars($lastUpdated); ?></span>
                    </div>
                </div>
                
                <?php if (!empty($validatedInfo)): ?>
                <div class="validation-info">
                    <span class="info-label">Validation Info:</span><br>
                    <span class="info-value"><?php echo htmlspecialchars($validatedInfo); ?></span>
                </div>
                <?php endif; ?>
            </div>
            
            <div class="divider"></div>
            
            <!-- Additional Information Section -->
            <div class="section">
                <h3 class="section-title"><i class="fas fa-info-circle"></i> Additional Information</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">Earnings:</span>
                        <span class="info-value">₱<?php echo number_format($earnings, 2); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Ratings:</span>
                        <span class="info-value">
                            <?php 
                            $rating = $driver['ratings'] ?? 0;
                            if (is_numeric($rating)) {
                                echo number_format(floatval($rating), 1);
                            } else {
                                echo htmlspecialchars($rating);
                            }
                            ?>/5
                        </span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Total Rides:</span>
                        <span class="info-value"><?php echo count($driverRides); ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Driver Active:</span>
                        <span class="info-value">
                            <?php echo (isset($driver['isDriverActive']) && $driver['isDriverActive']) ? 'Yes' : 'No'; ?>
                        </span>
                    </div>
                </div>
            </div>
            
            <!-- Account ID Section -->
            <div class="account-id">
                <div class="info-label">Driver Account ID</div>
                <div class="account-id-code"><?php echo htmlspecialchars($driverId); ?></div>
                <small style="color: #7f8c8d;">Use this ID for reference in all communications</small>
            </div>
            
            <div class="footer-info">
                <i class="fas fa-clock"></i> Printed on <?php echo date('Y-m-d H:i:s'); ?> |
                <i class="fas fa-user-shield"></i> Kaltrike Admin System
            </div>
        </div>
    </div>
    
    <script>
    // Add print functionality with custom styling
    function setupPrintFunctionality() {
        const printBtn = document.querySelector('.btn-print');
        
        printBtn.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Open print dialog
            window.print();
        });
    }
    
    // Copy driver ID to clipboard
    function copyDriverId() {
        const driverId = "<?php echo htmlspecialchars($driverId); ?>";
        navigator.clipboard.writeText(driverId).then(() => {
            // Show temporary notification
            showNotification('Driver ID copied to clipboard!', 'success');
        }).catch(err => {
            console.error('Failed to copy: ', err);
            showNotification('Failed to copy ID', 'error');
        });
    }
    
    // Show notification
    function showNotification(message, type) {
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
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transition = 'opacity 0.5s';
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 500);
        }, 3000);
    }
    
    // Setup on page load
    document.addEventListener('DOMContentLoaded', function() {
        setupPrintFunctionality();
        
        // Add click event to copy driver ID
        const accountIdCode = document.querySelector('.account-id-code');
        if (accountIdCode) {
            accountIdCode.style.cursor = 'pointer';
            accountIdCode.title = 'Click to copy Driver ID';
            accountIdCode.addEventListener('click', copyDriverId);
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
                window.location.href = <?php echo json_encode(getDriversRouteForCurrentUser()); ?>;
            }
        });
    });
    </script>
</body>
</html>