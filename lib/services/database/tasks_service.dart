import 'package:flutter/material.dart';
import 'package:fynix/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TasksService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Tasks> tasks = [];
  List<Tasks> tasksDia = [];

  bool isLoading = false;
  bool isSaving = false;

  Tasks? taskSeleccionado;

  TasksService() {
    // obtenerTasks();
    // obtenerTasksDia(DateTime.now());
  }

  // Metodo para obtener las tareas de la base de datos
  Future obtenerTasks() async {
    try {
      isLoading = true;
      notifyListeners();
      await actualizarTareasAtrasadas();
      final response = await _supabase.from('TAREAS').select('*');
      tasks = response.map((e) => Tasks.fromMap(e)).toList();
      notifyListeners();
      isLoading = false;
      return response;
    } catch (e) {
      debugPrint('Error obtener: $e');
    }
  }

  // Metodo para obtener las tareas por dia
  Future obtenerTasksDia(DateTime diaSeleccionado) async {
    try {
      // isLoading = true;
      notifyListeners();
      final response = await _supabase
          .from('TAREAS')
          .select('*')
          .eq('fechaFinalizacion', diaSeleccionado.toIso8601String());
      tasksDia = response.map((e) => Tasks.fromMap(e)).toList();
      // isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Error obtener por dia: $e');
    }
  }

  // Metodo para actualizar status de tareas que ya estan atrasadoas
  Future actualizarTareasAtrasadas() async {
    try {
      await _supabase
          .from("TAREAS")
          .update({'status': 'atrasado'})
          .lt("fechaFinalizacion", DateTime.now().toIso8601String())
          .neq("status", "completado");

      notifyListeners();
    } catch (e) {
      debugPrint('Error stado tareas: $e');
    }
  }

  // Metodo para actualizar tareas
  Future<int?> updateTask(Tasks task) async {
    try {
      await _supabase
          .from("TAREAS")
          .update({
            'nombre': task.nombre,
            'descripcion': task.descripcion,
            'fechaFinalizacion': task.fechaFinalizacion.toIso8601String(),
            'categoria': task.categoria,
            // 'user_id': userId,
          })
          .eq('id', task.id!);

      final index = tasks.indexWhere((element) => element.id == task.id);
      tasks[index] = task;

      notifyListeners();
      // return task.id!;
    } catch (e) {
      debugPrint('Error update: $e');
      return null;
    }
  }

  // Metodo que decide si añadir o actualizar una tarea
  Future addUpdateTask(Tasks task) async {
    isSaving = true;
    notifyListeners();

    if (task.id == null) {
      await addTask(task);
    } else {
      await updateTask(task);
    }

    isSaving = false;
    notifyListeners();
  }

  // Metodo para agregar una tarea nueva
  Future<int?> addTask(Tasks task) async {
    try {
      final hoy = DateTime.now();
      final fechaHoy = DateTime(hoy.year, hoy.month, hoy.day);

      final fechaTask = DateTime(
        task.fechaFinalizacion.year,
        task.fechaFinalizacion.month,
        task.fechaFinalizacion.day,
      );

      late String status;
      if (fechaTask.isBefore(fechaHoy)) {
        status = 'atrasado';
      } else {
        status = 'pendiente';
      }

      final response =
          await _supabase
              .from("TAREAS")
              .insert({
                'nombre': task.nombre,
                'descripcion': task.descripcion,
                'fechaFinalizacion': task.fechaFinalizacion.toIso8601String(),
                'categoria': task.categoria,
                'status': status,
              })
              .select()
              .single();

      task.id = response['id'];
      task.completado = response['completado'];
      tasks.add(task);

      notifyListeners();
      // return task.id!;
    } catch (e) {
      debugPrint('Error add: $e');
      return null;
    }
  }

  // Metodo para actualizar status de una tarea
  Future<int?> updateCompletado(Tasks task) async {
    try {
      final nuevoCompletado = !task.completado;

      final hoy = DateTime.now();
      final fechaHoy = DateTime(hoy.year, hoy.month, hoy.day);

      final fechaTask = DateTime(
        task.fechaFinalizacion.year,
        task.fechaFinalizacion.month,
        task.fechaFinalizacion.day,
      );

      String nuevoStatus = '';
      if (nuevoCompletado) {
        nuevoStatus = 'completado';
      } else if (fechaTask.isBefore(fechaHoy)) {
        nuevoStatus = 'atrasado';
      } else {
        nuevoStatus = 'pendiente';
      }

      await _supabase
          .from("TAREAS")
          .update({'completado': nuevoCompletado, 'status': nuevoStatus})
          .eq('id', task.id!);

      task.completado = nuevoCompletado;
      task.status = nuevoStatus;

      final index = tasks.indexWhere((e) => e.id == task.id);
      tasks[index] = task;

      notifyListeners();

      // return task.id!;
    } catch (e) {
      debugPrint('Error actualizar status: $e');
      return null;
    }
  }

  // Metodo para eliminar tareas
  Future deleteTask(Tasks task) async {
    try {
      await _supabase.from("TAREAS").delete().eq("id", task.id!);

      tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error delete: $e');
    }
  }
}
