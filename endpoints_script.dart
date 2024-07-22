import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File("C:/Users/User/Downloads/clinic.postman_collection4.json");
  final contents = await file.readAsString();
  final endpoints = <String>[];
  final postmanCollection = jsonDecode(contents);
  final outerItems = postmanCollection['item'];
  final nameCounts = <String, int>{};

  for (final outerItem in outerItems) {
    final items = outerItem['item'];
    print(outerItem);
    if (items == null) {
      final item = outerItem;
      final request = item['request'];
      final url = request['url'];
      final endpoint = extractEndpoint(url);
      final name = item['name'];

      var formattedName = toCamelCase(name);
      formattedName = resolveDuplicateName(formattedName, nameCounts);
      endpoints
          .add("  static const String $formattedName = '\$baseUrl$endpoint';");
      continue;
    }
    for (final item in items) {
      final request = item['request'];
      final url = request['url'];
      final endpoint = extractEndpoint(url);
      final name = item['name'];

      var formattedName = toCamelCase(name);
      formattedName = resolveDuplicateName(formattedName, nameCounts);
      endpoints
          .add("  static const String $formattedName = '\$baseUrl$endpoint';");
    }
  }

  final dartFileContent = generateDartFileContent(endpoints);

  final outputFile = File('C:/Users/User/Downloads/end_points.dart');
  await outputFile.writeAsString(dartFileContent);

  print('Endpoints Dart file generated successfully.');
}

String toCamelCase(String input) {
  final words = input.split(RegExp(r'[_\s]'));
  final formattedWords = words.mapIndexed((index, word) {
    if (index == 0) {
      return word.toLowerCase();
    } else {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }
  }).toList();
  return formattedWords.join('');
}

extension MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}

String extractEndpoint(dynamic url) {
  if (url is String) {
    return cleanUrl(url);
  } else if (url is Map) {
    if (url.containsKey('raw')) {
      return cleanUrl(url['raw']);
    } else if (url.containsKey('path')) {
      final path = url['path'];
      if (path is List) {
        return path.join('/');
      } else if (path is String) {
        return path;
      }
    }
  }
  return '';
}

String cleanUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    final uri = Uri.parse(url);
    return uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
  } else {
    final uri = Uri.parse('http://$url');
    return uri.path;
  }
}

String resolveDuplicateName(String name, Map<String, int> nameCounts) {
  if (nameCounts.containsKey(name)) {
    final count = nameCounts[name]! + 1;
    nameCounts[name] = count;
    return name + count.toString();
  } else {
    nameCounts[name] = 1;
    return name;
  }
}

String generateDartFileContent(List<String> endpoints) {
  final baseUrl = "  static const String baseUrl = 'http://10.0.2.2:8000';";
  final content = StringBuffer()
    ..writeln('class EndPoints {')
    ..writeln(baseUrl)
    ..writeln()
    ..writeln(endpoints.join('\n'))
    ..writeln('}');

  return content.toString();
}
