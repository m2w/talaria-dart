import 'package:polymer/builder.dart';
        
main(args) {
  build(entryPoints: ['web/talaria.html'],
        options: parseOptions(['--deploy']));
}
