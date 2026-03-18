const mix = require('laravel-mix');

/*
 |--------------------------------------------------------------------------
 | Mix Asset Management
 |--------------------------------------------------------------------------
 |
 | Mix provides a clean, fluent API for defining some Webpack build steps
 | for your Laravel application. By default, we are compiling the Sass
 | file for the application as well as bundling up all the JS files.
 |
 */

mix.js('resources/js/app.js', 'public/js');

// Disable minification to avoid UglifyJS compatibility issues on newer Node versions
mix.webpackConfig({ optimization: { minimize: false } });

// Ensure sass-loader uses dart-sass implementation to avoid node-sass requirements on newer Node versions
try {
  const sass = require('sass');
  mix.webpackConfig({
    module: {
      rules: [
        {
          test: /\.scss$/,
          loader: 'sass-loader',
          options: { implementation: sass },
        },
      ],
    },
  });
} catch (e) {
  // If sass isn't installed, fallback to default behaviour
}
