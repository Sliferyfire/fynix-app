import 'package:flutter/material.dart';
import 'package:fynix/models/task_model.dart';
import 'package:fynix/providers/user_data_provider.dart';
// import 'package:fynix/services/database/tasks_service.dart';
import 'package:fynix/services/offline/offline_tasks_service.dart';
import 'package:fynix/widgets/custom_drawer.dart';
import 'package:fynix/widgets/home/calendario_widget.dart';
import 'package:fynix/widgets/home/custom_scroll_screen.dart';
import 'package:fynix/widgets/loading_widget.dart';
import 'package:fynix/widgets/home/notification_icon.dart';
import 'package:fynix/widgets/tasks/task_card.dart';
import 'package:fynix/widgets/tasks/task_modal.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> showTaskModal(BuildContext context) {
  return showDialog(context: context, builder: (_) => const TaskModal());
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // const _HomeScreenState({super.key});

  DateTime selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserDataProvider>(context);
    // final tasksService = Provider.of<TasksService>(context);
    final offlineTasksService = Provider.of<OfflineTasksService>(context);

    const Color primaryColor = Color(0xFF84B9BF);
    const Color accentColor = Color(0xFFE1EDE9);

    void onDateSelected(DateTime day) async {
      setState(() {
        selectedDay = day;
      });
      await offlineTasksService.obtenerTasksDia(selectedDay);
    }

    final welcomeContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Hola de nuevo",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 28, color: Colors.white),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  userProvider.username ?? "",
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final screenBody = Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: CalendarWidget(
                  selectedDay: selectedDay,
                  onDateSelected: onDateSelected,
                  tasks: offlineTasksService.tasks,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Muestra la fecha de HOY
                Text(
                  DateFormat(
                    'dd \'de\' MMMM yyyy',
                    'es_ES',
                  ).format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                // Botón de Agregar Tarea (llama al diálogo)
                ElevatedButton.icon(
                  onPressed: () {
                    offlineTasksService.taskSeleccionado = Tasks(
                      nombre: "",
                      descripcion: "",
                      fechaFinalizacion: DateTime.now(),
                      categoria: "Personal",
                      status: "pendiente",
                      completado: false,
                    );
                    showTaskModal(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar tarea"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Sección de Tareas del Día Seleccionado ---
          TaskCard(
            title: 'Tareas del ${DateFormat('dd/MM').format(selectedDay)}',
            tasks: offlineTasksService.tasksDia,
            emptyMessage:
                'No hay tareas para el ${DateFormat('dd/MM').format(selectedDay)}.',
          ),

          const SizedBox(height: 20),

          // --- SECCIÓN: Listado de TODAS las Tareas ---
          TaskCard(
            title: "Todas las Tareas (${offlineTasksService.tasks.length})",
            tasks: offlineTasksService.tasks,
            emptyMessage: 'No hay ninguna tarea registrada en el sistema.',
          ),

          const SizedBox(height: 20),
        ],
      ),
    );

    // if (offlineTasksService.isLoading) {
    //   return LoadingWidget();
    // }

    return CustomScrollScreen(
      title: "Home",
      drawer: const CustomDrawer(),
      headerColor: primaryColor,
      contentBackgroundColor: accentColor,
      topContent: welcomeContent,
      actions: [
        NotificationIcon(allTasks: offlineTasksService.tasks),
        const SizedBox(width: 8),
      ],
      bodyContent: screenBody,
    );
  }
}
