import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tiny_vcc/repos/unity_editors_repository.dart';
import 'package:tiny_vcc/repos/vcc_projects_repository.dart';
import 'package:tiny_vcc/repos/vpm_packages_repository.dart';
import 'package:tiny_vcc/services/vcc_service.dart';

class ProjectModel with ChangeNotifier {
  ProjectModel(
    this.vcc,
    UnityEditorsRepository unityRepo,
    VccProjectsRepository projectsRepo,
    VpmPackagesRepository packageRepo,
    this.project,
  )   : _unityRepo = unityRepo,
        _projectsRepo = projectsRepo,
        _packageRepo = packageRepo;

  final VccProject project;
  final VccService vcc;
  final UnityEditorsRepository _unityRepo;
  final VccProjectsRepository _projectsRepo;
  final VpmPackagesRepository _packageRepo;

  bool _isMakingBackup = false;
  bool get isDoingTask => _isMakingBackup;

//  List<VpmPackage> _packages = [];
  List<VpmDependency> _lockedDependencies = [];
  List<VpmDependency> get lockedDependencies => _lockedDependencies;

  final Map<String, Version> _selectedVersion = {};

  List<PackageItem> _packages = [];
  List<PackageItem> get packages => _packages;

  void getLockedDependencies() async {
    final locked = await project.getLockedDependencies();
    _lockedDependencies = locked;
    _updateList();
    notifyListeners();
  }

  void openProject() async {
    var editorVersion = await project.getUnityEditorVersion();
    final editor = await _unityRepo.getEditor(editorVersion);
    Process.run(editor!.path, ['-projectPath', project.path]);
  }

  Future<File> backup() async {
    _isMakingBackup = true;
    notifyListeners();
    final file = await compute(_projectsRepo.backup, project);
    _isMakingBackup = false;
    notifyListeners();
    return file;
  }

  void selectVersion(String name, Version version) async {
    _selectedVersion[name] = version;
    _updateList();
    notifyListeners();
  }

  void addPackage(String name, Version version) async {
    await vcc.addPackage(project.path, name, version.toString());
    getLockedDependencies();
  }

  void removePackage(String name) async {
    await vcc.removePackage(project.path, name);
    getLockedDependencies();
  }

  void updatePackage(String name, Version version) async {
    await vcc.updatePackage(project.path, name, version);
    getLockedDependencies();
  }

  void _updateList() {
    final List<PackageItem> list = [];
    final locked = _lockedDependencies
        .where((element) => _packageRepo.getLatest(element.name) != null)
        .map((e) {
      final latest = _packageRepo.getLatest(e.name);
      return PackageItem(
        name: e.name,
        displayName: latest!.displayName,
        description: latest.description,
        installedVersion: e.version,
        selectedVersion: _selectedVersion[e.name] ?? latest.version,
        versions: _packageRepo.getVersions(e.name),
      );
    });
    list.addAll(locked);
    final not = _packageRepo.packages
        ?.where(
            (p) => _lockedDependencies.where((e) => e.name == p.name).isEmpty)
        .map((e) => e.name)
        .toSet();
    if (not != null) {
      list.addAll(not.map((name) {
        final p = _packageRepo.getLatest(name);
        return PackageItem(
          name: name,
          displayName: p!.displayName,
          description: p.description,
          selectedVersion: _selectedVersion[p.name] ?? p.version,
          versions: _packageRepo.getVersions(name),
        );
      }));
    }
    _packages = list;
  }
}

class PackageItem {
  PackageItem({
    required this.name,
    required this.displayName,
    required this.description,
    this.installedVersion,
    this.selectedVersion,
    required this.versions,
  });

  final String name;
  final String displayName;
  final String description;
  final Version? installedVersion;
  final Version? selectedVersion;
  final List<VpmPackage> versions;
}
