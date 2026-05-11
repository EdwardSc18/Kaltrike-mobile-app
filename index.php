<?php require_once __DIR__ . '/app_bootstrap.php'; ?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kaltrike Admin - Login</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🛺</text></svg>">
    <link rel="preload" href="assets/login.css?v=16" as="style" onload="this.onload=null;this.rel='stylesheet'">
    <noscript><link rel="stylesheet" href="assets/login.css?v=16"></noscript>
</head>
<body>
    <div class="login-container">
        <div class="login-header">
            <h1>🛺 Kaltrike Admin</h1>
            <p>Tricycle Booking System</p>
        </div>
        
        <div class="login-form">
            <?php if (isset($_GET['error']) && $_GET['error'] == 1): ?>
                <div class="error-message">
                    Invalid username or password
                </div>
            <?php endif; ?>
            
            <form method="POST" action="login.php">
                <div class="form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" required>
                </div>
                
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" required>
                </div>
                
                <button type="submit" class="login-btn">Login</button>
            </form>
        </div>
    </div>
</body>
</html>