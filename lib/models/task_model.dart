import 'dart:convert';

class Tasks {
  String? id;
  String nombre = '';
  String descripcion = '';
  DateTime fechaFinalizacion = DateTime.now();
  String categoria = '';
  String status = '';
  bool completado = false; 

  Tasks({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaFinalizacion,
    required this.categoria,
    required this.status,
    required this.completado,
  });

  factory Tasks.fromJson(String str) => Tasks.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Tasks.fromMap(Map<String, dynamic> json) => Tasks(
    id: json["id"],
    nombre: json["nombre"],
    descripcion: json["descripcion"],
    fechaFinalizacion: DateTime.parse(json["fechaFinalizacion"]),
    categoria: json["categoria"],
    status: json["status"],
    completado: json["completado"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "nombre": nombre,
    "descripcion": descripcion,
    "fechaFinalizacion": fechaFinalizacion,
    "categoria": categoria,
    "status": status,
    "completado": completado,
  };

  Tasks copy() => Tasks(
    id: id,
    nombre: nombre,
    descripcion: descripcion,
    fechaFinalizacion: fechaFinalizacion,
    categoria: categoria,
    status: status,
    completado: completado
  );
}
