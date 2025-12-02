import 'package:flutter/material.dart';
import 'package:fynix/models/task_model.dart';
// import 'package:fynix/services/database/tasks_service.dart';
import 'package:fynix/services/offline/offline_tasks_service.dart';
import 'package:fynix/widgets/tasks/task_modal.dart';
import 'package:provider/provider.dart';

Color _getStatusColor(Tasks task) {
  switch (task.status) {
    case "completado":
      return Colors.greenAccent.shade100;
    case "atrasado":
      return Colors.redAccent.shade100;
    case "deleted":
      return Colors.purple.shade100;
    default:
      return Colors.yellowAccent.shade100;
  }
}

class TaskCard extends StatelessWidget {
  final List<Tasks> tasks;
  final String title;
  final String emptyMessage;
  const TaskCard({
    super.key,
    required this.tasks,
    required this.title,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    // final tasksService = Provider.of<TasksService>(context);
    final offlineTasksService = Provider.of<OfflineTasksService>(context);

    Future<void> showTaskModal(BuildContext context) {
      return showDialog(context: context, builder: (_) => const TaskModal());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            // La columna más externa de TaskSectionBase (dentro del Card)
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              tasks.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                      child: Text(emptyMessage),
                    ),
                  )
                  // Usamos Column y ListView.builder para la lista de tareas
                  : Column(
                    mainAxisSize:
                        MainAxisSize
                            .min, // Ajuste para evitar el error RenderFlex
                    children: [
                      ListView.builder(
                        // CRUCIAL: Resuelve el error de layout
                        shrinkWrap: true,
                        // Evita que la lista intente hacer scroll dentro de un CustomScrollView
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            color: _getStatusColor(task),
                            child: ListTile(
                              leading: Checkbox(
                                shape: const CircleBorder(),
                                value: task.completado,
                                onChanged: (value) {
                                  offlineTasksService.updateCompletado(task);
                                },
                              ),
                              title: Text(task.nombre),
                              subtitle: Column(
                                children: [
                                  Text("Descripcion: ${task.descripcion}"),
                                  SizedBox(height: 5),
                                  Text(
                                    "Fecha: ${task.fechaFinalizacion.day}/${task.fechaFinalizacion.month}/${task.fechaFinalizacion.year} - ${task.categoria} - ${task.status}",
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (task.status == 'completado') ...[
                                    const Text("Completada", style: TextStyle(color: Colors.black))
                                  ]
                                  else if (task.status == 'deleted') ...[
                                    const Text("Eliminada", style: TextStyle(color: Colors.black)),
                                  ]
                                  else ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        offlineTasksService.taskSeleccionado =
                                            task;
                                        showTaskModal(context);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => {offlineTasksService.deleteTaskOffline(task)},
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
