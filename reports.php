<?php
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_REPORTS_GENERATE);

$todas = getAllTodas();

$isScopedTODA = (!isSuperAdmin() && currentAdminRole() !== ROLE_BPLO_VERIFIER);

// Inputs
$type = $_GET['type'] ?? 'trips';
$startDate = $_GET['start_date'] ?? '';
$endDate = $_GET['end_date'] ?? '';
$status = $_GET['status'] ?? '';
$driverId = $_GET['driver_id'] ?? '';
$todaId = $_GET['toda_id'] ?? '';

if ($isScopedTODA) {
    $todaId = currentAdminTodaId();
}

$export = isset($_GET['export']) && $_GET['export'] === 'csv';

// Shared indexes
[$todaByDriverId, $todaByPhone] = buildDriverTodaIndex();

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
function toTs($d, $end=false) {
    if ($d === '') return null;
    return strtotime($d . ($end ? ' 23:59:59' : ' 00:00:00')) ?: null;
}

$tsStart = toTs($startDate);
$tsEnd = toTs($endDate, true);

$rows = [];
$headers = [];
$summary = [];

// Helper to check date range
function inRange($ts, $tsStart, $tsEnd) {
    if ($tsStart !== null && $ts < $tsStart) return false;
    if ($tsEnd !== null && $ts > $tsEnd) return false;
    return true;
}

// Generate report
switch ($type) {
    case 'revenue': {
        $trips = getAllTrips();
        $daily = [];
        $total = 0;
        $count = 0;

        foreach ($trips as $tripId => $t) {
            if (!is_array($t) || !isTripData($t)) continue;

            $ts = parseTimestamp($t['time'] ?? $t['timestamp'] ?? $t['createdAt'] ?? null) ?: 0;
            if (!inRange($ts, $tsStart, $tsEnd)) continue;

            $tripStatus = strtolower($t['status'] ?? '');
            if ($status !== '' && $tripStatus !== strtolower($status)) continue;

            $tripToda = getTripTodaId($t, $todaByDriverId, $todaByPhone);
            if ($todaId !== '' && (string)$tripToda !== (string)$todaId) continue;

            $fare = getTripFare($t);
            if (!in_array($tripStatus, ['ended','completed','finished'], true)) continue; // revenue from completed

            $day = date('Y-m-d', $ts);
            if (!isset($daily[$day])) $daily[$day] = ['trips' => 0, 'revenue' => 0];
            $daily[$day]['trips'] += 1;
            $daily[$day]['revenue'] += $fare;

            $total += $fare;
            $count += 1;
        }

        ksort($daily);

        $headers = ['Date', 'Trips', 'Revenue'];
        foreach ($daily as $day => $agg) {
            $rows[] = [$day, $agg['trips'], number_format($agg['revenue'], 2, '.', '')];
        }

        $summary = [
            'Total completed trips' => $count,
            'Total revenue' => number_format($total, 2),
            'Average revenue per trip' => $count > 0 ? number_format($total / $count, 2) : '0.00',
        ];

        if ($export) {
            auditLog('EXPORT_REPORT', 'report', 'revenue', ['start_date'=>$startDate,'end_date'=>$endDate,'toda_id'=>$todaId,'status'=>$status]);
            outputCsv('revenue_report.csv', $headers, $rows);
        }
        break;
    }

    case 'driver_performance': {
        $drivers = getDriversList();
        $ratings = getAllRatings();
        $feedback = getAllFeedback();

        // complaints per driver
        $complaints = [];
        foreach ($feedback as $fid => $f) {
            if (!is_array($f)) continue;
            $did = $f['driverId'] ?? '';
            if ($did === '') continue;
            if (!isset($complaints[$did])) $complaints[$did] = 0;
            $complaints[$did] += 1;
        }

        $headers = ['Driver ID', 'Driver Name', 'TODA', 'Verification Status', 'Trips (Completed)', 'Avg Rating', 'Complaints'];

        foreach ($drivers as $did => $d) {
            if (!is_array($d)) continue;

            $driverToda = $d['todaId'] ?? null;
            if ($todaId !== '' && (string)$driverToda !== (string)$todaId) continue;

            if ($driverId !== '' && (string)$did !== (string)$driverId) continue;

            $r = $ratings[$did] ?? null;
            $avg = is_array($r) ? (float)($r['currentRating'] ?? 0) : 0;
            $completed = is_array($r) ? (int)($r['completedTrips'] ?? 0) : 0;

            $rows[] = [
                $did,
                $d['name'] ?? 'Unknown',
                getTodaName($driverToda),
                $d['verificationStatus'] ?? 'Unverified',
                $completed,
                number_format($avg, 2, '.', ''),
                (int)($complaints[$did] ?? 0),
            ];
        }

        $summary = [
            'Drivers included' => count($rows),
        ];

        if ($export) {
            auditLog('EXPORT_REPORT', 'report', 'driver_performance', ['toda_id'=>$todaId,'driver_id'=>$driverId]);
            outputCsv('driver_performance_report.csv', $headers, $rows);
        }
        break;
    }

    case 'compliance': {
        $drivers = getDriversList();
        $headers = ['Driver ID', 'Driver Name', 'TODA', 'Permit #', 'Verification Status', 'Permit Expiry', 'BPLO Reference', 'Verified By', 'Verified At'];

        foreach ($drivers as $did => $d) {
            if (!is_array($d)) continue;

            $driverToda = $d['todaId'] ?? null;
            if ($todaId !== '' && (string)$driverToda !== (string)$todaId) continue;

            $vAt = parseTimestamp($d['bploVerifiedAt'] ?? null);
            $rows[] = [
                $did,
                $d['name'] ?? 'Unknown',
                getTodaName($driverToda),
                $d['permitNumber'] ?? '',
                $d['verificationStatus'] ?? 'Unverified',
                $d['permitExpiryDate'] ?? '',
                $d['bploReference'] ?? '',
                $d['bploVerifiedBy'] ?? '',
                $vAt ? date('Y-m-d H:i:s', $vAt) : '',
            ];
        }

        $summary = [
            'Drivers included' => count($rows),
        ];

        if ($export) {
            auditLog('EXPORT_REPORT', 'report', 'compliance', ['toda_id'=>$todaId]);
            outputCsv('compliance_report.csv', $headers, $rows);
        }
        break;
    }

    case 'feedback': {
        $feedback = getAllFeedback();
        $headers = ['Feedback ID','Created At','TODA','Category','Rating','Status','Trip ID','Driver ID','Commuter ID','Comment','Assigned To','Internal Notes'];

        foreach ($feedback as $fid => $f) {
            if (!is_array($f)) continue;

            $ts = parseTimestamp($f['createdAt'] ?? null) ?: 0;
            if (!inRange($ts, $tsStart, $tsEnd)) continue;

            $ftoda = $f['todaId'] ?? null;
            if ($todaId !== '' && (string)$ftoda !== (string)$todaId) continue;

            if ($status !== '' && strcasecmp(($f['status'] ?? ''), $status) !== 0) continue;

            $rows[] = [
                $fid,
                $ts ? date('Y-m-d H:i:s', $ts) : '',
                getTodaName($ftoda),
                $f['category'] ?? '',
                $f['rating'] ?? '',
                $f['status'] ?? '',
                $f['tripId'] ?? '',
                $f['driverId'] ?? '',
                $f['commuterId'] ?? '',
                $f['comment'] ?? '',
                $f['assignedTo'] ?? '',
                $f['internalNotes'] ?? '',
            ];
        }

        $summary = [
            'Feedback records included' => count($rows),
        ];

        if ($export) {
            auditLog('EXPORT_REPORT', 'report', 'feedback', ['start_date'=>$startDate,'end_date'=>$endDate,'toda_id'=>$todaId,'status'=>$status]);
            outputCsv('feedback_report.csv', $headers, $rows);
        }
        break;
    }

    case 'trips':
    default: {
        $trips = getAllTrips();
        $headers = ['Trip ID', 'Date/Time', 'Passenger', 'Driver', 'TODA', 'Fare', 'Status', 'Origin', 'Destination'];

        foreach ($trips as $tripId => $t) {
            if (!is_array($t) || !isTripData($t)) continue;

            $ts = parseTimestamp($t['time'] ?? $t['timestamp'] ?? $t['createdAt'] ?? null) ?: 0;
            if (!inRange($ts, $tsStart, $tsEnd)) continue;

            $tripStatus = strtolower($t['status'] ?? '');
            if ($status !== '' && $tripStatus !== strtolower($status)) continue;

            if ($driverId !== '') {
                $tDriverId = $t['driverId'] ?? $t['driver_id'] ?? '';
                if ((string)$tDriverId !== (string)$driverId) continue;
            }

            $tripToda = getTripTodaId($t, $todaByDriverId, $todaByPhone);
            if ($todaId !== '' && (string)$tripToda !== (string)$todaId) continue;

            $passenger = $t['userName'] ?? $t['user_name'] ?? $t['passengerName'] ?? '';
            $driver = $t['driverName'] ?? $t['driver_name'] ?? '';

            $origin = $t['originAddress'] ?? (is_array($t['origin'] ?? null) ? ($t['origin']['address'] ?? '') : ($t['origin'] ?? ''));
            $dest = $t['destinationAddress'] ?? (is_array($t['destination'] ?? null) ? ($t['destination']['address'] ?? '') : ($t['destination'] ?? ''));

            $rows[] = [
                $tripId,
                $ts ? date('Y-m-d H:i:s', $ts) : '',
                $passenger,
                $driver,
                getTodaName($tripToda),
                number_format(getTripFare($t), 2, '.', ''),
                $tripStatus,
                $origin,
                $dest,
            ];
        }

        $summary = [
            'Trips included' => count($rows),
        ];

        if ($export) {
            auditLog('EXPORT_REPORT', 'report', 'trips', ['start_date'=>$startDate,'end_date'=>$endDate,'toda_id'=>$todaId,'status'=>$status,'driver_id'=>$driverId]);
            outputCsv('trips_report.csv', $headers, $rows);
        }
        break;
    }
}

// If not exporting, show in HTML
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reports - Kaltrike Admin</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel=\"stylesheet\" href=\"assets/styles.css\">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background:#f5f6fa; color:#2c3e50; display:flex; min-height:100vh; }
        .main-content { flex:1; margin-left:250px; padding:25px; min-height:100vh; }
        .header { display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; padding-bottom:15px; border-bottom:2px solid #e0e0e0; }
        .header h1 { font-size:28px; font-weight:600; }
        .card { background:#fff; border-radius:12px; box-shadow:0 2px 10px rgba(0,0,0,0.08); padding:18px; margin-bottom:18px; }
        label { font-size:12px; color:#7f8c8d; font-weight:600; margin-bottom:6px; display:block; }
        input, select { width:100%; padding:10px 12px; border:1px solid #ddd; border-radius:8px; font-size:14px; }
        .grid { display:grid; grid-template-columns: repeat(4, 1fr); gap:12px; }
        .row { display:flex; gap:10px; align-items:center; }
        .btn { border:none; border-radius:8px; padding:10px 14px; cursor:pointer; font-weight:600; }
        .btn-primary { background:#3498db; color:#fff; }
        .btn-secondary { background:#95a5a6; color:#fff; }
        table { width:100%; border-collapse:collapse; }
        th, td { padding:12px; border-bottom:1px solid #eee; text-align:left; vertical-align:top; }
        th { background:#fafafa; font-size:12px; letter-spacing:0.3px; text-transform:uppercase; color:#7f8c8d; }
        .stat { display:inline-block; padding:6px 10px; border-radius:10px; background:#f1f2f6; margin-right:8px; margin-bottom:8px; }
        .small { font-size:12px; color:#7f8c8d; }
        @media (max-width: 980px) {
            .grid { grid-template-columns: 1fr; }
            .main-content { margin-left:0; }
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>
    <?php include 'sidebar.php'; ?>

    <div class="main-content">
        <div class="header">
            <h1><i class="fa-solid fa-file-lines"></i> Reports</h1>
        </div>

        <div class="card">
            <h3 style="margin-bottom:10px;">Generate Report</h3>
            <form method="GET">
                <div class="grid">
                    <div>
                        <label>Report Type</label>
                        <select name="type">
                            <option value="trips" <?php echo $type==='trips'?'selected':''; ?>>Trips</option>
                            <option value="revenue" <?php echo $type==='revenue'?'selected':''; ?>>Revenue</option>
                            <option value="driver_performance" <?php echo $type==='driver_performance'?'selected':''; ?>>Driver Performance</option>
                            <option value="compliance" <?php echo $type==='compliance'?'selected':''; ?>>Compliance (BPLO)</option>
                            <option value="feedback" <?php echo $type==='feedback'?'selected':''; ?>>Feedback</option>
                        </select>
                    </div>
                    <div>
                        <label>Start Date</label>
                        <input type="date" name="start_date" value="<?php echo h($startDate); ?>" />
                    </div>
                    <div>
                        <label>End Date</label>
                        <input type="date" name="end_date" value="<?php echo h($endDate); ?>" />
                    </div>
                    <div>
                        <label>Status (Trips/Feedback)</label>
                        <input name="status" value="<?php echo h($status); ?>" placeholder="e.g., completed / New" />
                    </div>

                    <div>
                        <label>Driver ID (optional)</label>
                        <input name="driver_id" value="<?php echo h($driverId); ?>" placeholder="driver_..." />
                    </div>
                    <div>
                        <label>TODA</label>
                        <?php if ($isScopedTODA): ?>
                            <input type="text" value="<?php echo h(getTodaName($todaId)); ?>" disabled />
                            <input type="hidden" name="toda_id" value="<?php echo h($todaId); ?>" />
                        <?php else: ?>
                            <select name="toda_id">
                                <option value="">All TODAs</option>
                                <?php foreach ($todas as $tid => $td): ?>
                                    <option value="<?php echo h($tid); ?>" <?php echo ((string)$todaId===(string)$tid)?'selected':''; ?>><?php echo h($td['name'] ?? $tid); ?></option>
                                <?php endforeach; ?>
                            </select>
                        <?php endif; ?>
                    </div>
                    <div style="display:flex; align-items:flex-end; gap:10px;">
                        <button class="btn btn-primary" type="submit"><i class="fa-solid fa-chart-simple"></i> Generate</button>
                        <a class="btn btn-secondary" href="?<?php echo http_build_query(array_merge($_GET, ['export'=>'csv'])); ?>" style="text-decoration:none; display:inline-flex; align-items:center; gap:8px;">
                            <i class="fa-solid fa-file-csv"></i> Export CSV
                        </a>
                    </div>
                </div>
            </form>
        </div>

        <div class="card">
            <h3 style="margin-bottom:10px;">Summary</h3>
            <?php if (empty($summary)): ?>
                <div class="small">Generate a report to see summary values.</div>
            <?php else: ?>
                <?php foreach ($summary as $k => $v): ?>
                    <span class="stat"><strong><?php echo h($k); ?>:</strong> <?php echo h($v); ?></span>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>

        <div class="card">
            <h3 style="margin-bottom:10px;">Results (<?php echo count($rows); ?> rows)</h3>
            <div class="small" style="margin-bottom:10px;">Tip: use Export CSV for large datasets.</div>

            <div style="overflow-x:auto;">
                <table>
                    <thead>
                        <tr>
                            <?php foreach ($headers as $hcol): ?>
                                <th><?php echo h($hcol); ?></th>
                            <?php endforeach; ?>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($rows)): ?>
                            <tr><td colspan="<?php echo count($headers); ?>" class="small">No results.</td></tr>
                        <?php endif; ?>
                        <?php foreach (array_slice($rows, 0, 500) as $r): ?>
                            <tr>
                                <?php foreach ($r as $cell): ?>
                                    <td><?php echo h($cell); ?></td>
                                <?php endforeach; ?>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <?php if (count($rows) > 500): ?>
                <div class="small" style="margin-top:10px;">Showing first 500 rows. Export CSV to download full results.</div>
            <?php endif; ?>
        </div>

        <div class="card">
            <h3>Audit Notes</h3>
            <ul style="margin-left:18px; margin-top:8px;">
                <li>Every CSV export writes an entry to <code>auditLogs</code> (filters + report type).</li>
                <li>Revenue report only counts completed trips (status: ended/completed/finished).</li>
            </ul>
        </div>
    </div>
</body>
</html>
