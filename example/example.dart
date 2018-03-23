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
