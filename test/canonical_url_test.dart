import 'package:test/test.dart';

import 'package:canonical_url/canonical_url.dart';

void main() {
  group('default', () {
    final canonicalizer = new UrlCanonicalizer();
    void ec(String from, String to) {
      expect(canonicalizer.canonicalize(from), to);
    }

    test('letter case', () {
      ec('HTTPS://EXAMPLE.COM', 'https://example.com');
      ec('HTTPS://EXAMPLE.COM/A', 'https://example.com/A');
      ec('HTTPS://EXAMPLE.COM/A#', 'https://example.com/A');
      ec('HTTPS://EXAMPLE.COM/A#D', 'https://example.com/A#D');
    });

    test('port removal', () {
      ec('http://example.com:80/abc', 'http://example.com/abc');
      ec('https://example.com:443/abc', 'https://example.com/abc');
    });

    test('port kept', () {
      ec('http://example.com:443/abc', 'http://example.com:443/abc');
      ec('https://example.com:80/abc', 'https://example.com:80/abc');
    });

    test('reorder parameters', () {
      ec('http://example.com/abc?a=1&c=2&b=3&d=4',
          'http://example.com/abc?a=1&b=3&c=2&d=4');
    });

    test('path canonicalized', () {
      ec('http://example.com/a/b/../c/./x.txt', 'http://example.com/a/c/x.txt');
    });
  });

  group('fixed parameter order', () {
    final canonicalizer = new UrlCanonicalizer(order: ['c', 'b', 'a']);
    void ec(String from, String to) {
      expect(canonicalizer.canonicalize(from), to);
    }

    test('only two', () {
      ec('http://example.com/abc?a=1&b=2', 'http://example.com/abc?b=2&a=1');
    });

    test('all three', () {
      ec('http://example.com/abc?a=1&c=3&b=2',
          'http://example.com/abc?c=3&b=2&a=1');
    });

    test('1+1', () {
      ec('http://example.com/abc?x=3&a=1', 'http://example.com/abc?a=1&x=3');
    });

    test('1+2', () {
      ec('http://example.com/abc?x=3&a=1&y=2',
          'http://example.com/abc?a=1&x=3&y=2');
    });
  });

  group('keep parameter order', () {
    test('no order otherwise', () {
      final canonicalizer = new UrlCanonicalizer(sort: false);
      expect(canonicalizer.canonicalize('http://example.com/abc?x=3&a=1&y=2'),
          'http://example.com/abc?x=3&a=1&y=2');
    });

    test('fixed order', () {
      final canonicalizer = new UrlCanonicalizer(order: ['y'], sort: false);
      expect(canonicalizer.canonicalize('http://example.com/abc?x=3&a=1&y=2'),
          'http://example.com/abc?y=2&x=3&a=1');
    });
  });

  group('keep parameters', () {
    final canonicalizer = new UrlCanonicalizer(whitelist: ['a']);
    void ec(String from, String to) {
      expect(canonicalizer.canonicalize(from), to);
    }

    test('no params', () {
      ec('http://example.com/abc?x=2', 'http://example.com/abc');
    });

    test('single param', () {
      ec('http://example.com/abc?a=2', 'http://example.com/abc?a=2');
    });

    test('more params', () {
      ec('http://example.com/abc?a=2&x=2', 'http://example.com/abc?a=2');
    });
  });

  group('remove parameters', () {
    final canonicalizer = new UrlCanonicalizer(blacklist: ['a']);
    void ec(String from, String to) {
      expect(canonicalizer.canonicalize(from), to);
    }

    test('no params', () {
      ec('http://example.com/abc', 'http://example.com/abc');
    });

    test('single param', () {
      ec('http://example.com/abc?a=2', 'http://example.com/abc');
    });

    test('more params', () {
      ec('http://example.com/abc?a=2&x=2', 'http://example.com/abc?x=2');
    });
  });

  group('remove fragments', () {
    final canonicalizer = new UrlCanonicalizer(removeFragment: true);
    void ec(String from, String to) {
      expect(canonicalizer.canonicalize(from), to);
    }

    test('empty fragment', () {
      ec('http://example.com/abc#', 'http://example.com/abc');
    });

    test('long fragment', () {
      ec('http://example.com/abc#xyz', 'http://example.com/abc');
    });
  });

  group('query parameters only', () {
    final canonicalizer = new UrlCanonicalizer(removeFragment: true);
    void ec(String from, String to) {
      expect(canonicalizer.canonicalize(from), to);
    }

    test('single param', () {
      final uri = new Uri(queryParameters: {'a': 'b'});
      expect(uri.toString(), '?a=b');
      ec(uri.toString(), '?a=b');
    });

    test('multiple param', () {
      final uri = new Uri(queryParameters: {'b': 'x', 'a': 'b'});
      ec(uri.toString(), '?a=b&b=x');
    });
  });

  group('contextualized url', () {
    final canonicalizer = new UrlCanonicalizer();
    void ec(String url, String context, String to) {
      expect(canonicalizer.canonicalize(url, context: context), to);
    }

    test('absolute from root', () {
      ec('/xyz?a=2#e1', 'http://example.com/abc?q=1',
          'http://example.com/xyz?a=2#e1');
    });

    test('relative path', () {
      ec('xyz?a=1', 'http://example.com/abc', 'http://example.com/xyz?a=1');
      ec('xyz?a=1', 'http://example.com/abc/',
          'http://example.com/abc/xyz?a=1');
      ec('xyz?a=1', 'http://example.com/a/bc', 'http://example.com/a/xyz?a=1');
      ec('xyz?a=1', 'http://example.com/a/bc/',
          'http://example.com/a/bc/xyz?a=1');
    });
  });
}
