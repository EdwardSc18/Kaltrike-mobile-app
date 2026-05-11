<?php
require_once 'database.php';

if (!isLoggedIn()) return;

$current = basename($_SERVER['PHP_SELF']);
$role = currentAdminRole();
$isTodaMonitor = $role === ROLE_TODA_MONITOR;
$isBploVerifier = $role === ROLE_BPLO_VERIFIER;
$dashboardHref = getDashboardRouteForCurrentUser();
$ratingsHref = getRatingsRouteForCurrentUser();
$driversHref = getDriversRouteForCurrentUser();
$sidebarTitle = $isBploVerifier ? 'BPLO Console' : ($isTodaMonitor ? getTodaName(currentAdminTodaId()) . ' Monitor' : 'Kaltrike Admin');
$sidebarContext = $isBploVerifier ? 'Verification Workspace' : ($isTodaMonitor ? 'Assigned TODA View' : 'Super Admin');

function navActive($file, $current) {
    return $file === $current ? 'active' : '';
}
?>
<link rel="stylesheet" href="assets/sidebar.css?v=19">
<button class="sidebar-toggle" type="button" aria-label="Toggle navigation" aria-controls="appSidebar" aria-expanded="false" data-sidebar-toggle>
    <i class="fa-solid fa-bars"></i>
</button>
<div class="sidebar-backdrop" data-sidebar-backdrop></div>
<div class="sidebar" id="appSidebar">
    <div class="logo">
        <div class="logo-icon" aria-hidden="true">🛺</div>
        <div class="logo-copy">
            <span><?php echo htmlspecialchars($sidebarTitle); ?></span>
            <small><?php echo htmlspecialchars($sidebarContext); ?></small>
        </div>
    </div>

    <ul class="nav-links">
        <?php if (hasPermission(PERM_DASHBOARD_VIEW)): ?>
        <li>
            <a href="<?php echo htmlspecialchars($dashboardHref); ?>" class="<?php echo navActive(basename($dashboardHref), $current); ?>">
                <i class="fa-solid fa-chart-line"></i>
                <span>Dashboard</span>
            </a>
        </li>
        <?php endif; ?>

        <?php if (hasPermission(PERM_DRIVERS_VIEW)): ?>
        <li>
            <a href="<?php echo htmlspecialchars($driversHref); ?>" class="<?php echo navActive(basename($driversHref), $current); ?>">
                <i class="fa-solid fa-user-tie"></i>
                <span>Drivers</span>
            </a>
        </li>
        <?php endif; ?>

        <?php if (!$isTodaMonitor && hasPermission(PERM_COMMUTERS_VIEW)): ?>
        <li>
            <a href="commuters.php" class="<?php echo navActive('commuters.php', $current); ?>">
                <i class="fa-solid fa-users"></i>
                <span>Commuters</span>
            </a>
        </li>
        <?php endif; ?>

        <?php if (hasPermission(PERM_TRIPS_VIEW)): ?>
        <li>
            <a href="trips.php" class="<?php echo navActive('trips.php', $current); ?>">
                <i class="fa-solid fa-route"></i>
                <span>Trips</span>
            </a>
        </li>
        <?php endif; ?>

        <?php if (hasPermission(PERM_RATINGS_VIEW)): ?>
        <li>
            <a href="<?php echo htmlspecialchars($ratingsHref); ?>" class="<?php echo navActive(basename($ratingsHref), $current); ?>">
                <i class="fa-solid fa-star"></i>
                <span>Ratings</span>
            </a>
        </li>
        <?php endif; ?>

        <?php if (hasPermission(PERM_FEEDBACK_VIEW)): ?>
        <li>
            <a href="feedback.php" class="<?php echo navActive('feedback.php', $current); ?>">
                <i class="fa-solid fa-comment-dots"></i>
                <span>Feedback</span>
            </a>
        </li>
        <?php endif; ?>

        <?php if ($isBploVerifier && hasPermission(PERM_VERIFICATION_VIEW)): ?>
        <li>
            <a href="bplo_verification.php" class="<?php echo navActive('bplo_verification.php', $current); ?>">
                <i class="fa-solid fa-shield-halved"></i>
                <span>Verification</span>
            </a>
        </li>
        <?php endif; ?>

        <?php if (hasPermission(PERM_TODAS_MANAGE)): ?>
        <li>
            <a href="toda_management.php" class="<?php echo navActive('toda_management.php', $current); ?>">
                <i class="fa-solid fa-building-user"></i>
                <span>TODAs</span>
            </a>
        </li>
        <?php endif; ?>

        <li>
            <a href="logout.php">
                <i class="fa-solid fa-right-from-bracket"></i>
                <span>Logout</span>
            </a>
        </li>
    </ul>

    <div class="sidebar-user-card">
        <div><strong><?php echo htmlspecialchars($_SESSION['admin_username'] ?? ''); ?></strong></div>
        <div class="sidebar-role"><?php echo htmlspecialchars($_SESSION['admin_role'] ?? ''); ?></div>
        <?php if (!empty($_SESSION['admin_toda_id'])): ?>
            <div><?php echo htmlspecialchars(getTodaName($_SESSION['admin_toda_id'])); ?></div>
        <?php endif; ?>
    </div>
</div>
<script src="assets/sidebar.js?v=19" defer></script>
