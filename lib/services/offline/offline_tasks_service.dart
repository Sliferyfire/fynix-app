import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fynix/models/task_model.dart';
import 'package:intl/intl.dart';
import 'package:localstore/localstore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

class OfflineTasksService with ChangeNotifier {
  List<Tasks> tasks = [];
  List<Tasks> tasksDia = [];

  final db = Localstore.instance;
  final _supabase = Supabase.instance.client;
  bool _isOnline = false;
  List<Map<String, dynamic>> _tasks = [];

  bool isLoading = false;
  bool isSaving = false;

  Tasks? taskSeleccionado;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  OfflineTasksService() {
    initAppServices();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> initAppServices() async {
    await loadLocal();
    await _syncToSupabase();
    await actualizarTareasAtrasadas();
    await listenConnection();
  }

  String getStatus(Tasks t) {
    final hoy = DateTime.now();
    final fechaHoy = DateTime(hoy.year, hoy.month, hoy.day);

    final fechaTask = DateTime(
      t.fechaFinalizacion.year,
      t.fechaFinalizacion.month,
      t.fechaFinalizacion.day,
    );

    if (t.completado == true) return 'completado';
    if (t.status == 'deleted') return 'deleted';

    if (fechaTask.isBefore(fechaHoy)) {
      return 'atrasado';
    } else {
      return 'pendiente';
    }
  }

  Future<void> listenConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = result.first != ConnectivityResult.none;

      if (_isOnline) await _syncToSupabase();

      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        results,
      ) async {
        final wasOffline = !_isOnline;
        _isOnline = results.first != ConnectivityResult.none;

        debugPrint("-----Conexión cambió: $_isOnline");

        if (_isOnline && wasOffline) {
          debugPrint("-----Reconectado, sincronizando...");
          await _syncToSupabase();
        }

        notifyListeners();
      });
    } catch (e) {
      debugPrint("-----Error listen connection: $e");
    }
  }

  Future<void> loadLocal() async {
    try {
      isLoading = true;
      final data = await db.collection('TAREAS').get() ?? {};
      _tasks =
          data.entries
              .map((e) {
                final Map<String, dynamic> value = Map<String, dynamic>.from(
                  e.value as Map,
                );
                return <String, dynamic>{'id': e.key, ...value};
              })
              .toList()
              .reversed
              .toList();

      tasks = _tasks.map((task) => Tasks.fromMap(task)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("-----Error load local: $e");
    }
  }

  Future<void> obtenerTasksDia(DateTime diaSeleccionado) async {
    try {
      String dia = DateFormat('yyyy-MM-dd').format(diaSeleccionado);

      List<Tasks> tareasFiltradas =
          _tasks
              .map((task) => Tasks.fromMap(task))
              .where(
                (t) =>
                    DateFormat('yyyy-MM-dd').format(t.fechaFinalizacion) == dia,
              )
              .toList();

      tasksDia = tareasFiltradas;
      notifyListeners();
    } catch (e) {
      debugPrint("-----Error obtenerTasksDia: $e");
    }
  }

  Future<void> actualizarTareasAtrasadas() async {
    try {
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day); 

      for (var task in _tasks) {
        final fechaTask = DateTime.parse(task['fechaFinalizacion']);
        
        final fechaTaskSoloDia = DateTime(fechaTask.year, fechaTask.month, fechaTask.day);

        if (fechaTaskSoloDia.isBefore(hoy) &&
            (task['status'] != 'completado' && task['status'] != 'deleted')) {
          
          task['status'] = 'atrasado';
          task['pendingSync'] = true;
          await db.collection('TAREAS').doc(task['id']).set(task);
        }
      }

      if (_isOnline) await _syncToSupabase();

      notifyListeners();
    } catch (e) {
      debugPrint("-----Error al actualizar atrasadas offline: $e");
    }
  }

  Future<void> updateTask(Tasks t) async {
    try {
      isSaving = true;
      final userId = _supabase.auth.currentUser?.id;

      String status = getStatus(t);

      final updatedTask = {
        'id': t.id,
        'user_id': userId,
        'nombre': t.nombre,
        'descripcion': t.descripcion,
        'fechaFinalizacion': t.fechaFinalizacion.toIso8601String(),
        'categoria': t.categoria,
        'status': status,
        'completado': t.completado,
        'pendingSync': true,
      };

      await db.collection('TAREAS').doc(t.id.toString()).set(updatedTask);

      final index = _tasks.indexWhere((task) => task['id'] == t.id);
      if (index != -1) _tasks[index] = updatedTask;

      await loadLocal();

      if (_isOnline) await _syncToSupabase();

      isSaving = false;
      notifyListeners();
    } catch (e) {
      debugPrint("-----Error al actualizar offline: $e");
    }
  }

  Future addUpdateTask(Tasks task) async {
    notifyListeners();

    if (task.id == null) {
      await addTask(task);
    } else {
      await updateTask(task);
    }

    notifyListeners();
  }

  Future<void> addTask(Tasks t) async {
    try {
      isSaving = true;

      final userId = _supabase.auth.currentUser?.id;
      final id = uuid.v4();
      String status = getStatus(t);

      final task = {
        'id': id,
        'user_id': userId,
        'nombre': t.nombre,
        'descripcion': t.descripcion,
        'fechaFinalizacion': t.fechaFinalizacion.toIso8601String(),
        'categoria': t.categoria,
        'status': status,
        'completado': false,
        'pendingSync': true,
      };
      await db.collection('TAREAS').doc(id.toString()).set(task);
      _tasks.insert(0, task);

      await loadLocal();

      if (_isOnline) await _syncToSupabase();

      isSaving = false;
      notifyListeners();
    } catch (e) {
      debugPrint("-----Error agregar offline: $e");
    }
  }

  Future<void> updateCompletado(Tasks t) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      t.completado = !t.completado;

      String newStatus = getStatus(t);

      t.status = newStatus;

      notifyListeners();

      final task = t.toMap();

      task['status'] = newStatus;

      task['user_id'] = userId;
      task['fechaFinalizacion'] = t.fechaFinalizacion.toIso8601String();
      task['pendingSync'] = true;

      await db.collection('TAREAS').doc(task['id']).set(task);

      await loadLocal();
      notifyListeners();

      if (_isOnline) await _syncToSupabase();
    } catch (e) {
      debugPrint('-----Error update completado: $e');
    }
  }

  Future<void> deleteTaskOffline(Tasks t) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final task = {
        'id': t.id,
        'user_id': userId,
        'nombre': t.nombre,
        'descripcion': t.descripcion,
        'fechaFinalizacion': t.fechaFinalizacion.toIso8601String(),
        'categoria': t.categoria,
        'status': 'deleted',
        'completado': false,
        'pendingSync': true,
      };

      await db.collection('TAREAS').doc(t.id).set(task);

      await loadLocal();

      notifyListeners();
      if (_isOnline) await syncDeletedTask(t.id);
    } catch (e) {
      debugPrint('-----Error delete: $e');
    }
  }

  Future<void> syncDeletedTask(String? id) async {
    final doc = await db.collection('TAREAS').doc(id).get();

    if (doc == null || doc['status'] != 'deleted') return;

    try {
      await _supabase.from("TAREAS").delete().eq("id", id!);

      await db.collection('TAREAS').doc(id).delete();
      tasks.removeWhere((t) => t.id == id);
      tasksDia.removeWhere((t) => t.id == id);

      notifyListeners();
    } catch (e) {
      debugPrint("-----Error syncing delete: $e");
    }
  }

  Future<void> _syncToSupabase() async {
    try {
      isLoading = true;

      final data = await db.collection('TAREAS').get() ?? {};
      for (final entry in data.entries) {
        final t = entry.value;
        final id = t['id'];

        if (t['status'] == 'deleted') {
          try {
            await _supabase.from('TAREAS').delete().eq('id', id);

            await db.collection('TAREAS').doc(id).delete();
            tasks.removeWhere((x) => x.id == id);
            tasksDia.removeWhere((x) => x.id == id);
          } catch (e) {
            debugPrint('-----Error eliminando registro: $e');
          }
          continue;
        }

        if (t['pendingSync'] == true) {
          await _supabase.from('TAREAS').upsert({
            'id': t['id'],
            'user_id': t['user_id'],
            'nombre': t['nombre'],
            'descripcion': t['descripcion'],
            'fechaFinalizacion': t['fechaFinalizacion'],
            'categoria': t['categoria'],
            'status': t['status'],
            'completado': t['completado'],
          });
          t['pendingSync'] = false;
          await db.collection('TAREAS').doc(entry.key).set(t);
        }
      }
      await loadLocal();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("-----Error sync supabase: $e");
    }
  }
}
