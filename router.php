<?php

/**
 * Simple router for Laravel on PHP built-in server
 */

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// If requesting root, serve index.php
if ($uri === '/' || $uri === '') {
    require __DIR__.'/index.php';
    return;
}

// Check if it's a static file in the root
$file = __DIR__ . $uri;
if (!preg_match('/\.(php)$/', $uri) && file_exists($file) && is_file($file)) {
    $ext = pathinfo($file, PATHINFO_EXTENSION);
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
    ];
    
    if (isset($mimeTypes[$ext])) {
        header('Content-Type: ' . $mimeTypes[$ext]);
    }
    
    readfile($file);
    return;
}

// Otherwise, serve through Laravel
require __DIR__.'/index.php';
