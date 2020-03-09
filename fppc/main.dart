import 'dart:core';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/which.dart';
import 'package:strings/strings.dart';

import 'package:mustache/mustache.dart';

bool verbose = false;

void transformDirectory(String source, String destination, Map data) {

  var inDir = Directory(source);
  var outDir = Directory(destination);

  List files = inDir.listSync(recursive: true);
  files.removeWhere((f) => f.path.endsWith("~"));

  List dirs = List.from(files);
  dirs.retainWhere((f) => f is Directory);
  dirs.forEach((d) {
      var od = d.path.replaceAll('mustache', data['package']['dart']);
      od = od.replaceAll('greetings', data['package']['dart']);
      var outDir = Directory(od);
      // print(outDir);
      outDir.createSync(recursive: true);
  });

  files.removeWhere((f) => f is Directory);

  List templates = List.from(files);

  files.removeWhere((f) => f.path.endsWith("mustache"));
  var outFiles = files.map((f) => File(f.path.replaceAll('mustache', data['package']['dart']).replaceAll('greetings', data['package']['dart'])));

  // print("FILES:");
  // outFiles.forEach((f) => print(f));

  files.forEach((f) {
      var of = f.path.replaceAll(RegExp('^mustache'), data['package']['dart']);
      of = of.replaceAll('greetings', data['package']['dart']);
      var outFile = File(of);
      print("COPY: $f");
      print(" => $outFile");
      f.copySync(of);
  });

  templates.retainWhere((f) => f.path.endsWith("mustache"));
  templates.forEach((t) {
      var out = t.path.replaceAll('greetings', data['package']['dart']);
      out = out.replaceAll('Greetings', data['plugin-class']);
      out = out.replaceFirst(RegExp('^mustache'), data['package']['dart'])
      .replaceFirst(RegExp('\.mustache\$'), '');
      print(t);
      print(" => $out");
      var contents;
      contents = t.readAsStringSync();
      var template = Template(contents, name: t.path, htmlEscapeValues: false);
      var newContents = template.renderString(data);
      File(out).writeAsStringSync(newContents);
  });
}

void validatePkgName(String pkg) {
  final r = RegExp(r"^[a-z_][a-z0-9_]*$");
  if ( ! r.hasMatch(pkg) ) {
    print("invalid package name: $pkg");
    exit(0);
  }
}

void main(List<String> args) {
  var parser = ArgParser();
  parser.addOption('package', abbr: 'p',
    valueHelp: "[a-z_][a-z0-9_]*",
    help: "Package name.",
    defaultsTo: 'greetings',
    callback: (pkg) => validatePkgName(pkg)
  );
  parser.addOption('org', abbr: 'o', defaultsTo: 'org.example',
    help: "Organization identifier",
    valueHelp: "Reverse domain name, e.g. org.example"
  );
  parser.addFlag('help', abbr: 'h', defaultsTo: false);
  parser.addFlag('verbose', abbr: 'v', defaultsTo: false);

  var results = parser.parse(args);

  verbose = results['verbose'];

  if (results['help']) {
    print(parser.usage);
    exit(0);
  }


  // "package" = Java package string, e.g. org.example.foo
  String dartPackage = results['package'];
  String javaPackage = results['org'] + "." + dartPackage;
  String pluginClass = dartPackage.split("_").map(
    (s)=> capitalize(s)).join();

  // FIXME: find best way to get these values.
  // They're for android/local.properties
  // print("resolvedExecutable: ${Platform.resolvedExecutable}");
  var androidExecutable = whichSync('android');
  // print("android exe: $androidExecutable");
  var android_sdk = path.joinAll(
    path.split(androidExecutable)
    ..removeLast()
    ..removeLast());

  var flutterExecutable = whichSync('flutter');
  // print("flutter exe: $flutterExecutable");
  var flutter_sdk = path.joinAll(
    path.split(flutterExecutable)
    ..removeLast()
    ..removeLast());


  var data = {
    "version" : {
      "android" : {
        "compile-sdk" : "28",
        "min-sdk"     : "16",
        "target-sdk" : "28",
        // androidx.test:runner:1.1.1
        // androidx.test.espresso:espresso-core:3.1.1'
      },
      "cupertino-icons": "\"^0.1.2\"",
      "e2e"     : "^0.2.0",
      "flutter" : "\">=1.12.8 <2.0.0\"",
      "gradle" : "3.5.0",
      "junit"  : "4.12",
      "kotlin" : "1.3.50",
      "meta"   : "^1.1.8",
      "mockito"  : "^4.1.1",
      "package" : "0.0.1",
      "pedantic" : "^1.8.0",
      "platform-detect" : "^1.4.0",
      "plugin-platform-interface" : "^1.0.2",
      "sdk"     : "\">=2.1.0 <3.0.0\"",
      "test"    : "^1.14.0",
    },
    "description" : {
      "component" : "A Flutter Platform-Portable Component.",
      "demo" : "Demo using a Flutter Platform-Portable Component."
    },
    "org" : results['org'],
    "package" : {
      "dart" : results['package'],
      "java" : javaPackage
    },
    "plugin-class" : pluginClass,
    "sdk" : {"flutter" : flutter_sdk,
      "android" : android_sdk
    }
  };

  if (verbose) print("data: $data");

  var inDir = "mustache";
  var outDir = data['package']['dart'];
  print("inDir: $inDir");
  print("outDir: $outDir");
  transformDirectory(inDir, outDir, data);

  // print(data);
}
