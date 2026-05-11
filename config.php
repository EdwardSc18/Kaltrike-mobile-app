<?php
// config.php
session_start();

// Firebase Realtime Database Configuration
define('FIREBASE_URL', 'https://kaltrikedriverapp-default-rtdb.firebaseio.com/');
define('ADMIN_USERNAME', 'admin');
define('ADMIN_PASSWORD', 'admin123'); // Change this to a secure password

// Check if user is logged in
function isLoggedIn() {
    return isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;
}

// Firebase REST API Helper Functions
function firebaseGet($path) {
    $url = FIREBASE_URL . $path . '.json';
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    curl_close($ch);
    return json_decode($response, true);
}

function firebaseDelete($path) {
    $url = FIREBASE_URL . $path . '.json';
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "DELETE");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    curl_close($ch);
    return $response;
}

// Get all ride requests
function getAllRideRequests() {
    return firebaseGet('ALL Ride Requests');
}

// Get total counts
function getTotalCounts() {
    $data = getAllRideRequests();
    $counts = [
        'total_rides' => 0,
        'completed_rides' => 0,
        'active_rides' => 0,
        'total_drivers' => [],
        'total_commuters' => []
    ];
    
    if ($data) {
        $counts['total_rides'] = count($data);
        foreach ($data as $ride) {
            if (isset($ride['status'])) {
                if ($ride['status'] == 'ended') {
                    $counts['completed_rides']++;
                } else {
                    $counts['active_rides']++;
                }
            }
            
            // Count unique drivers
            if (isset($ride['driverId'])) {
                $counts['total_drivers'][$ride['driverId']] = true;
            }
            
            // Count unique commuters
            if (isset($ride['userPhone'])) {
                $counts['total_commuters'][$ride['userPhone']] = true;
            }
        }
        $counts['total_drivers'] = count($counts['total_drivers']);
        $counts['total_commuters'] = count($counts['total_commuters']);
    }
    
    return $counts;
}
?>