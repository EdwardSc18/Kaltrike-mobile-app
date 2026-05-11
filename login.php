<?php
require_once 'database.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $identifier = trim($_POST['username'] ?? '');
    $password = (string)($_POST['password'] ?? '');

    if (adminLogin($identifier, $password)) {
        header('Location: ' . getDashboardRouteForCurrentUser());
        exit();
    }

    header('Location: index.php?error=1');
    exit();
}
?>