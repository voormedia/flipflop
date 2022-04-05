## 2.7.0

* Removing .css extension from render partial and adding it to html handler to correctly render the erb file.
  * Fixes Rails 6 & 7 deprecation: `Render file with extension is deprecated`

## 2.6.0

* Failure to load strategies in test environments will result in a warning instead of an error. This should aid in running Rake tasks.

## 2.5.0

* Add Sequel strategy. ActiveRecord/Sequel can be used side by side.
* Rails 6 compatibility.

## 2.4.0

* Add location of feature definition.
* Raise error for undefined feature or strategy keys. This change can potentially break test cases that use dummy keys.

## 2.3.1

* Fixed backwards compatibility of strategies controller. The incompatibility was introduced in 2.3.0. (@jcoyne)

## 2.3.0

* Support for Rails API only apps.
* Features can now be grouped in the dashboard.
* Features can now be added to Rails engines and loaded with an initializer.
* The dashboard (including features and strategies) can be translated.
* Removed Rails asset pipeline dependency.
