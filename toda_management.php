<?php
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_TODAS_MANAGE);

$message = '';
$messageType = '';
$todas = getAllTodas();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];

    if ($action === 'create_toda_account') {
        $role = (string)($_POST['role'] ?? ROLE_TODA_ADMIN);
        if (!in_array($role, [ROLE_TODA_ADMIN, ROLE_TODA_STAFF], true)) {
            $role = ROLE_TODA_ADMIN;
        }

        $data = [
            'username' => trim($_POST['username'] ?? ''),
            'email' => trim($_POST['email'] ?? ''),
            'password' => (string)($_POST['password'] ?? ''),
            'role' => $role,
            'todaId' => ($_POST['todaId'] ?? '') !== '' ? $_POST['todaId'] : null,
            'active' => true,
            'permissions' => roleDefaultPermissions($role),
        ];

        $override = isset($_POST['override_limit']) && isSuperAdmin();
        [$ok, $err] = createAdminUser($data, $override);
        if ($ok) {
            $message = 'TODA account created successfully.';
            $messageType = 'success';
        } else {
            $message = $err ?: 'Failed to create TODA account.';
            $messageType = 'error';
        }
    }

    if ($action === 'update') {
        $todaId = $_POST['toda_id'] ?? '';
        $data = [
            'name' => trim($_POST['name'] ?? ''),
            'code' => trim($_POST['code'] ?? ''),
            'active' => isset($_POST['active']) ? true : false,
        ];

        if (updateToda($todaId, $data)) {
            $message = 'TODA updated successfully.';
            $messageType = 'success';
        } else {
            $message = 'Failed to update TODA.';
            $messageType = 'error';
        }
    }

    if ($action === 'delete') {
        $todaId = $_POST['toda_id'] ?? '';
        if (deleteToda($todaId)) {
            $message = 'TODA deleted successfully.';
            $messageType = 'success';
        } else {
            $message = 'Failed to delete TODA.';
            $messageType = 'error';
        }
    }

    $todas = getAllTodas();
}

$drivers = getAllDrivers();
$trips = getAllTrips();
$ratings = getAllRatings();
[$indexById, $indexByPhone] = buildDriverTodaIndex();

$monitoringRows = [];
foreach ($todas as $todaId => $toda) {
    if (!is_array($toda)) continue;
    $driverStats = getDriverStatisticsForToda($todaId, $drivers);
    $tripStats = getTripStatisticsForToda($todaId, $trips);
    $ratingStats = getRatingStatisticsForToda($todaId, $ratings);
    $monitoringRows[$todaId] = [
        'meta' => $toda,
        'drivers' => $driverStats,
        'trips' => $tripStats,
        'ratings' => $ratingStats,
        'accounts' => countActiveTODAAccounts($todaId),
    ];
}

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TODAs - Kaltrike Admin</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background:#f5f6fa; color:#2c3e50; display:flex; min-height:100vh; }
        .main-content { flex:1; margin-left:250px; padding:25px; min-height:100vh; }
        .header { display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; padding-bottom:15px; border-bottom:2px solid #e0e0e0; }
        .header h1 { font-size:28px; font-weight:600; }
        .card { background:#fff; border-radius:12px; box-shadow:0 2px 10px rgba(0,0,0,0.08); padding:18px; margin-bottom:18px; }
        .grid { display:grid; grid-template-columns: repeat(3, 1fr); gap:12px; }
        .mini-grid { display:grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap:12px; margin-top:14px; }
        .metric { background:#f8fbff; border:1px solid #e3eef9; border-radius:12px; padding:14px; }
        .metric .label { font-size:12px; color:#7f8c8d; text-transform:uppercase; letter-spacing:0.05em; }
        .metric .value { font-size:24px; font-weight:700; margin-top:8px; color:#2c3e50; }
        label { font-size:12px; color:#7f8c8d; font-weight:600; margin-bottom:6px; display:block; }
        input, select { width:100%; padding:10px 12px; border:1px solid #ddd; border-radius:8px; font-size:14px; }
        .btn { border:none; border-radius:8px; padding:10px 14px; cursor:pointer; font-weight:600; }
        .btn-primary { background:#3498db; color:#fff; }
        .btn-danger { background:#e74c3c; color:#fff; }
        .message { padding:12px 14px; border-radius:10px; margin-bottom:18px; }
        .success { background:#d4edda; color:#155724; }
        .error { background:#f8d7da; color:#721c24; }
        .table-wrap { overflow-x:auto; }
        table { width:100%; border-collapse:collapse; min-width:980px; }
        th, td { padding:12px; border-bottom:1px solid #eee; text-align:left; vertical-align:top; }
        th { background:#fafafa; font-size:12px; letter-spacing:0.3px; text-transform:uppercase; color:#7f8c8d; }
        .tag { display:inline-block; padding:3px 8px; border-radius:999px; font-size:12px; background:#ecf0f1; }
        .tag-green { background:#eafaf1; color:#27ae60; }
        .tag-red { background:#fdecea; color:#c0392b; }
        .small { font-size:12px; color:#7f8c8d; }
        @media (max-width: 1100px) {
            .grid, .mini-grid { grid-template-columns: 1fr; }
            .main-content { margin-left:0; }
        }
    </style>
    <?php include 'ui_theme.php'; ?>
</head>
<body>
    <?php include 'sidebar.php'; ?>

    <div class="main-content">
        <div class="header">
            <h1><i class="fa-solid fa-building-user"></i> TODA Accounts & Monitoring</h1>
        </div>

        <?php if ($message): ?>
            <div class="message <?php echo $messageType === 'success' ? 'success' : 'error'; ?>">
                <?php echo h($message); ?>
            </div>
        <?php endif; ?>

        <div class="card">
            <h3 style="margin-bottom:10px;">Create TODA Account</h3>
            <p class="small" style="margin-bottom:12px;">Use this instead of creating a new admin user page. Accounts here are tied to one selected TODA.</p>
            <form method="POST">
                <input type="hidden" name="action" value="create_toda_account" />
                <div class="grid">
                    <div>
                        <label>Username *</label>
                        <input name="username" required />
                    </div>
                    <div>
                        <label>Email (optional)</label>
                        <input name="email" type="email" />
                    </div>
                    <div>
                        <label>Password *</label>
                        <input name="password" type="password" required />
                    </div>
                    <div>
                        <label>Account Type</label>
                        <select name="role">
                            <option value="<?php echo h(ROLE_TODA_ADMIN); ?>">TODA_ADMIN</option>
                            <option value="<?php echo h(ROLE_TODA_STAFF); ?>">TODA_STAFF</option>
                        </select>
                    </div>
                    <div>
                        <label>Assign TODA *</label>
                        <select name="todaId" required>
                            <option value="">-- Select TODA --</option>
                            <?php foreach ($todas as $tid => $td): ?>
                                <option value="<?php echo h($tid); ?>"><?php echo h($td['name'] ?? $tid); ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div>
                        <label>Limit Override</label>
                        <label style="display:flex; gap:8px; align-items:center; color:#2c3e50; font-size:14px; font-weight:600; margin-top:10px;">
                            <input type="checkbox" name="override_limit" value="1" <?php echo isSuperAdmin() ? '' : 'disabled'; ?> />
                            Allow more than 3 active TODA accounts
                        </label>
                    </div>
                </div>
                <div style="margin-top:14px;">
                    <button class="btn btn-primary" type="submit"><i class="fa-solid fa-plus"></i> Create TODA Account</button>
                </div>
            </form>
        </div>

        <div class="card">
            <h3 style="margin-bottom:6px;">Monitoring All TODAs</h3>
            <div class="small">Overview of drivers, trips, ratings, and active TODA accounts for each association.</div>
            <div class="mini-grid">
                <div class="metric"><div class="label">Total TODAs</div><div class="value"><?php echo (int)count($monitoringRows); ?></div></div>
                <div class="metric"><div class="label">Registered Drivers</div><div class="value"><?php echo (int)getRegisteredDriverCount(null, $drivers); ?></div></div>
                <div class="metric"><div class="label">Total Trips</div><div class="value"><?php echo (int)getTripStatisticsForToda(null, $trips)['totalTrips']; ?></div></div>
                <div class="metric"><div class="label">Rated Drivers</div><div class="value"><?php echo (int)getRatingStatisticsForToda(null, $ratings)['ratedDrivers']; ?></div></div>
            </div>
        </div>

        <div class="card">
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>TODA</th>
                            <th>Registered Drivers</th>
                            <th>Validated Drivers</th>
                            <th>Total Trips</th>
                            <th>Completed Trips</th>
                            <th>Average Rating</th>
                            <th>Active Accounts</th>
                            <th>Status</th>
                            <th>Manage</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($monitoringRows)): ?>
                            <tr><td colspan="9" class="small">No TODAs created yet.</td></tr>
                        <?php endif; ?>

                        <?php foreach ($monitoringRows as $todaId => $row): ?>
                            <?php $t = $row['meta']; $active = !empty($t['active']); ?>
                            <tr>
                                <td>
                                    <strong><?php echo h($t['name'] ?? $todaId); ?></strong><br>
                                    <span class="small">Code: <?php echo h($t['code'] ?? '—'); ?></span><br>
                                    <span class="small">ID: <?php echo h($todaId); ?></span>
                                </td>
                                <td><?php echo (int)$row['drivers']['totalDrivers']; ?></td>
                                <td><?php echo (int)$row['drivers']['validatedDrivers']; ?></td>
                                <td><?php echo (int)$row['trips']['totalTrips']; ?></td>
                                <td><?php echo (int)$row['trips']['completedTrips']; ?></td>
                                <td><?php echo $row['ratings']['averageRating'] > 0 ? h(number_format((float)$row['ratings']['averageRating'], 1)) : '—'; ?></td>
                                <td><?php echo (int)$row['accounts']; ?> / 3</td>
                                <td>
                                    <?php if ($active): ?>
                                        <span class="tag tag-green">Active</span>
                                    <?php else: ?>
                                        <span class="tag tag-red">Disabled</span>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <details>
                                        <summary style="cursor:pointer; color:#3498db; font-weight:600;">Edit</summary>
                                        <form method="POST" style="margin-top:10px;">
                                            <input type="hidden" name="action" value="update" />
                                            <input type="hidden" name="toda_id" value="<?php echo h($todaId); ?>" />
                                            <label>Name</label>
                                            <input name="name" value="<?php echo h($t['name'] ?? ''); ?>" required />
                                            <div style="margin-top:10px;">
                                                <label>Code</label>
                                                <input name="code" value="<?php echo h($t['code'] ?? ''); ?>" />
                                            </div>
                                            <div style="margin-top:10px;">
                                                <label style="display:flex; gap:8px; align-items:center; font-weight:600; color:#2c3e50;">
                                                    <input type="checkbox" name="active" <?php echo $active ? 'checked' : ''; ?> /> Active
                                                </label>
                                            </div>
                                            <div style="margin-top:12px; display:flex; gap:8px; flex-wrap:wrap;">
                                                <button class="btn btn-primary" type="submit"><i class="fa-solid fa-floppy-disk"></i> Save</button>
                                            </div>
                                        </form>
                                        <form method="POST" onsubmit="return confirm('Delete this TODA? This removes the TODA record only.');" style="margin-top:10px;">
                                            <input type="hidden" name="action" value="delete" />
                                            <input type="hidden" name="toda_id" value="<?php echo h($todaId); ?>" />
                                            <button class="btn btn-danger" type="submit"><i class="fa-solid fa-trash"></i> Delete</button>
                                        </form>
                                    </details>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</body>
</html>
