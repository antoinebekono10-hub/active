<?php

/**
 * Router script for PHP built-in server
 * Handles static files properly
 */

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// Serve static files directly
if ($uri !== '/' && $uri !== '' && !preg_match('/\.(php)$/', $uri)) {
    $file = __DIR__ . $uri;
    if (file_exists($file) && is_file($file)) {
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
            'eot' => 'application/vnd.ms-fontobject',
            'ico' => 'image/x-icon',
            'webp' => 'image/webp',
            'json' => 'application/json',
            'xml' => 'application/xml',
        ];
        
        if (isset($mimeTypes[$ext])) {
            header('Content-Type: ' . $mimeTypes[$ext]);
        }
        
        readfile($file);
        return true;
    }
}

// Fall back to Laravel
require __DIR__.'/index.php';
