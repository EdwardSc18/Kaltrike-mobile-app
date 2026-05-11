<?php
if (!defined('APP_DEBUG')) {
    $envDebug = getenv('KALTRIKE_DEBUG');
    define('APP_DEBUG', in_array(strtolower((string)$envDebug), ['1', 'true', 'yes', 'on'], true));
}

if (function_exists('ini_set')) {
    ini_set('log_errors', '1');
    ini_set('error_log', __DIR__ . '/firebase_errors.log');
    error_reporting(E_ALL);
    ini_set('display_errors', APP_DEBUG ? '1' : '0');
    ini_set('default_socket_timeout', '8');
}

if (!headers_sent()) {
    header('X-Content-Type-Options: nosniff');
    header('Referrer-Policy: strict-origin-when-cross-origin');
}

if (!APP_DEBUG && function_exists('ob_start') && extension_loaded('zlib') && !headers_sent() && !ini_get('zlib.output_compression') && ob_get_level() === 0) {
    ob_start('ob_gzhandler');
}

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
