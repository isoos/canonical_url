import 'package:path/path.dart' as p;

/// The UrlCanonicalizer is used for the process of converting an URL into a
/// canonical (normalized) form.
class UrlCanonicalizer {
  final bool sort;
  final List<String> order;
  final List<String> whitelist;
  final List<String> blacklist;
  final bool removeFragment;

  UrlCanonicalizer({
    this.sort: true,
    this.order,
    this.removeFragment: false,
    this.whitelist,
    this.blacklist,
  });

  T canonicalize<T>(T url, {T context}) {
    final uri = url is String ? Uri.parse(url) : url;
    final contextUri = context is String ? Uri.parse(context) : context;
    final canonical = _canonicalize(_contextualize(uri, contextUri));
    return url is String ? canonical.toString() : canonical;
  }

  Uri _contextualize(Uri uri, Uri context) {
    if (context == null) return uri;
    if (uri.hasScheme && uri.host != null) return uri;

    final path = uri.path.startsWith('/')
        ? uri.path
        : p.canonicalize(p.join(_dirname(context.path), uri.path));
    return context.replace(
      path: path,
      queryParameters: uri.queryParameters,
      fragment: uri.fragment,
    );
  }

  String _dirname(String path) {
    if (path.endsWith('/')) return path;
    final list = p.split(path);
    list.removeLast();
    return list.join('/');
  }

  Uri _canonicalize(Uri uri) {
    final scheme = uri.scheme?.toLowerCase();
    final Map<String, String> params = _params(uri);
    final fragment =
        (removeFragment || !(uri.hasFragment && uri.fragment.isNotEmpty))
            ? null
            : uri.fragment;
    final int port =
        uri.hasPort && !_matchesPort(scheme, uri.port) ? uri.port : null;
    String path;
    if (uri.hasAbsolutePath) {
      path = p.canonicalize(uri.path);
    } else {
      path = uri.path;
    }
    return new Uri(
      scheme: scheme,
      host: uri.host?.toLowerCase(),
      port: port,
      path: path,
      queryParameters: params == null || params.isEmpty ? null : params,
      fragment: fragment,
    );
  }

  Map<String, String> _params(Uri uri) {
    Map<String, String> params;
    if (uri.hasQuery) {
      final map = new Map<String, String>.from(uri.queryParameters);
      blacklist?.forEach(map.remove);
      if (whitelist != null) {
        map.removeWhere((key, value) => !whitelist.contains(key));
      }
      if (map.isNotEmpty) {
        params = <String, String>{};
        order?.forEach((p) {
          if (map.containsKey(p)) {
            params[p] = map[p];
          }
        });
        if (params.length != map.length) {
          Iterable<String> keys;
          if (sort) {
            final Set<String> set = map.keys.toSet();
            if (order != null) {
              set.removeAll(order);
            }
            keys = set.toList()..sort();
          } else {
            keys = map.keys.where(
                    (s) => order == null || !order.contains(s));
          }
          for (String key in keys) {
            params[key] = map[key];
          }
        }
        assert(params.length == map.length);
      }
    }
    return params;
  }

  List<T> canonicalizeUrls<T>(Iterable<T> urls, {T context}) {
    return urls.map((T url) => canonicalize(url, context: context)).toList();
  }
}

bool _matchesPort(String scheme, int port) {
  if (port == null) return true;
  if (scheme == 'http' && port == 80) return true;
  if (scheme == 'https' && port == 443) return true;
  return false;
}