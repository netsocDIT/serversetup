<?php
/**
 * The base configurations of the WordPress.
 *
 * This file has the following configurations: MySQL settings, Table Prefix,
 * Secret Keys, WordPress Language, and ABSPATH. You can find more information
 * by visiting {@link http://codex.wordpress.org/Editing_wp-config.php Editing
 * wp-config.php} Codex page. You can get the MySQL settings from your web host.
 *
 * This file is used by the wp-config.php creation script during the
 * installation. You don't have to use the web site, you can just copy this file
 * to "wp-config.php" and fill in the values.
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('WP_CACHE', true); //Added by WP-Cache Manager
define('DB_NAME', 'netsoc');

/** MySQL database username */
define('DB_USER', 'netsoc');

/** MySQL database password */
define('DB_PASSWORD', '%mysql-wordpress-password%');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'iu?]E3:>Gp_KR7qRbW x&?uo2%t`]w;v2$En;i7v:=K/lGL>&n{-:J%VYZ$ ZD=f');
define('SECURE_AUTH_KEY',  '|0iyX:l#eu+HF&16H~|YpWg_o&[!XU7WA#62XdKlnDIdCL[P:{ND<mx/42_UXOiZ');
define('LOGGED_IN_KEY',    'qz;EzE`r tQ~1 oZKt9]PNdu0@o&SxCM4AERQ*sb]7c:8das82 BzGq`1-AvkVzH');
define('NONCE_KEY',        '/kWPi{A5x$2Er<~gGp/.fWrM)y42cUi/B89rNX2v4n5||fuLy*DX@|@ee+6Zk>fo');
define('AUTH_SALT',        'HJB0MjZVGZ!ZM# cXwET8F(1W#qF+tx+hTnLBDvDDe2*J@RM|?u.~:JMd54.uk+~');
define('SECURE_AUTH_SALT', ']bMXlrfP5,}xCIJvRf,Nq?c!X>`;;Z1/zL#zOQgjQ;=~0yy-m(J8)%=|Q102Fs7)');
define('LOGGED_IN_SALT',   '-(}(-bI-OuKp*LD-8&mGF:2|vjTfvz+5,-bkEw;`{.N8pMdP{n sq-YSg*3MD5`.');
define('NONCE_SALT',       'U DM~1-.d}{}qVsM/4H=MZ}cQo?hJ4>rb!crZ-<F<_rZ-0vQe+[O(O+^|d8^PXl~');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * WordPress Localized Language, defaults to English.
 *
 * Change this to localize WordPress. A corresponding MO file for the chosen
 * language must be installed to wp-content/languages. For example, install
 * de_DE.mo to wp-content/languages and set WPLANG to 'de_DE' to enable German
 * language support.
 */
define('WPLANG', '');

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 */
define('WP_DEBUG', false);


#01 Changes by Mark Cunningham on 08-10-2011 to require SSL for login + admin
define('FORCE_SSL_ADMIN', true);
#01 end of changes



/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');

