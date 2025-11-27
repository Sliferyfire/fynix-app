import 'package:flutter/material.dart';
import 'package:fynix/models/task_model.dart';

class TasksFormProvider with ChangeNotifier {
  GlobalKey<FormState> tasksFormKey = GlobalKey<FormState>();

  Tasks task;

  TasksFormProvider(this.task);

  bool isValidForm() {
    return tasksFormKey.currentState?.validate() ?? false;
  }

  void updateCategoria(String value) {
    task.categoria = value;
    notifyListeners();
  }

  void updateFecha(DateTime value) {
    task.fechaFinalizacion = value;
    notifyListeners();
  }
}
