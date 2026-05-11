<?php
// debug_trips.php
session_start();
require_once 'database.php';

// Override to see all errors
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Firebase Trip Debugging</h1>";

// Test 1: Check if logged in (temporarily bypass)
$_SESSION['admin_logged_in'] = true;
$_SESSION['admin_username'] = 'admin';

// Test 2: Check Firebase connection
echo "<h2>Test 1: Firebase Connection</h2>";
$testData = firebaseGet('');
if ($testData === null) {
    echo "<div style='color: red;'><b>❌ Firebase connection FAILED - returned NULL</b></div>";
} elseif (empty($testData)) {
    echo "<div style='color: orange;'><b>⚠️ Firebase connection OK but returned empty array</b></div>";
} else {
    echo "<div style='color: green;'><b>✅ Firebase connection SUCCESSFUL</b></div>";
    echo "<p>Data structure type: " . gettype($testData) . "</p>";
}

// Test 3: Check all data from Firebase
echo "<h2>Test 2: All Data from Firebase Root</h2>";
echo "<p><b>URL being called:</b> " . FIREBASE_URL . ".json</p>";

// Get all data
$allData = firebaseGet('');

if (is_array($allData) && !empty($allData)) {
    echo "<div style='color: green;'>Found " . count($allData) . " items at root level</div>";
    
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Item Key</th><th>Type</th><th>Has userName?</th><th>Has driverName?</th><th>Has time?</th><th>Status</th></tr>";
    
    foreach ($allData as $key => $value) {
        $type = gettype($value);
        $hasUserName = (is_array($value) && isset($value['userName'])) ? '✅' : '❌';
        $hasDriverName = (is_array($value) && isset($value['driverName'])) ? '✅' : '❌';
        $hasTime = (is_array($value) && isset($value['time'])) ? '✅' : '❌';
        $status = (is_array($value) && isset($value['status'])) ? $value['status'] : 'N/A';
        
        echo "<tr>";
        echo "<td><b>" . htmlspecialchars($key) . "</b></td>";
        echo "<td>" . $type . "</td>";
        echo "<td>" . $hasUserName . "</td>";
        echo "<td>" . $hasDriverName . "</td>";
        echo "<td>" . $hasTime . "</td>";
        echo "<td>" . htmlspecialchars($status) . "</td>";
        echo "</tr>";
        
        // If this is your trip, show more details
        if ($key === "-OdETgHMYBSPV4Euy3Yg") {
            echo "<tr><td colspan='6' style='background-color: #e8f4fc;'>";
            echo "<b>Trip Details:</b><br>";
            echo "<pre>" . print_r($value, true) . "</pre>";
            echo "</td></tr>";
        }
    }
    echo "</table>";
} else {
    echo "<div style='color: red;'>No data found or data is not an array</div>";
    echo "<pre>" . print_r($allData, true) . "</pre>";
}

// Test 4: Test getAllTrips() function
echo "<h2>Test 3: getAllTrips() Function</h2>";
$trips = getAllTrips();

if (is_array($trips) && !empty($trips)) {
    echo "<div style='color: green;'>✅ getAllTrips() found " . count($trips) . " trips</div>";
    
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Trip ID</th><th>Passenger</th><th>Driver</th><th>Time</th><th>Fare</th><th>Status</th></tr>";
    
    foreach ($trips as $tripId => $trip) {
        $passenger = $trip['userName'] ?? 'N/A';
        $driver = $trip['driverName'] ?? 'N/A';
        $time = $trip['time'] ?? 'N/A';
        $fare = $trip['fareAmount'] ?? 'N/A';
        $status = $trip['status'] ?? 'N/A';
        
        echo "<tr>";
        echo "<td>" . htmlspecialchars($tripId) . "</td>";
        echo "<td>" . htmlspecialchars($passenger) . "</td>";
        echo "<td>" . htmlspecialchars($driver) . "</td>";
        echo "<td>" . htmlspecialchars($time) . "</td>";
        echo "<td>" . htmlspecialchars($fare) . "</td>";
        echo "<td>" . htmlspecialchars($status) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<div style='color: red;'>❌ getAllTrips() returned empty or no trips</div>";
    echo "<pre>" . print_r($trips, true) . "</pre>";
}

// Test 5: Test getTripStatistics()
echo "<h2>Test 4: getTripStatistics() Function</h2>";
$stats = getTripStatistics();
echo "<pre>" . print_r($stats, true) . "</pre>";

// Test 6: Test getTripsPaginated()
echo "<h2>Test 5: getTripsPaginated() Function</h2>";
$paginationResult = getTripsPaginated(1, 20, '', 'time', 'desc', []);
echo "<pre>" . print_r($paginationResult, true) . "</pre>";

// Test 7: Raw CURL test
echo "<h2>Test 6: Raw CURL Request</h2>";
$url = FIREBASE_URL . '.json';
echo "<p><b>Testing URL:</b> <a href='" . htmlspecialchars($url) . "' target='_blank'>" . htmlspecialchars($url) . "</a></p>";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

echo "<p><b>HTTP Status Code:</b> " . $httpCode . "</p>";
echo "<p><b>CURL Error:</b> " . ($curlError ? $curlError : 'None') . "</p>";
echo "<p><b>Raw Response (first 1000 chars):</b><br>";
echo "<textarea style='width: 100%; height: 200px;'>" . htmlspecialchars(substr($response, 0, 1000)) . "</textarea></p>";

if ($response !== false) {
    $jsonData = json_decode($response, true);
    if ($jsonData !== null) {
        echo "<p><b>JSON Decoded Successfully:</b> " . (is_array($jsonData) ? 'Array with ' . count($jsonData) . ' items' : 'Not an array') . "</p>";
    } else {
        echo "<p><b>JSON Decode Failed</b></p>";
    }
}

echo "<hr>";
echo "<h2>Recommendations</h2>";

if (empty($allData)) {
    echo "<ol>
    <li><b>Check Firebase URL</b>: Make sure it's exactly: <code>https://kaltrikedriverapp-default-rtdb.firebaseio.com/</code></li>
    <li><b>Check Firebase Rules</b>: Ensure your database allows public read access</li>
    <li><b>Check Internet Connection</b>: Your server must be able to reach Firebase</li>
    <li><b>Check for CORS issues</b>: Try accessing the URL directly in your browser</li>
    </ol>";
} elseif (!isset($allData["-OdETgHMYBSPV4Euy3Yg"])) {
    echo "<ol>
    <li><b>Trip not at root level</b>: Your trip might be under a different path</li>
    <li><b>Check other keys</b>: Look for your trip data under a different key</li>
    <li><b>Data structure changed</b>: The trip might be nested deeper</li>
    </ol>";
}

echo "</body></html>";
?>