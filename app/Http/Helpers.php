<?php
// Lightweight helper to resolve asset URLs in Railway deployments
// Usage: railway_asset('css/app.css')
if (!function_exists('railway_asset')) {
    function railway_asset($path) {
        // If Laravel's asset() helper is available, use it to preserve URL generation logic
        if (function_exists('asset')) {
            return asset($path);
        }
        // Fallback: return a root-relative URL
        return '/' . ltrim($path, '/');
    }
}
