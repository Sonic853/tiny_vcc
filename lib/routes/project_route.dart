import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../globals.dart';
import '../models/project_model.dart';
import '../services/vcc_service.dart';
import '../utils.dart';
import '../widgets/package_list_item.dart';

class ProjectRouteArguments {
  ProjectRouteArguments({required this.project});

  final VccProject project;
}

class ProjectRoute extends StatefulWidget {
  const ProjectRoute({super.key});

  static const String routeName = '/project';

  @override
  State<ProjectRoute> createState() => _ProjectRoute();
}

class _ProjectRoute extends State<ProjectRoute> with RouteAware {
  ScaffoldFeatureController? _unityBannerController;

  void _refreshLockedDependencies() {
    final model = Provider.of<ProjectModel>(context, listen: false);
    model.getLockedDependencies();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    _refreshLockedDependencies();
  }

  ProjectModel _model(BuildContext context) {
    return Provider.of<ProjectModel>(context, listen: false);
  }

  void _didClickOpenFolder(BuildContext context) {
    final uri = Uri.file(_model(context).project.path);
    launchUrl(uri);
  }

  void _didClickMakeBackup(BuildContext context) async {
    final projectName = _model(context).project.name;
    showProgressDialog(context, 'Backing up $projectName');
    File file;
    try {
      file = await _model(context).backup();
    } catch (error) {
      Navigator.pop(context);
      showAlertDialog(context,
          title: 'Backup Error',
          message: 'Failed to back up $projectName.\n\n$error');
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.pop(context);

    final showFile = await showDialog(
      context: context,
      builder: ((context) => AlertDialog(
            title: const Text('Made Backup'),
            content: Text(file.path),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Show Me'),
              ),
            ],
          )),
    );
    if (showFile != null && showFile) {
      launchUrl(Uri.file(file.parent.path));
    }
  }

  void _showMessageToCloseUnity() {
    if (_unityBannerController != null) {
      return;
    }
    _unityBannerController =
        scaffoldKey.currentState?.showMaterialBanner(MaterialBanner(
      content: const Text(
          'Packages have been changed. Close and reopen Unity project to apply changes.'),
      actions: [
        TextButton(
            onPressed: () {
              _unityBannerController?.close();
              _unityBannerController = null;
            },
            child: const Text('Dismiss')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ProjectModel>(
            builder: (context, model, child) => Text(model.project.name)),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<ProjectModel>(
                  builder: (context, model, child) => Text(model.project.path)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Consumer<ProjectModel>(
                    builder: ((context, value, child) => OutlinedButton(
                        onPressed: value.isDoingTask
                            ? null
                            : () {
                                value.openProject();
                              },
                        child: const Text('Open Project'))),
                  ),
                  Consumer<ProjectModel>(
                    builder: ((context, value, child) => OutlinedButton(
                        onPressed: value.isDoingTask
                            ? null
                            : () {
                                _didClickOpenFolder(context);
                              },
                        child: const Text('Open Folder'))),
                  ),
                  Consumer<ProjectModel>(
                    builder: ((context, value, child) => OutlinedButton(
                        onPressed: value.isDoingTask
                            ? null
                            : () {
                                _didClickMakeBackup(context);
                              },
                        child: const Text('Make Backup'))),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<ProjectModel>(
            builder: (context, model, child) => _buildList(model),
          ),
        ),
      ]),
    );
  }

  Widget _buildList(ProjectModel model) {
    return ListView.builder(
      itemCount: model.packages.length,
      itemBuilder: (context, index) {
        final dep = model.packages[index];
        return PackageListItem(
          item: dep,
          onSelect: (name, version) {
            model.selectVersion(name, version);
          },
          onClickAdd: (name) {
            model.addPackage(name, dep.selectedVersion!);
            _showMessageToCloseUnity();
          },
          onClickRemove: (name) {
            model.removePackage(name);
            _showMessageToCloseUnity();
          },
          onClickUpdate: ((name) {
            model.updatePackage(name, dep.selectedVersion!);
            _showMessageToCloseUnity();
          }),
        );
      },
    );
  }
}
