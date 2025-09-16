# wkhtmltopdf (A CFML/Coldbox Wrapper) Version History

## v1.2.0 (September 16, 2025)

* Added support to specify the HTTP timeout
* Added support to retry a request that fails due to a timeout up to an arbitrary number of times

## v1.1.0 (June 27, 2022)

* Fixed ACF support by detecting the server engine and adding a .toByteArray() to the HTTP response
* Fixed URL/content detection across engines

## v1.0.1 (June 22, 2022)

* Fixed a typo in ModuleConfig.cfc blocking installs on Adobe Coldfusion (reported by https://github.com/alorne)

## v1.0.0 (January 4, 2020)

* Initial release