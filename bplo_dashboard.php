<?php
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_DASHBOARD_VIEW);

if (!isBploVerifier()) {
    header('Location: ' . getDashboardRouteForCurrentUser());
    exit();
}

$drivers = getAllDrivers();
$pendingCompliance = [];
$verifiedDrivers = 0;
$withCompleteDocs = 0;
$missingReference = 0;

foreach ($drivers as $driverId => $driver) {
    if (!is_array($driver)) continue;

    $documents = getDriverValidationDocuments($driverId, $driver);
    $hasCompleteDocs = $documents['idUrl'] !== '' && $documents['permitUrl'] !== '' && $documents['selfieUrl'] !== '';
    if ($hasCompleteDocs) {
        $withCompleteDocs++;
    }

    $verificationStatus = strtolower((string)($driver['verificationStatus'] ?? $driver['validationStatus'] ?? $driver['accountStatus'] ?? 'pending'));
    $bploReference = trim((string)($driver['bploReference'] ?? ''));

    if (in_array($verificationStatus, ['verified', 'approved', 'validated'], true)) {
        $verifiedDrivers++;
    }

    if ($bploReference === '') {
        $missingReference++;
    }

    if (!in_array($verificationStatus, ['verified', 'approved', 'validated'], true) || !$hasCompleteDocs || $bploReference === '') {
        $pendingCompliance[$driverId] = $driver + ['_docs' => $documents];
    }
}

if (!empty($pendingCompliance)) {
    uasort($pendingCompliance, function ($a, $b) {
        $ta = parseTimestamp($a['updatedAt'] ?? $a['createdAt'] ?? null) ?: 0;
        $tb = parseTimestamp($b['updatedAt'] ?? $b['createdAt'] ?? null) ?: 0;
        return $tb <=> $ta;
    });
}
$pendingCompliance = array_slice($pendingCompliance, 0, 10, true);

function bploStatusLabel($driver) {
    $status = strtolower((string)($driver['verificationStatus'] ?? $driver['validationStatus'] ?? $driver['accountStatus'] ?? 'pending'));
    if (in_array($status, ['verified', 'approved', 'validated'], true)) {
        return ['Verified', 'status-good'];
    }
    if (in_array($status, ['pending', 'for_review', 'for review'], true)) {
        return ['For review', 'status-warn'];
    }
    return [ucwords(str_replace('_', ' ', $status ?: 'Pending')), 'status-info'];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BPLO Dashboard - Kaltrike Admin</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .main-content { padding-bottom: 36px !important; }
        .hero {
            display: grid;
            grid-template-columns: 1.35fr minmax(300px, 0.85fr);
            gap: 18px;
            margin-bottom: 22px;
        }
        .hero-card,
        .panel-card {
            background: rgba(255,255,255,0.96);
            border: 1px solid #dbe6f3;
            border-radius: 26px;
            box-shadow: 0 24px 48px rgba(15, 23, 42, 0.10);
            padding: 24px;
        }
        .eyebrow {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 14px;
            border-radius: 999px;
            background: rgba(34, 197, 94, 0.12);
            color: #15803d;
            font-weight: 700;
            font-size: 13px;
            margin-bottom: 16px;
        }
        h1 { margin: 0 0 10px; font-size: clamp(2rem, 2.8vw, 2.8rem); }
        .subtitle { color: #64748b; line-height: 1.65; }
        .hero-actions {
            margin-top: 20px;
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
        }
        .hero-actions a {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 18px;
            border-radius: 14px;
            text-decoration: none;
            font-weight: 700;
        }
        .btn-primary { background: linear-gradient(135deg, #16a34a 0%, #15803d 100%); color: #fff; }
        .btn-light { background: #f0fdf4; color: #15803d; }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 18px;
            margin-bottom: 22px;
        }
        .stat-value { font-size: clamp(1.7rem, 2.5vw, 2.4rem); font-weight: 800; margin: 10px 0 6px; }
        .stat-label { color: #64748b; font-weight: 600; }
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; min-width: 780px; }
        th, td { padding: 14px 12px; border-bottom: 1px solid #e5edf8; text-align: left; }
        .status-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: 999px;
            font-weight: 700;
            font-size: 12px;
        }
        .status-good { background: #dcfce7; color: #166534; }
        .status-info { background: #dbeafe; color: #1d4ed8; }
        .status-warn { background: #fef3c7; color: #b45309; }
        .doc-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 10px;
            border-radius: 999px;
            background: #eff6ff;
            color: #1d4ed8;
            font-size: 12px;
            font-weight: 700;
            margin: 0 6px 6px 0;
        }
        @media (max-width: 1120px) {
            .hero,
            .stats-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>
    <?php include 'sidebar.php'; ?>
    <main class="main-content">
        <section class="hero">
            <div class="hero-card">
                <div class="eyebrow"><i class="fa-solid fa-shield-halved"></i> BPLO Workspace</div>
                <h1>BPLO Dashboard</h1>
                <div class="hero-actions">
                    <a class="btn-primary" href="bplo_verification.php"><i class="fa-solid fa-file-signature"></i> Open Verification</a>
                    <a class="btn-light" href="drivers.php"><i class="fa-solid fa-user-tie"></i> View Drivers</a>
                </div>
            </div>
        </section>

        <section class="stats-grid">
            <div class="panel-card">
                <div class="stat-label">Total Drivers</div>
                <div class="stat-value"><?php echo count($drivers); ?></div>
            </div>
            <div class="panel-card">
                <div class="stat-label">Verified Drivers</div>
                <div class="stat-value"><?php echo (int)$verifiedDrivers; ?></div>
            </div>
            <div class="panel-card">
                <div class="stat-label">Complete Documents</div>
                <div class="stat-value"><?php echo (int)$withCompleteDocs; ?></div>
            </div>
            <div class="panel-card">
                <div class="stat-label">Missing Reference</div>
                <div class="stat-value"><?php echo (int)$missingReference; ?></div>
            </div>
        </section>

        <section class="panel-card">
            <h2 style="margin:0 0 16px;"><i class="fa-solid fa-list-check"></i> Recent Compliance Queue</h2>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Driver</th>
                            <th>TODA</th>
                            <th>Status</th>
                            <th>Documents</th>
                            <th>BPLO Reference</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php if (!empty($pendingCompliance)): ?>
                        <?php foreach ($pendingCompliance as $driverId => $driver): ?>
                            <?php [$label, $class] = bploStatusLabel($driver); ?>
                            <?php $docs = $driver['_docs'] ?? ['idUrl' => '', 'permitUrl' => '', 'selfieUrl' => '']; ?>
                            <tr>
                                <td>
                                    <strong><?php echo htmlspecialchars($driver['name'] ?? 'Unknown'); ?></strong><br>
                                    <span style="color:#64748b;font-size:13px;"><?php echo htmlspecialchars($driver['permitNumber'] ?? 'No permit'); ?></span>
                                </td>
                                <td><?php echo htmlspecialchars(getTodaName($driver['todaId'] ?? null)); ?></td>
                                <td><span class="status-pill <?php echo htmlspecialchars($class); ?>"><?php echo htmlspecialchars($label); ?></span></td>
                                <td>
                                    <span class="doc-chip <?php echo $docs['idUrl'] !== '' ? '' : 'status-warn'; ?>"><i class="fa-solid fa-id-card"></i> ID</span>
                                    <span class="doc-chip <?php echo $docs['permitUrl'] !== '' ? '' : 'status-warn'; ?>"><i class="fa-solid fa-file"></i> Permit</span>
                                    <span class="doc-chip <?php echo $docs['selfieUrl'] !== '' ? '' : 'status-warn'; ?>"><i class="fa-solid fa-camera"></i> Selfie</span>
                                </td>
                                <td><?php echo htmlspecialchars(trim((string)($driver['bploReference'] ?? '')) ?: 'Not set'); ?></td>
                            </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="5" style="text-align:center;color:#64748b;padding:26px;">All visible drivers are already compliant.</td>
                        </tr>
                    <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </section>
    </main>
</body>
</html>
