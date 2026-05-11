<?php
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_VERIFICATION_VIEW);

$message = '';
$messageType = '';

$drivers = getDriversList();
$todas = getAllTodas();

// CSV import (batch) or single updates
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    requirePermission(PERM_VERIFICATION_MANAGE);

    if ($_POST['action'] === 'update_driver') {
        $driverId = $_POST['driver_id'] ?? '';
        $status = trim($_POST['verificationStatus'] ?? 'Unverified');
        $expiry = trim($_POST['permitExpiryDate'] ?? ''); // YYYY-MM-DD
        $ref = trim($_POST['bploReference'] ?? '');

        $update = [
            'verificationStatus' => $status,
            'permitExpiryDate' => $expiry,
            'bploReference' => $ref,
            'bploVerifiedAt' => (int)(microtime(true) * 1000),
            'bploVerifiedBy' => $_SESSION['admin_username'] ?? '',
        ];

        if (firebaseUpdate('drivers/' . $driverId, $update)) {
            auditLog('BPLO_VERIFY_DRIVER', 'driver', $driverId, $update);
            $message = 'Driver verification updated.';
            $messageType = 'success';
        } else {
            $message = 'Failed to update driver verification.';
            $messageType = 'error';
        }
    }

    if ($_POST['action'] === 'import_csv') {
        if (!isset($_FILES['csv']) || $_FILES['csv']['error'] !== UPLOAD_ERR_OK) {
            $message = 'CSV upload failed.';
            $messageType = 'error';
        } else {
            $tmp = $_FILES['csv']['tmp_name'];
            $fh = fopen($tmp, 'r');
            if (!$fh) {
                $message = 'Unable to read CSV.';
                $messageType = 'error';
            } else {
                $header = fgetcsv($fh);
                $header = is_array($header) ? array_map('trim', $header) : [];

                // Expected columns (any order): driverId OR permitNumber, status, expiryDate, referenceId
                $col = [];
                foreach ($header as $i => $h) {
                    $key = strtolower($h);
                    $col[$key] = $i;
                }

                $updated = 0;
                $skipped = 0;

                while (($row = fgetcsv($fh)) !== false) {
                    $driverId = '';
                    $permitNumber = '';

                    if (isset($col['driverid'])) $driverId = trim($row[$col['driverid']] ?? '');
                    if (isset($col['permitnumber'])) $permitNumber = trim($row[$col['permitnumber']] ?? '');

                    // Find by driverId first; else permitNumber
                    if ($driverId === '' && $permitNumber !== '') {
                        foreach ($drivers as $did => $d) {
                            if (!is_array($d)) continue;
                            if (trim((string)($d['permitNumber'] ?? '')) === $permitNumber) {
                                $driverId = $did;
                                break;
                            }
                        }
                    }

                    if ($driverId === '') {
                        $skipped++;
                        continue;
                    }

                    $status = '';
                    $expiry = '';
                    $ref = '';

                    if (isset($col['status'])) $status = trim($row[$col['status']] ?? '');
                    if (isset($col['expirydate'])) $expiry = trim($row[$col['expirydate']] ?? '');
                    if (isset($col['referenceid'])) $ref = trim($row[$col['referenceid']] ?? '');

                    $update = [
                        'verificationStatus' => $status !== '' ? $status : 'Verified',
                        'permitExpiryDate' => $expiry,
                        'bploReference' => $ref,
                        'bploVerifiedAt' => (int)(microtime(true) * 1000),
                        'bploVerifiedBy' => $_SESSION['admin_username'] ?? '',
                    ];

                    if (firebaseUpdate('drivers/' . $driverId, $update)) {
                        $updated++;
                    } else {
                        $skipped++;
                    }
                }

                fclose($fh);

                auditLog('BPLO_IMPORT_CSV', 'driver', '', ['updated' => $updated, 'skipped' => $skipped]);
                $message = "CSV processed. Updated: $updated, Skipped: $skipped";
                $messageType = $updated > 0 ? 'success' : 'error';
            }
        }
    }

    // Refresh
    $drivers = getDriversList();
}

// Filters
$statusFilter = $_GET['vstatus'] ?? '';
$todaFilter = $_GET['toda'] ?? '';
$showExpiring = isset($_GET['expiring']) && $_GET['expiring'] === '1';

$today = new DateTime('today');
$threshold = (clone $today)->modify('+30 days');

$filtered = [];
foreach ($drivers as $driverId => $d) {
    if (!is_array($d)) continue;

    $v = trim((string)($d['verificationStatus'] ?? 'Unverified'));
    $todaId = $d['todaId'] ?? null;

    if ($statusFilter !== '' && strcasecmp($v, $statusFilter) !== 0) continue;
    if ($todaFilter !== '' && (string)$todaId !== (string)$todaFilter) continue;

    if ($showExpiring) {
        $expiryStr = trim((string)($d['permitExpiryDate'] ?? ''));
        if ($expiryStr === '') continue;

        $expiry = DateTime::createFromFormat('Y-m-d', $expiryStr);
        if (!$expiry) continue;

        if ($expiry > $threshold) continue;
    }

    $filtered[$driverId] = $d;
}

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BPLO Verification - Kaltrike Admin</title>
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
        .message { padding:12px 14px; border-radius:10px; margin-bottom:18px; }
        .success { background:#d4edda; color:#155724; }
        .error { background:#f8d7da; color:#721c24; }
        label { font-size:12px; color:#7f8c8d; font-weight:600; margin-bottom:6px; display:block; }
        input, select { width:100%; padding:10px 12px; border:1px solid #ddd; border-radius:8px; font-size:14px; }
        .row { display:flex; gap:10px; align-items:center; }
        .btn { border:none; border-radius:8px; padding:10px 14px; cursor:pointer; font-weight:600; }
        .btn-primary { background:#3498db; color:#fff; }
        .btn-secondary { background:#95a5a6; color:#fff; }
        table { width:100%; border-collapse:collapse; }
        th, td { padding:12px; border-bottom:1px solid #eee; text-align:left; vertical-align:top; }
        th { background:#fafafa; font-size:12px; letter-spacing:0.3px; text-transform:uppercase; color:#7f8c8d; }
        .tag { display:inline-block; padding:3px 8px; border-radius:999px; font-size:12px; background:#ecf0f1; }
        .tag-green { background:#eafaf1; color:#27ae60; }
        .tag-red { background:#fdecea; color:#c0392b; }
        .tag-blue { background:#e8f4fc; color:#3498db; }
        .small { font-size:12px; color:#7f8c8d; }
        @media (max-width: 980px) {
            .main-content { margin-left:0; }
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>
    <?php include 'sidebar.php'; ?>

    <div class="main-content">
        <div class="header">
            <h1><i class="fa-solid fa-shield-halved"></i> BPLO Verification</h1>
        </div>

        <?php if ($message): ?>
            <div class="message <?php echo $messageType === 'success' ? 'success' : 'error'; ?>">
                <?php echo h($message); ?>
            </div>
        <?php endif; ?>

        <div class="card">
            <div class="row" style="justify-content:space-between;">
                <div>
                    <h3 style="margin-bottom:6px;">Filters</h3>
                    <div class="small">Use this screen to verify permits and monitor expiring/flagged drivers.</div>
                </div>
                <form method="GET" class="row">
                    <select name="vstatus" style="width:200px;">
                        <option value="">All Status</option>
                        <?php foreach (['Unverified','Pending','Verified','Expired','Rejected'] as $s): ?>
                            <option value="<?php echo h($s); ?>" <?php echo ($statusFilter===$s)?'selected':''; ?>><?php echo h($s); ?></option>
                        <?php endforeach; ?>
                    </select>

                    <select name="toda" style="width:220px;">
                        <option value="">All TODAs</option>
                        <?php foreach ($todas as $tid => $td): ?>
                            <option value="<?php echo h($tid); ?>" <?php echo ((string)$todaFilter===(string)$tid)?'selected':''; ?>><?php echo h($td['name'] ?? $tid); ?></option>
                        <?php endforeach; ?>
                    </select>

                    <label style="display:flex; gap:8px; align-items:center; font-weight:600; color:#2c3e50;">
                        <input type="checkbox" name="expiring" value="1" <?php echo $showExpiring?'checked':''; ?> /> Expiring (30 days)
                    </label>

                    <button class="btn btn-secondary" type="submit"><i class="fa-solid fa-filter"></i> Apply</button>
                </form>
            </div>
        </div>

        <?php if (hasPermission(PERM_VERIFICATION_MANAGE)): ?>
        <div class="card">
            <h3 style="margin-bottom:10px;">Batch Import (CSV)</h3>
            <div class="small" style="margin-bottom:10px;">
                CSV header example: <code>driverId,permitNumber,status,expiryDate,referenceId</code>
            </div>
            <form method="POST" enctype="multipart/form-data" class="row">
                <input type="hidden" name="action" value="import_csv" />
                <input type="file" name="csv" accept=".csv" required />
                <button class="btn btn-primary" type="submit"><i class="fa-solid fa-upload"></i> Import</button>
            </form>
        </div>
        <?php endif; ?>

        <div class="card">
            <h3 style="margin-bottom:10px;">Drivers</h3>
            <table>
                <thead>
                    <tr>
                        <th>Driver</th>
                        <th>TODA</th>
                        <th>Permit</th>
                        <th>Verification</th>
                        <th>Expiry</th>
                        <th>Update</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($filtered)): ?>
                        <tr><td colspan="6" class="small">No drivers matched your filters.</td></tr>
                    <?php endif; ?>

                    <?php foreach ($filtered as $driverId => $d): ?>
                        <?php
                            $name = $d['name'] ?? 'Unknown';
                            $phone = $d['phone'] ?? '';
                            $permit = $d['permitNumber'] ?? '';
                            $todaName = getTodaName($d['todaId'] ?? null);
                            $v = trim((string)($d['verificationStatus'] ?? 'Unverified'));
                            $expiryStr = trim((string)($d['permitExpiryDate'] ?? ''));
                            $tagClass = 'tag-blue';
                            if (strcasecmp($v, 'Verified') === 0) $tagClass = 'tag-green';
                            if (in_array(strtolower($v), ['expired','rejected'], true)) $tagClass = 'tag-red';
                        ?>
                        <tr>
                            <td>
                                <strong><?php echo h($name); ?></strong><br>
                                <span class="small"><?php echo h($phone); ?></span><br>
                                <span class="small">ID: <?php echo h($driverId); ?></span>
                            </td>
                            <td><?php echo h($todaName); ?></td>
                            <td><?php echo h($permit); ?></td>
                            <td><span class="tag <?php echo $tagClass; ?>"><?php echo h($v); ?></span></td>
                            <td><?php echo h($expiryStr ?: '—'); ?></td>
                            <td>
                                <?php if (hasPermission(PERM_VERIFICATION_MANAGE)): ?>
                                <details>
                                    <summary style="cursor:pointer; color:#3498db; font-weight:600;">Update</summary>
                                    <form method="POST" style="margin-top:10px;">
                                        <input type="hidden" name="action" value="update_driver" />
                                        <input type="hidden" name="driver_id" value="<?php echo h($driverId); ?>" />

                                        <div class="row" style="gap:10px;">
                                            <div style="flex:1;">
                                                <label>Status</label>
                                                <select name="verificationStatus">
                                                    <?php foreach (['Unverified','Pending','Verified','Expired','Rejected'] as $s): ?>
                                                        <option value="<?php echo h($s); ?>" <?php echo ($v===$s)?'selected':''; ?>><?php echo h($s); ?></option>
                                                    <?php endforeach; ?>
                                                </select>
                                            </div>
                                            <div style="flex:1;">
                                                <label>Permit Expiry (YYYY-MM-DD)</label>
                                                <input name="permitExpiryDate" value="<?php echo h($expiryStr); ?>" placeholder="2026-12-31" />
                                            </div>
                                        </div>

                                        <div style="margin-top:10px;">
                                            <label>Reference ID (optional)</label>
                                            <input name="bploReference" value="<?php echo h($d['bploReference'] ?? ''); ?>" />
                                        </div>

                                        <div style="margin-top:10px;">
                                            <button class="btn btn-primary" type="submit"><i class="fa-solid fa-floppy-disk"></i> Save</button>
                                        </div>
                                    </form>
                                </details>
                                <?php else: ?>
                                    <span class="small">Read-only</span>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>

        <div class="card">
            <h3>Compliance Notes</h3>
            <ul style="margin-left:18px; margin-top:8px;">
                <li>Verification fields are stored in Firebase under each driver: <code>verificationStatus</code>, <code>permitExpiryDate</code>, <code>bploVerifiedAt</code>, <code>bploVerifiedBy</code>, <code>bploReference</code>.</li>
                <li>All changes are logged to <code>auditLogs</code>.</li>
            </ul>
        </div>
    </div>
</body>
</html>
