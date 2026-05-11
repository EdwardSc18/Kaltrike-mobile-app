<?php
// debug_firebase.php
session_start();
require_once 'database.php';

// Test Firebase connection
echo "<h1>Firebase Debug Information</h1>";

// Test basic connection
echo "<h2>1. Testing Firebase Connection</h2>";
$testData = firebaseGet('');
if ($testData === null) {
    echo "❌ Firebase connection failed - returned null<br>";
} elseif (is_array($testData)) {
    echo "✅ Firebase connection successful!<br>";
    echo "Total root items: " . count($testData) . "<br>";
} else {
    echo "⚠️ Firebase returned non-array data<br>";
    var_dump($testData);
}

// Get all data from root
echo "<h2>2. Root Level Data Structure</h2>";
$allData = firebaseGet('');
echo "<pre>" . htmlspecialchars(json_encode($allData, JSON_PRETTY_PRINT)) . "</pre>";

// Test getAllTrips function
echo "<h2>3. Testing getAllTrips() Function</h2>";
$trips = getAllTrips();
echo "Trips found: " . count($trips) . "<br>";

if (count($trips) > 0) {
    echo "<h3>First 3 trips:</h3>";
    $count = 0;
    foreach ($trips as $tripId => $trip) {
        if ($count >= 3) break;
        echo "<h4>Trip ID: " . htmlspecialchars($tripId) . "</h4>";
        echo "<pre>" . htmlspecialchars(json_encode($trip, JSON_PRETTY_PRINT)) . "</pre>";
        $count++;
    }
} else {
    echo "<h3>No trips found. Let's check all data manually:</h3>";
    
    // Check all items in root to see what we have
    if (is_array($allData)) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Key</th><th>Type</th><th>Sample Data</th></tr>";
        
        foreach ($allData as $key => $value) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($key) . "</td>";
            
            if (is_array($value)) {
                echo "<td>Array (" . count($value) . " items)</td>";
                echo "<td>";
                // Show first few keys of the array
                $keys = array_keys($value);
                $sampleKeys = array_slice($keys, 0, 5);
                echo implode(", ", array_map('htmlspecialchars', $sampleKeys));
                if (count($keys) > 5) echo ", ...";
                echo "</td>";
            } else {
                echo "<td>" . gettype($value) . "</td>";
                echo "<td>" . htmlspecialchars(substr(strval($value), 0, 100)) . "...</td>";
            }
            echo "</tr>";
        }
        echo "</table>";
    }
}

// Test searching for trips manually
echo "<h2>4. Manual Trip Search</h2>";
echo "<h3>Looking for items with trip-like structure:</h3>";

if (is_array($allData)) {
    $tripCandidates = [];
    
    foreach ($allData as $itemId => $itemData) {
        if (!is_array($itemData)) {
            continue;
        }
        
        // Check if this looks like a trip
        $hasUserName = isset($itemData['userName']);
        $hasDriverName = isset($itemData['driverName']);
        $hasFareAmount = isset($itemData['fareAmount']);
        $hasTime = isset($itemData['time']);
        $hasStatus = isset($itemData['status']);
        
        if ($hasUserName || $hasDriverName || $hasFareAmount) {
            $tripCandidates[$itemId] = [
                'data' => $itemData,
                'score' => ($hasUserName ? 1 : 0) + ($hasDriverName ? 1 : 0) + 
                          ($hasFareAmount ? 1 : 0) + ($hasTime ? 1 : 0) + 
                          ($hasStatus ? 1 : 0)
            ];
        }
    }
    
    echo "Found " . count($tripCandidates) . " potential trip items<br>";
    
    if (count($tripCandidates) > 0) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Score</th><th>userName</th><th>driverName</th><th>fareAmount</th><th>time</th><th>status</th></tr>";
        
        foreach ($tripCandidates as $itemId => $candidate) {
            $data = $candidate['data'];
            echo "<tr>";
            echo "<td>" . htmlspecialchars($itemId) . "</td>";
            echo "<td>" . $candidate['score'] . "</td>";
            echo "<td>" . (isset($data['userName']) ? htmlspecialchars($data['userName']) : '') . "</td>";
            echo "<td>" . (isset($data['driverName']) ? htmlspecialchars($data['driverName']) : '') . "</td>";
            echo "<td>" . (isset($data['fareAmount']) ? htmlspecialchars($data['fareAmount']) : '') . "</td>";
            echo "<td>" . (isset($data['time']) ? htmlspecialchars($data['time']) : '') . "</td>";
            echo "<td>" . (isset($data['status']) ? htmlspecialchars($data['status']) : '') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
}

// Test direct retrieval of your sample trip ID
echo "<h2>5. Testing Direct Trip Retrieval</h2>";
$sampleTripId = "-OdGt1oZ_hQMreDBJUx7"; // From your sample data
echo "Testing trip ID: " . htmlspecialchars($sampleTripId) . "<br>";

$directTrip = firebaseGet($sampleTripId);
if ($directTrip && is_array($directTrip)) {
    echo "✅ Direct trip retrieval successful!<br>";
    echo "<pre>" . htmlspecialchars(json_encode($directTrip, JSON_PRETTY_PRINT)) . "</pre>";
} else {
    echo "❌ Direct trip retrieval failed<br>";
}

// Check if there's a specific collection for trips
echo "<h2>6. Checking Specific Collections</h2>";
$collections = ['RideRequests', 'All Ride Requests', 'trips', 'Trips', 'requests', 'Rides'];
foreach ($collections as $collection) {
    $data = firebaseGet($collection);
    echo "<h3>Collection: $collection</h3>";
    if (is_array($data) && count($data) > 0) {
        echo "✅ Found " . count($data) . " items<br>";
        // Show first item
        $firstKey = array_key_first($data);
        echo "First item key: " . htmlspecialchars($firstKey) . "<br>";
    } else {
        echo "❌ No data found<br>";
    }
}
?>