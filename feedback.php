<?php
require_once 'database.php';

requireAdminAuth();
requirePermission(PERM_FEEDBACK_VIEW);

$todas = getAllTodas();
$feedback = getPassengerCommentFeedbackRecords();

$startDate = $_GET['start_date'] ?? '';
$endDate = $_GET['end_date'] ?? '';
$todaFilter = $_GET['toda'] ?? '';

$isScopedTODA = (!isSuperAdmin() && currentAdminRole() !== ROLE_BPLO_VERIFIER);
if ($isScopedTODA) {
    $todaFilter = currentAdminTodaId();
}

$filtered = [];
foreach ($feedback as $id => $f) {
    if (!is_array($f)) continue;

    $comment = trim((string)($f['comment'] ?? ''));
    if ($comment === '') continue;

    $todaId = $f['todaId'] ?? null;
    $createdAt = parseTimestamp($f['createdAt'] ?? null) ?: 0;

    if ($todaFilter !== '' && (string)$todaId !== (string)$todaFilter) continue;

    if ($startDate !== '') {
        $sd = strtotime($startDate . ' 00:00:00');
        if ($createdAt < $sd) continue;
    }
    if ($endDate !== '') {
        $ed = strtotime($endDate . ' 23:59:59');
        if ($createdAt > $ed) continue;
    }

    $f['id'] = $id;
    $filtered[$id] = $f;
}

uasort($filtered, function($a, $b) {
    $ta = parseTimestamp($a['createdAt'] ?? null) ?: 0;
    $tb = parseTimestamp($b['createdAt'] ?? null) ?: 0;
    return $tb <=> $ta;
});

$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = max(10, min(100, (int)($_GET['per_page'] ?? 20)));
$feedbackPaginationResult = paginateAssociativeArray($filtered, $page, $perPage);
$filtered = $feedbackPaginationResult['items'];
$feedbackPagination = $feedbackPaginationResult['pagination'];

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
function fmtDate($ts) { return $ts ? date('M d, Y h:i A', $ts) : '—'; }
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Feedback - Kaltrike Admin</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background:#f5f6fa; color:#2c3e50; display:flex; min-height:100vh; }
        .main-content { flex:1; margin-left:250px; padding:25px; min-height:100vh; }
        .header { display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; padding-bottom:15px; border-bottom:2px solid #e0e0e0; }
        .header h1 { font-size:28px; font-weight:600; }
        .card { background:#fff; border-radius:12px; box-shadow:0 2px 10px rgba(0,0,0,0.08); padding:18px; margin-bottom:18px; }
        label { font-size:12px; color:#7f8c8d; font-weight:600; margin-bottom:6px; display:block; }
        input, select { width:100%; padding:10px 12px; border:1px solid #ddd; border-radius:8px; font-size:14px; }
        .row { display:flex; gap:10px; align-items:center; flex-wrap:wrap; }
        .btn { border:none; border-radius:8px; padding:10px 14px; cursor:pointer; font-weight:600; }
        .btn-secondary { background:#95a5a6; color:#fff; }
        table { width:100%; border-collapse:collapse; }
        th, td { padding:12px; border-bottom:1px solid #eee; text-align:left; vertical-align:top; }
        th { background:#fafafa; font-size:12px; letter-spacing:0.3px; text-transform:uppercase; color:#7f8c8d; }
        .tag { display:inline-block; padding:3px 8px; border-radius:999px; font-size:12px; background:#e8f4fc; color:#3498db; }
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
            <div>
                <h1><i class="fa-solid fa-comment-dots"></i> Feedback</h1>
                <p class="small" style="margin-top:6px;">Shows passenger comments only when a ride has an actual comment.</p>
            </div>
        </div>

        <div class="card">
            <div class="row" style="justify-content:space-between;">
                <div>
                    <h3 style="margin-bottom:6px;">Filter Passenger Comments</h3>
                    <div class="small">Ride comments are read live from Firebase and shown only when the passenger commented. Showing <?php echo ($feedbackPagination['total_items'] > 0 ? ($feedbackPagination['offset'] + 1) : 0); ?>-<?php echo min($feedbackPagination['offset'] + $feedbackPagination['per_page'], $feedbackPagination['total_items']); ?> of <?php echo $feedbackPagination['total_items']; ?> comment(s).</div>
                </div>
                <form method="GET" class="row">
                    <input type="date" name="start_date" value="<?php echo h($startDate); ?>" />
                    <input type="date" name="end_date" value="<?php echo h($endDate); ?>" />

                    <?php if (!$isScopedTODA): ?>
                        <select name="toda" style="width:220px;">
                            <option value="">All TODAs</option>
                            <?php foreach ($todas as $tid => $td): ?>
                                <option value="<?php echo h($tid); ?>" <?php echo ((string)$todaFilter===(string)$tid)?'selected':''; ?>><?php echo h($td['name'] ?? $tid); ?></option>
                            <?php endforeach; ?>
                        </select>
                    <?php else: ?>
                        <input type="text" value="<?php echo h(getTodaName($todaFilter)); ?>" disabled style="width:220px;" />
                    <?php endif; ?>

                    <button class="btn btn-secondary" type="submit"><i class="fa-solid fa-filter"></i> Apply</button>
                </form>
            </div>
        </div>

        <div class="card">
            <h3 style="margin-bottom:10px;">Passenger Comment Records</h3>
            <table>
                <thead>
                    <tr>
                        <th>Created</th>
                        <th>TODA</th>
                        <th>Driver Name</th>
                        <th>Passenger Name</th>
                        <th>Rating</th>
                        <th>Comment</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($filtered)): ?>
                        <tr><td colspan="6" class="small">No passenger comments found.</td></tr>
                    <?php endif; ?>

                    <?php foreach ($filtered as $id => $f): ?>
                        <?php
                            $ts = parseTimestamp($f['createdAt'] ?? null) ?: 0;
                            $todaName = getTodaName($f['todaId'] ?? null);
                            $rating = $f['rating'] ?? '';
                        ?>
                        <tr>
                            <td><?php echo h(fmtDate($ts)); ?><br><span class="small">ID: <?php echo h($id); ?></span></td>
                            <td><?php echo h($todaName); ?></td>
                            <td>
                                <div><?php echo h(($f['driverName'] ?? '') !== '' ? $f['driverName'] : ($f['driverId'] ?? '—')); ?></div>
                                <div class="small">Driver ID: <?php echo h($f['driverId'] ?? '—'); ?></div>
                            </td>
                            <td>
                                <div><?php echo h(($f['commuterName'] ?? '') !== '' ? $f['commuterName'] : ($f['commuterId'] ?? '—')); ?></div>
                                <div class="small">Passenger record</div>
                            </td>
                            <td><?php echo $rating === '' || $rating === null ? '—' : '<span class="tag">' . h(number_format((float)$rating, 1)) . '</span>'; ?></td>
                            <td><?php echo nl2br(h($f['comment'] ?? '')); ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
            <?php if (($feedbackPagination['total_pages'] ?? 1) > 1): ?>
            <div style="display:flex; justify-content:space-between; align-items:center; gap:12px; flex-wrap:wrap; padding-top:16px;">
                <div class="small">Page <?php echo $feedbackPagination['current_page']; ?> of <?php echo $feedbackPagination['total_pages']; ?></div>
                <div class="row" style="justify-content:flex-end;">
                    <?php if ($feedbackPagination['has_previous']): ?><a class="btn btn-secondary" href="<?php echo h(buildQueryUrl(['page' => $feedbackPagination['current_page'] - 1])); ?>">Previous</a><?php endif; ?>
                    <?php if ($feedbackPagination['has_next']): ?><a class="btn btn-secondary" href="<?php echo h(buildQueryUrl(['page' => $feedbackPagination['current_page'] + 1])); ?>">Next</a><?php endif; ?>
                </div>
            </div>
            <?php endif; ?>
</body>
</html>
