import 'package:flutter/material.dart';
// import 'package:fynix/models/task_model.dart';
import 'package:fynix/providers/tasks_form_provider.dart';
// import 'package:fynix/services/database/tasks_service.dart';
import 'package:fynix/services/offline/offline_tasks_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TaskModal extends StatelessWidget {
  const TaskModal({super.key});

  @override
  Widget build(BuildContext context) {
    // final tasksService = Provider.of<TasksService>(context);
    final offlinetasksService = Provider.of<OfflineTasksService>(context);

    return ChangeNotifierProvider(
      create:
          (context) => TasksFormProvider(offlinetasksService.taskSeleccionado!),
      child: _TaskModalBody(offlinetasksService: offlinetasksService),
    );
  }
}

class _TaskModalBody extends StatelessWidget {
  final OfflineTasksService offlinetasksService;

  const _TaskModalBody({
    // super.key,
    required this.offlinetasksService,
  });

  @override
  Widget build(BuildContext context) {
    final taskForm = Provider.of<TasksFormProvider>(context);
    final task = taskForm.task;

    return AlertDialog(
      title: Text("Tareas"),
      content: StatefulBuilder(
        builder:
            (context, setStateDialog) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: task.nombre,
                    onChanged: (value) => task.nombre = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Nombre obligatorio";
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Nombre de la tarea",
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: task.descripcion,
                    onChanged: (value) => task.descripcion = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Descripcion obligatorio";
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Descripcion de la tarea",
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text("Fecha: "),
                      TextButton(
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: task.fechaFinalizacion,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            taskForm.updateFecha(picked);
                          }
                        },

                        child: Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(task.fechaFinalizacion),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text("Categoría: "),
                      DropdownButton<String>(
                        value: task.categoria,
                        items:
                            ['Personal', 'General', 'Otro']
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            taskForm.updateCategoria(value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () {
            offlinetasksService.addUpdateTask(task);
            Navigator.pop(context);
          },
          child: const Text("Guardar"),
        ),
      ],
    );
  }
}
