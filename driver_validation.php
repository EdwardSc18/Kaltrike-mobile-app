<?php
// driver_validation.php - Driver Validation Review System
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_VERIFICATION_VIEW);
$canManageValidation = hasPermission(PERM_VERIFICATION_MANAGE);

$driverId = $_GET['id'] ?? '';
$driver = getDriverById($driverId);

if (!$driver) {
    header('Location: drivers.php');
    exit();
}

if (isTodaScopedAdmin()) {
    requireTodaAccess($driver['todaId'] ?? null);
}

$documents = getDriverValidationDocuments($driverId, $driver);

// Get validation data from Firebase structure
$validationData = [
    'idUrl' => $documents['idUrl'] ?? '',
    'permitUrl' => $documents['permitUrl'] ?? '',
    'selfieUrl' => $documents['selfieUrl'] ?? '',
    'validationStatus' => $driver['validationStatus'] ?? 'pending',
    'validatedBy' => $driver['validatedBy'] ?? '',
    'validatedAt' => $driver['validatedAt'] ?? '',
    'validationNotes' => $driver['validationNotes'] ?? '',
    'deadline' => $driver['validationDeadline'] ?? ''
];

// Get vehicle details from both possible Firebase structures
$vehicleDetails = [
    'plateNumber' => $driver['vechicle_details']['plate_number'] ?? $driver['plateNumber'] ?? 'N/A',
    'vehicleType' => $driver['vechicle_details']['type'] ?? $driver['vehicleType'] ?? 'N/A',
    'vehicleColor' => $driver['vechicle_details']['vehicle_color'] ?? $driver['vehicleColor'] ?? 'N/A',
    'vehicleModel' => $driver['vechicle_details']['vehicle_model'] ?? $driver['vehicleModel'] ?? 'N/A',
    'vehiclePermit' => $driver['vechicle_details']['vehicle_permit'] ?? $driver['vehiclePermitNumber'] ?? 'N/A'
];

// Handle form submissions
$message = '';
$messageType = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requirePermission(PERM_VERIFICATION_MANAGE);
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'approve':
                $validationNotes = $_POST['validationNotes'] ?? '';
                $deadline = $_POST['deadline'] ?? '';
                
                $updateData = [
                    'validationStatus' => 'approved',
                    'validatedBy' => $_SESSION['admin_username'] ?? 'admin',
                    'validatedAt' => time() * 1000, // Firebase timestamp in milliseconds
                    'accountStatus' => 'validated',
                    'status' => 'validated',
                    'isDriverActive' => !empty($driver['isDriverActive'])
                ];
                
                if (!empty($validationNotes)) {
                    $updateData['validationNotes'] = $validationNotes;
                }
                
                if (!empty($deadline)) {
                    $updateData['validationDeadline'] = $deadline;
                }
                
                if (updateDriver($driverId, $updateData)) {
                    $message = "Driver approved successfully!";
                    $messageType = 'success';
                    // Refresh driver data
                    $driver = getDriverById($driverId);
                    $validationData['validationStatus'] = 'approved';
                } else {
                    $message = "Failed to approve driver!";
                    $messageType = 'error';
                }
                break;
                
            case 'decline':
                $validationNotes = $_POST['validationNotes'] ?? '';
                
                $updateData = [
                    'validationStatus' => 'declined',
                    'validatedBy' => $_SESSION['admin_username'] ?? 'admin',
                    'validatedAt' => time() * 1000,
                    'accountStatus' => 'pending',
                    'status' => 'pending',
                    'isDriverActive' => false
                ];
                
                if (!empty($validationNotes)) {
                    $updateData['validationNotes'] = $validationNotes;
                }
                
                if (updateDriver($driverId, $updateData)) {
                    $message = "Driver declined successfully!";
                    $messageType = 'success';
                    // Refresh driver data
                    $driver = getDriverById($driverId);
                    $validationData['validationStatus'] = 'declined';
                } else {
                    $message = "Failed to decline driver!";
                    $messageType = 'error';
                }
                break;
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Driver Validation - Kaltrike Admin</title>
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
        
        .validation-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-bottom: 30px;
        }
        
        @media (max-width: 992px) {
            .validation-grid {
                grid-template-columns: 1fr;
            }
        }
        
        .validation-section {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
        }
        
        .section-title {
            color: #2c3e50;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #f0f0f0;
            font-size: 18px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .documents-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
        }
        
        .document-card {
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            transition: all 0.3s;
        }
        
        .document-card:hover {
            border-color: #3498db;
            transform: translateY(-2px);
        }
        
        .document-icon {
            font-size: 40px;
            color: #3498db;
            margin-bottom: 15px;
        }
        
        .document-title {
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 10px;
        }
        
        .document-actions {
            margin-top: 15px;
        }
        
        .view-btn {
            background: #3498db;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            text-decoration: none;
        }
        
        .view-btn:hover {
            background: #2980b9;
        }
        
        .vehicle-details {
            margin-top: 20px;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #eee;
        }
        
        .detail-label {
            color: #7f8c8d;
            font-weight: 600;
        }
        
        .detail-value {
            color: #2c3e50;
            font-weight: 500;
        }
        
        .validation-notes {
            margin-top: 20px;
        }
        
        .notes-textarea {
            width: 100%;
            padding: 15px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 14px;
            min-height: 120px;
            margin-bottom: 15px;
            resize: vertical;
        }
        
        .notes-textarea:focus {
            border-color: #3498db;
            outline: none;
            box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
        }
        
        .deadline-input {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            margin-bottom: 20px;
        }
        
        .deadline-input:focus {
            border-color: #3498db;
            outline: none;
            box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
        }
        
        .action-buttons {
            display: flex;
            gap: 15px;
            margin-top: 20px;
        }
        
        .btn-decline, .btn-approve {
            flex: 1;
            padding: 15px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        .btn-decline {
            background: #e74c3c;
            color: white;
        }
        
        .btn-decline:hover {
            background: #c0392b;
            transform: translateY(-2px);
        }
        
        .btn-approve {
            background: #27ae60;
            color: white;
        }
        
        .btn-approve:hover {
            background: #219653;
            transform: translateY(-2px);
        }
        
        .status-badge {
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 600;
            display: inline-block;
            margin-bottom: 20px;
        }
        
        .status-pending {
            background-color: #fff3cd;
            color: #856404;
        }
        
        .status-approved {
            background-color: #d5f4e6;
            color: #27ae60;
        }
        
        .status-declined {
            background-color: #f8d7da;
            color: #721c24;
        }
        
        .message-box {
            background: white;
            border-radius: 10px;
            padding: 15px 20px;
            margin-bottom: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            border-left: 4px solid;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .message-success {
            border-left-color: #27ae60;
            background: linear-gradient(135deg, #f1f8e9 0%, #e8f5e9 100%);
        }
        
        .message-error {
            border-left-color: #e74c3c;
            background: linear-gradient(135deg, #ffebee 0%, #fce4ec 100%);
        }
        
        .driver-info-card {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 30px;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .info-item {
            display: flex;
            flex-direction: column;
        }
        
        .info-label {
            color: #7f8c8d;
            font-size: 14px;
            margin-bottom: 5px;
        }
        
        .info-value {
            color: #2c3e50;
            font-weight: 600;
            font-size: 16px;
        }
        
        .no-document {
            color: #95a5a6;
            font-style: italic;
        }
        
        .document-image-modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.9);
            z-index: 2000;
            align-items: center;
            justify-content: center;
        }
        
        .document-image {
            max-width: 90%;
            max-height: 90%;
            border-radius: 8px;
        }
        
        .close-modal {
            position: absolute;
            top: 20px;
            right: 20px;
            color: white;
            font-size: 30px;
            cursor: pointer;
            background: none;
            border: none;
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1><i class="fas fa-user-check"></i> Driver Validation Review</h1>
            <a href="drivers.php" class="back-btn">
                <i class="fas fa-arrow-left"></i> Back to Drivers
            </a>
        </div>
        
        <!-- Message Box -->
        <?php if ($message): ?>
        <div class="message-box message-<?php echo $messageType; ?>">
            <i class="fas fa-<?php echo $messageType == 'success' ? 'check-circle' : 'exclamation-circle'; ?>"></i>
            <?php echo $message; ?>
        </div>
        <?php endif; ?>
        
        <!-- Driver Info Card -->
        <div class="driver-info-card">
            <h2 class="section-title">
                <i class="fas fa-user"></i> Driver Information
                <?php if ($validationData['validationStatus']): ?>
                    <span class="status-badge status-<?php echo $validationData['validationStatus']; ?>">
                        <?php echo strtoupper($validationData['validationStatus']); ?>
                    </span>
                <?php endif; ?>
            </h2>
            
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Name</span>
                    <span class="info-value"><?php echo htmlspecialchars($driver['name'] ?? 'N/A'); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Email</span>
                    <span class="info-value"><?php echo htmlspecialchars($driver['email'] ?? 'N/A'); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Phone</span>
                    <span class="info-value"><?php echo htmlspecialchars($driver['phone'] ?? 'N/A'); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Permit Number</span>
                    <span class="info-value"><?php echo htmlspecialchars($driver['permitNumber'] ?? 'N/A'); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Account Status</span>
                    <span class="info-value"><?php echo htmlspecialchars($driver['accountStatus'] ?? 'pending'); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Profile Completed</span>
                    <span class="info-value">
                        <?php echo (isset($driver['isProfileCompleted']) && $driver['isProfileCompleted']) ? 'Yes' : 'No'; ?>
                    </span>
                </div>
            </div>
        </div>
        
        <!-- Main Validation Grid -->
        <div class="validation-grid">
            <!-- Left Column: Documents -->
            <div class="validation-section">
                <h2 class="section-title"><i class="fas fa-file-alt"></i> Validation Documents</h2>
                
                <div class="documents-grid">
                    <!-- ID Document -->
                    <div class="document-card">
                        <div class="document-icon">
                            <i class="fas fa-id-card"></i>
                        </div>
                        <div class="document-title">ID Document</div>
                        <?php if (!empty($validationData['idUrl'])): ?>
                            <div class="document-actions">
                                <a href="<?php echo htmlspecialchars($validationData['idUrl']); ?>" 
                                   target="_blank" class="view-btn" id="viewIdBtn">
                                    <i class="fas fa-eye"></i> View Full Size
                                </a>
                            </div>
                        <?php else: ?>
                            <div class="no-document">No ID document uploaded</div>
                        <?php endif; ?>
                    </div>
                    
                    <!-- Selfie Document -->
                    <div class="document-card">
                        <div class="document-icon">
                            <i class="fas fa-camera"></i>
                        </div>
                        <div class="document-title">Selfie Document</div>
                        <?php if (!empty($validationData['selfieUrl'])): ?>
                            <div class="document-actions">
                                <a href="<?php echo htmlspecialchars($validationData['selfieUrl']); ?>" 
                                   target="_blank" class="view-btn" id="viewSelfieBtn">
                                    <i class="fas fa-eye"></i> View Full Size
                                </a>
                            </div>
                        <?php else: ?>
                            <div class="no-document">No document uploaded</div>
                        <?php endif; ?>
                    </div>
                    
                    <!-- Permit Document -->
                    <div class="document-card">
                        <div class="document-icon">
                            <i class="fas fa-file-contract"></i>
                        </div>
                        <div class="document-title">Permit Document</div>
                        <?php if (!empty($validationData['permitUrl'])): ?>
                            <div class="document-actions">
                                <a href="<?php echo htmlspecialchars($validationData['permitUrl']); ?>" 
                                   target="_blank" class="view-btn" id="viewPermitBtn">
                                    <i class="fas fa-eye"></i> View Full Size
                                </a>
                            </div>
                        <?php else: ?>
                            <div class="no-document">No permit document uploaded</div>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
            
            <!-- Right Column: Vehicle Details and Validation -->
            <div class="validation-section">
                <h2 class="section-title"><i class="fas fa-car"></i> Vehicle Details from Validation</h2>
                
                <div class="vehicle-details">
                    <div class="detail-row">
                        <span class="detail-label">Plate Number:</span>
                        <span class="detail-value"><?php echo htmlspecialchars($vehicleDetails['plateNumber']); ?></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Vehicle Type:</span>
                        <span class="detail-value"><?php echo htmlspecialchars($vehicleDetails['vehicleType']); ?></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Vehicle Color:</span>
                        <span class="detail-value"><?php echo htmlspecialchars($vehicleDetails['vehicleColor']); ?></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Vehicle Model:</span>
                        <span class="detail-value"><?php echo htmlspecialchars($vehicleDetails['vehicleModel']); ?></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Vehicle Permit:</span>
                        <span class="detail-value"><?php echo htmlspecialchars($vehicleDetails['vehiclePermit']); ?></span>
                    </div>
                </div>
                
                <div class="validation-notes">
                    <h2 class="section-title"><i class="fas fa-edit"></i> Validation Notes</h2>
                    
                    <?php if ($validationData['validationStatus'] === 'approved'): ?>
                        <div style="background: #d5f4e6; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                            <div style="font-weight: 600; color: #27ae60; margin-bottom: 5px;">
                                <i class="fas fa-check-circle"></i> VALIDATED
                            </div>
                            <?php if (!empty($validationData['validatedBy'])): ?>
                                <div style="color: #7f8c8d; font-size: 14px;">
                                    Validated by: <?php echo htmlspecialchars($validationData['validatedBy']); ?>
                                    <?php if (!empty($validationData['validatedAt'])): ?>
                                        on <?php echo date('Y-m-d H:i', $validationData['validatedAt'] / 1000); ?>
                                    <?php endif; ?>
                                </div>
                            <?php endif; ?>
                        </div>
                    <?php endif; ?>
                    
                    <form method="POST" action="">
                        <?php if (!$canManageValidation): ?>
                            <div style="background:#eef5ff; color:#1f4b99; padding:14px 16px; border-radius:8px; margin-bottom:20px;">
                                <i class="fas fa-eye"></i> View-only access. Validation actions are disabled for your account.
                            </div>
                        <?php endif; ?>
                        <textarea name="validationNotes" class="notes-textarea" <?php echo !$canManageValidation ? 'readonly' : ''; ?> 
                                  placeholder="Add validation notes or comments..."><?php 
                            echo htmlspecialchars($validationData['validationNotes'] ?? ''); 
                        ?></textarea>
                        
                        <div style="margin-bottom: 20px;">
                            <label style="display: block; margin-bottom: 8px; color: #2c3e50; font-weight: 600;">
                                <i class="fas fa-calendar-alt"></i> Add "deadline: YYYY-MM-DD" to set a deadline
                            </label>
                            <input type="date" name="deadline" class="deadline-input" <?php echo !$canManageValidation ? 'disabled' : ''; ?> 
                                   value="<?php echo htmlspecialchars($validationData['deadline'] ?? ''); ?>">
                        </div>
                        
                        <?php if ($canManageValidation): ?>
                        <div class="action-buttons">
                            <button type="submit" name="action" value="decline" class="btn-decline">
                                <i class="fas fa-times"></i> X Decline Driver
                            </button>
                            <button type="submit" name="action" value="approve" class="btn-approve">
                                <i class="fas fa-check"></i> ✔️ Approve Driver
                            </button>
                        </div>
                        <?php endif; ?>
                    </form>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Image Modal -->
    <div id="imageModal" class="document-image-modal">
        <button class="close-modal" onclick="closeImageModal()">&times;</button>
        <img id="modalImage" class="document-image" src="" alt="Document">
    </div>
    
    <script>
    // Handle document viewing in modal
    const viewIdBtn = document.getElementById('viewIdBtn');
    const viewSelfieBtn = document.getElementById('viewSelfieBtn');
    const viewPermitBtn = document.getElementById('viewPermitBtn');
    const modal = document.getElementById('imageModal');
    const modalImage = document.getElementById('modalImage');
    
    function openImageModal(imageUrl) {
        modalImage.src = imageUrl;
        modal.style.display = 'flex';
    }
    
    function closeImageModal() {
        modal.style.display = 'none';
        modalImage.src = '';
    }
    
    // Attach click events if elements exist
    if (viewIdBtn) {
        viewIdBtn.addEventListener('click', function(e) {
            e.preventDefault();
            openImageModal(this.href);
        });
    }
    
    if (viewSelfieBtn) {
        viewSelfieBtn.addEventListener('click', function(e) {
            e.preventDefault();
            openImageModal(this.href);
        });
    }
    
    if (viewPermitBtn) {
        viewPermitBtn.addEventListener('click', function(e) {
            e.preventDefault();
            openImageModal(this.href);
        });
    }
    
    // Close modal on ESC key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeImageModal();
        }
    });
    
    // Close modal when clicking outside image
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            closeImageModal();
        }
    });
    
    // Form submission confirmation
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', function(e) {
            const action = e.submitter ? e.submitter.value : '';
            
            if (action === 'decline') {
                if (!confirm('Are you sure you want to decline this driver?')) {
                    e.preventDefault();
                }
            } else if (action === 'approve') {
                if (!confirm('Are you sure you want to approve this driver?')) {
                    e.preventDefault();
                }
            }
        });
    });
    </script>
</body>
</html>