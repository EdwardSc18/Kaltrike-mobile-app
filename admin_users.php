<?php
require_once 'database.php';

requireAdminAuth();

header('Location: toda_management.php');
exit();
