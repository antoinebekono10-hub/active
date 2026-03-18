<?php

/**
 * Simple router for Laravel on PHP built-in server
 */

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// Serve static files from root (this project has index.php at root)
$staticFile = __DIR__ . $uri;
if ($uri !== '/' && !preg_match('/\.(php)$/', $uri) && file_exists($staticFile) && is_file($staticFile)) {
    $ext = pathinfo($staticFile, PATHINFO_EXTENSION);
    $mimeTypes = [
        'css' => 'text/css',
        'js' => 'application/javascript',
        'png' => 'image/png',
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'gif' => 'image/gif',
        'svg' => 'image/svg+xml',
        'woff' => 'font/woff',
        'woff2' => 'font/woff2',
        'ttf' => 'font/ttf',
        'ico' => 'image/x-icon',
        'webp' => 'image/webp',
        'json' => 'application/json',
    ];
    
    if (isset($mimeTypes[$ext])) {
        header('Content-Type: ' . $mimeTypes[$ext]);
    }
    
    readfile($staticFile);
    return;
}

// Serve from root folder (index.php is at root)
$rootFile = __DIR__ . ($uri === '/' ? '/index.php' : $uri);
if (file_exists($rootFile) && is_file($rootFile)) {
    return false;
}

// Handle Laravel routes - use root index.php
require __DIR__.'/index.php';
