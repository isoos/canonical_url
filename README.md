# canonical_url

The `UrlCanonicalizer` is used for the process of converting an URL into a canonical (normalized) form. It will:

- make `scheme` and `host` lowercase
- remove `port` if it matches the default (80, 443)
- canonicalize `path` (e.g. `/a/../`, `/a/./`)
- sort query parameters (default)
- use query parameter ordering (optional)
- whitelist / blacklist parameters (optional)
- remove `fragment` (optional)

It can also calculate the `url` relative to a `context` (e.g. base url + relative link).

## Usage

A simple usage example:

````dart
import 'package:canonical_url/canonical_url.dart';

main() {
  final urlc = new UrlCanonicalizer(removeFragment: true);

  // prints http://example.com/b.txt
  print(urlc.canonicalize('http://example.com:80/a/../b.txt'));

  // prints https://example.com/abc
  print(urlc.canonicalize('https://example.com/abc#xyz'));

  // prints http://example.com/api?a=2&b=3&c=1
  print(urlc.canonicalize('http://example.com/api?c=1&a=2&b=3'));
}
````
