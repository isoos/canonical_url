import 'package:path/path.dart' as p;

/// The UrlCanonicalizer is used for the process of converting an URL into a
/// canonical (normalized) form.
class UrlCanonicalizer {
  final bool sort;
  final bool sortValues;
  final List<String> order;
  final List<String> whitelist;
  final List<String> blacklist;
  final bool removeFragment;

  UrlCanonicalizer({
    this.sort = true,
    this.sortValues = false,
    this.order,
    this.removeFragment = false,
    this.whitelist,
    this.blacklist,
  });

  T canonicalize<T>(T url, {T context}) {
    final uri = url is String ? Uri.parse(url) : url as Uri;
    final contextUri = context is String ? Uri.parse(context) : context as Uri;
    final canonical = _canonicalize(_contextualize(uri, contextUri));
    return (url is String ? canonical.toString() : canonical) as T;
  }

  Uri _contextualize(Uri uri, Uri context) {
    if (context == null) return uri;
    if (uri.hasScheme && uri.host != null) return uri;

    String path;
    if (uri.path.startsWith('/')) {
      path = uri.path;
    } else {
      path = p.canonicalize(p.join(_dirname(context.path), uri.path));
      if (uri.path.endsWith('/') && !path.endsWith('/')) {
        path = '$path/';
      }
    }
    return context.replace(
      path: path,
      queryParameters: uri.queryParametersAll,
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
    final Map<String, List<String>> params = _params(uri);
    final fragment =
        (removeFragment || !(uri.hasFragment && uri.fragment.isNotEmpty))
            ? null
            : uri.fragment;
    final int port =
        uri.hasPort && !_matchesPort(scheme, uri.port) ? uri.port : null;
    String path;
    if (uri.hasAbsolutePath) {
      path = p.canonicalize(uri.path);
      if (uri.path.endsWith('/') && !path.endsWith('/')) {
        path = '$path/';
      }
    } else {
      path = uri.path;
    }
    final host = uri.host?.toLowerCase();
    return Uri(
      scheme: scheme,
      host: host == null || host.isEmpty ? null : host,
      port: port,
      path: path,
      queryParameters: params == null || params.isEmpty ? null : params,
      fragment: fragment,
    );
  }

  Map<String, List<String>> _params(Uri uri) {
    Map<String, List<String>> params;
    if (uri.hasQuery) {
      final map = Map<String, List<String>>.from(uri.queryParametersAll);
      blacklist?.forEach(map.remove);
      if (whitelist != null) {
        map.removeWhere((key, value) => !whitelist.contains(key));
      }
      if (map.isNotEmpty) {
        params = <String, List<String>>{};
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
            keys = map.keys.where((s) => order == null || !order.contains(s));
          }
          for (String key in keys) {
            params[key] = map[key];
          }
        }
        if (sortValues) {
          params = params.map((key, values) {
            if (values.length > 1) {
              values = List<String>.from(values);
              values.sort();
            }
            return MapEntry(key, values);
          });
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
