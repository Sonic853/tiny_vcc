import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiny_vcc/models/new_project_model.dart';
import 'package:tiny_vcc/models/projects_model.dart';
import 'package:tiny_vcc/repos/vcc_projects_repository.dart';
import 'package:tiny_vcc/routes/new_project_route.dart';
import 'package:tiny_vcc/routes/project_route.dart';
import 'package:tiny_vcc/routes/projects_route.dart';
import 'package:tiny_vcc/routes/settings_route.dart';
import 'package:tiny_vcc/services/vcc_service.dart';
import 'package:window_size/window_size.dart';

import 'models/project_model.dart';

void main() {
  runApp(MyApp(
    vcc: VccService(),
  ));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required this.vcc}) : vccData = VccProjectsRepository(vcc);

  final VccService vcc;
  final VccProjectsRepository vccData;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    setWindowTitle('Tiny VCC');
    return MaterialApp(
      title: 'Tiny VCC',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      initialRoute: ProjectsRoute.routeName,
      routes: {
        ProjectsRoute.routeName: (context) =>
            ChangeNotifierProvider<ProjectsModel>(
              create: (context) => ProjectsModel(vccData),
              child: const ProjectsRoute(),
            ),
        NewProjectRoute.routeName: (context) =>
            ChangeNotifierProvider<NewProjectModel>(
              create: (context) => NewProjectModel(vcc),
              child: NewProjectRoute(),
            ),
        SettingsRoute.routeName: ((context) => const SettingsRoute(counter: 1)),
      },
      onGenerateRoute: (settings) {
        if (settings.name == ProjectRoute.routeName) {
          final args = settings.arguments as ProjectRouteArguments;
          return MaterialPageRoute(
            builder: ((context) => ChangeNotifierProvider<ProjectModel>(
                  create: (context) => ProjectModel(vcc, args.project),
                  child: const ProjectRoute(),
                )),
          );
        }
      },
    );
  }
}
