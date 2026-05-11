<?php
require_once 'database.php';

echo "<h2>Testing Firebase Connection</h2>";

if (testFirebaseConnection()) {
    echo "<p style='color: green;'>✅ Firebase connection successful!</p>";
    
    // Test getting data
    $rides = getAllRideRequests();
    echo "<p>Total rides found: " . count($rides) . "</p>";
    
    // Show sample data
    if (!empty($rides)) {
        echo "<h3>Sample Ride:</h3>";
        $firstRide = reset($rides);
        echo "<pre>";
        print_r($firstRide);
        echo "</pre>";
    }
} else {
    echo "<p style='color: red;'>❌ Firebase connection failed!</p>";
    echo "<p>Possible issues:";
    echo "<ul>";
    echo "<li>Check Firebase URL in database.php</li>";
    echo "<li>Check if your InfinityFree hosting allows outgoing HTTP requests</li>";
    echo "<li>Check if Firebase database has public read access (required)</li>";
    echo "</ul>";
}
?>