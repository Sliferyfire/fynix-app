import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar para TextInputFormatter
import 'package:fynix/services/offline/offline_tasks_service.dart';
import 'package:fynix/widgets/home/notification_icon.dart';
import 'package:fynix/widgets/modal_bienvenida_finanzas.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../widgets/custom_drawer.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  static const Color primaryColor = Color(0xFF84B9BF);
  static const Color accentColor = Color(0xFFE1EDE9);
  static const Color textColor = Color(0xFF06373E);

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  List<Map<String, dynamic>> registros = [];

  // ---- filtros
  String filtroFecha =
      "Todos"; // Opciones: Todos, Hoy, Esta semana, Este mes, Este año
  String filtroTipo = "Todos"; // Opciones: Todos, Ingresos, Gastos

  // búsqueda
  TextEditingController searchController = TextEditingController();

  // Controlador para mostrar/ocultar el modal de bienvenida
  bool _showWelcomeModal = true;

  // Modo de selección para eliminar múltiples registros
  bool _selectionMode = false;
  List<int> _selectedIndices = []; // Índices de los registros seleccionados

  @override
  void initState() {
    super.initState();
    _cargarRegistros();
    searchController.addListener(() => setState(() {}));

    // También podríamos cargar una preferencia para saber si ya se mostró antes
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenWelcome =
        prefs.getBool('hasSeenFinanzasWelcome') ?? false;

    if (hasSeenWelcome) {
      setState(() {
        _showWelcomeModal = false;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------
  // FUNCIONES PARA ELIMINACIÓN
  // ------------------------------------------------------

  // Activar/desactivar modo de selección
  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedIndices.clear();
      }
    });
  }

  // Seleccionar/deseleccionar un registro
  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }

      // Si no hay elementos seleccionados, salir del modo selección
      if (_selectedIndices.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  // Eliminar los registros seleccionados
  Future<void> _deleteSelected() async {
    if (_selectedIndices.isEmpty) return;

    // Mostrar diálogo de confirmación
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Confirmar eliminación"),
                content: Text(
                  "¿Estás seguro de eliminar ${_selectedIndices.length} registro${_selectedIndices.length > 1 ? 's' : ''}?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Eliminar"),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      // Ordenar índices de mayor a menor para eliminar correctamente
      _selectedIndices.sort((a, b) => b.compareTo(a));

      setState(() {
        for (int index in _selectedIndices) {
          if (index < registros.length) {
            registros.removeAt(index);
          }
        }
        _selectedIndices.clear();
        _selectionMode = false;
      });

      await _guardarRegistros();

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${_selectedIndices.length} registro${_selectedIndices.length > 1 ? 's' : ''} eliminado${_selectedIndices.length > 1 ? 's' : ''}",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // ------------------------------------------------------
  // GUARDAR LOCALMENTE (incluye preferencia del banner)
  // ------------------------------------------------------
  Future<void> _guardarRegistros() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> convertidos =
        registros.map((e) {
          return "${e['tipo']}|${e['nombre']}|${e['cantidad']}|${(e['fecha'] as DateTime).toIso8601String()}";
        }).toList();

    await prefs.setStringList('registros_finanzas', convertidos);
  }

  // ------------------------------------------------------
  // CARGAR LOCALMENTE
  // ------------------------------------------------------
  Future<void> _cargarRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? data = prefs.getStringList('registros_finanzas');

    if (data == null) return;

    List<Map<String, dynamic>> temp =
        data.map((e) {
          final partes = e.split("|");
          return {
            "tipo": partes[0],
            "nombre": partes[1],
            "cantidad": double.parse(partes[2]),
            "fecha": DateTime.parse(partes[3]),
          };
        }).toList();

    setState(() => registros = temp);
  }

  // ------------------------------------------------------
  // MODAL PARA AGREGAR INGRESO/GASTO (CON VALIDACIÓN)
  // ------------------------------------------------------
  void _abrirModal(bool esIngreso) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nombreCtrl = TextEditingController();
    final TextEditingController cantidadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(esIngreso ? "Nuevo Ingreso" : "Nuevo Gasto"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText:
                        esIngreso ? "Nombre del ingreso" : "Nombre del gasto",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo no puede estar vacío';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: cantidadCtrl,
                  decoration: const InputDecoration(
                    labelText: "Cantidad (MXN)",
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // Permite ingresar solo números y un punto decimal
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese una cantidad';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Cantidad inválida (solo números)';
                    }
                    if (amount <= 0) {
                      return 'La cantidad debe ser mayor que cero';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validación del formulario
                if (_formKey.currentState!.validate()) {
                  String nombre = nombreCtrl.text.trim();
                  double cantidad = double.parse(cantidadCtrl.text);

                  setState(() {
                    registros.add({
                      "tipo": esIngreso ? "ingreso" : "gasto",
                      "nombre": nombre,
                      "cantidad": cantidad,
                      "fecha": DateTime.now(),
                    });
                    registros.sort((a, b) => b["fecha"].compareTo(a["fecha"]));
                  });

                  await _guardarRegistros();

                  Navigator.pop(context);
                  // Opcional: Mostrar SnackBar de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        esIngreso ? 'Ingreso guardado' : 'Gasto guardado',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FinanzasScreen.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------
  // FILTRADO: getter que devuelve registros sin modificar la lista original
  // (considera filtros de tipo, fecha y búsqueda por nombre)
  // ------------------------------------------------------
  List<Map<String, dynamic>> get registrosFiltrados {
    DateTime ahora = DateTime.now();
    final query = searchController.text.trim().toLowerCase();

    return registros.where((e) {
      // FILTRO TIPO
      bool pasaTipo = true;
      if (filtroTipo == "Ingresos") pasaTipo = e['tipo'] == 'ingreso';
      if (filtroTipo == "Gastos") pasaTipo = e['tipo'] == 'gasto';

      // FILTRO FECHA
      bool pasaFecha = true;
      final DateTime fecha = e['fecha'] as DateTime;

      switch (filtroFecha) {
        case "Hoy":
          pasaFecha =
              fecha.year == ahora.year &&
              fecha.month == ahora.month &&
              fecha.day == ahora.day;
          break;

        case "Esta semana":
          DateTime inicioSemana = ahora.subtract(
            Duration(days: ahora.weekday - 1),
          );
          DateTime finSemana = inicioSemana.add(Duration(days: 6));
          pasaFecha =
              fecha.isAfter(inicioSemana.subtract(const Duration(days: 1))) &&
              fecha.isBefore(finSemana.add(const Duration(days: 1)));
          break;

        case "Este mes":
          pasaFecha = fecha.year == ahora.year && fecha.month == ahora.month;
          break;

        case "Este año":
          pasaFecha = fecha.year == ahora.year;
          break;

        default:
          pasaFecha = true;
      }

      // FILTRO BÚSQUEDA (por nombre)
      bool pasaBusqueda = true;
      if (query.isNotEmpty) {
        pasaBusqueda = (e['nombre'] as String).toLowerCase().contains(query);
      }

      return pasaTipo && pasaFecha && pasaBusqueda;
    }).toList();
  }

  // ------------------------------------------------------
  // GENERAR SPOTS PARA LA GRÁFICA (AHORA USA registrosFiltrados)
  // ------------------------------------------------------
  List<FlSpot> _generarSpots() {
    final lista = registrosFiltrados;
    if (lista.isEmpty) return const [FlSpot(0, 0)];

    final sorted = List<Map<String, dynamic>>.from(lista)..sort(
      (a, b) => (a["fecha"] as DateTime).compareTo(b["fecha"] as DateTime),
    );

    double balance = 0;
    List<FlSpot> spots = [];

    spots.add(const FlSpot(0, 0));

    for (int i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      double valor = e["cantidad"] * (e["tipo"] == "ingreso" ? 1 : -1);
      balance += valor;
      spots.add(FlSpot(i.toDouble() + 1, balance));
    }

    return spots;
  }

  // ------------------------------------------------------
  // TOTALES (AHORA SOBRE registrosFiltrados)
  // ------------------------------------------------------
  double get totalIngresos => registrosFiltrados
      .where((e) => e["tipo"] == "ingreso")
      .fold(0.0, (s, e) => s + e["cantidad"]);

  double get totalGastos => registrosFiltrados
      .where((e) => e["tipo"] == "gasto")
      .fold(0.0, (s, e) => s + e["cantidad"]);

  double get totalRestante => totalIngresos - totalGastos;

  // ------------------------------------------------------
  // GENERAR Y DESCARGAR PDF (AHORA CON REGISTROS FILTRADOS)
  // ------------------------------------------------------
  Future<void> generarPDF() async {
    final pdf = pw.Document();
    final lista =
        registrosFiltrados..sort(
          (a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime),
        );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              pw.Center(
                child: pw.Text(
                  "Reporte de Finanzas",
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#06373E'),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Resumen General",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(thickness: 1, color: PdfColor.fromHex('#84B9BF')),
              _buildPdfRow("Ingresos Totales:", totalIngresos, PdfColors.green),
              _buildPdfRow("Gastos Totales:", totalGastos, PdfColors.red),
              _buildPdfRow("Balance Final:", totalRestante, PdfColors.blue),
              pw.SizedBox(height: 20),
              pw.Text(
                "Detalle de Movimientos",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(thickness: 1, color: PdfColor.fromHex('#84B9BF')),
              pw.SizedBox(height: 10),
              // Tabla con registros filtrados
              pw.Table.fromTextArray(
                headers: ['Tipo', 'Descripción', 'Cantidad (MXN)', 'Fecha'],
                data:
                    lista.map((e) {
                      final isIngreso = e['tipo'] == 'ingreso';
                      return [
                        isIngreso ? 'INGRESO' : 'GASTO',
                        e['nombre'].toString(),
                        '${isIngreso ? '+' : '-'} \$${e['cantidad'].toStringAsFixed(2)}',
                        DateFormat('dd/MM/yyyy HH:mm').format(e['fecha']),
                      ];
                    }).toList(),
                border: pw.TableBorder.all(color: PdfColor.fromHex('#84B9BF')),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF84B9BF),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(6),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF0F4F3),
                ),
              ),
            ],
      ),
    );

    final bytes = await pdf.save();

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Reporte_Finanzas_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generado y listo para compartir')),
      );
    }
  }

  pw.Widget _buildPdfRow(String label, double amount, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            '\$${amount.toStringAsFixed(2)} MXN',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------
  // UI
  // ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          // Contenido principal de la pantalla
          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Container(
                  color: FinanzasScreen.accentColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SEARCH BAR + FILTER ICON (como la imagen)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: _buildSearchAndFilterBar(),
                      ),

                      const SizedBox(height: 10),

                      _buildResumen(),
                      const SizedBox(height: 10),

                      // -------------------------------
                      // BOTÓN DE EXPORTAR PDF (OPCIÓN B)
                      // -------------------------------
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: generarPDF,
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Exportar resultados a PDF",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FinanzasScreen.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildListaRegistros(),
                      const SizedBox(height: 20),
                      _buildGrafica(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Modal de bienvenida (si está activo)
          if (_showWelcomeModal || registros.isEmpty) ModalBienvenidaFinanzas(),

          // Botón flotante para eliminar seleccionados (cuando hay selección)
          if (_selectedIndices.isNotEmpty)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _deleteSelected,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                child: const Icon(Icons.delete),
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // COMPONENTES DE UI
  // ----------------------------------------------------------------

  Widget _buildSliverAppBar(BuildContext context) {
    final offlineTasksService = Provider.of<OfflineTasksService>(context);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 220.0,
      backgroundColor: FinanzasScreen.primaryColor,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 30),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      ),
      actions: [
        // SOLO LA CAMPANITA - ELIMINAMOS EL BOTE DE BASURA
        NotificationIcon(allTasks: offlineTasksService.tasks),

        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Container(),
        background: Container(
          color: FinanzasScreen.primaryColor,
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Finanzas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Registro y gestión',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton('Nuevo Ingreso', true, Colors.green),
                  const SizedBox(width: 15),
                  _buildActionButton('Nuevo Gasto', false, Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, bool isIncome, Color color) {
    return ElevatedButton.icon(
      onPressed: () => _abrirModal(isIncome),
      icon: Icon(isIncome ? Icons.add : Icons.remove, color: color),
      label: Text(
        text,
        style: TextStyle(
          color: FinanzasScreen.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
      ),
    );
  }

  // ------------------------------------------------------
  // _buildResumen: muestra solo los totales (sin dropdowns)
  // ------------------------------------------------------
  Widget _buildResumen() {
    return Container(
      // AJUSTE DE POSICIÓN: Valor reducido de -28.0 a -16.0
      transform: Matrix4.translationValues(0.0, 10.0, 0.0),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FinanzasScreen.primaryColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ingresos Totales',
                style: TextStyle(color: FinanzasScreen.textColor, fontSize: 16),
              ),
              const Text(
                'Total Restante',
                style: TextStyle(color: FinanzasScreen.textColor, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${totalIngresos.toStringAsFixed(2)} MXN',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${totalRestante.toStringAsFixed(2)} MXN',
                style: TextStyle(
                  color: totalRestante >= 0 ? Colors.blue : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Gastos Totales',
            style: TextStyle(color: FinanzasScreen.textColor, fontSize: 16),
          ),
          Text(
            '\$${totalGastos.toStringAsFixed(2)} MXN',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------
  // BARRA DE BÚSQUEDA + ICONO DE FILTROS (estilo imagen)
  // ------------------------------------------------------
  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF84B9BF)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar . . .',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Contador de seleccionados en modo selección
                if (_selectionMode && _selectedIndices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedIndices.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color:
                (filtroTipo != "Todos" || filtroFecha != "Todos")
                    ? FinanzasScreen.primaryColor
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.filter_list,
              color:
                  (filtroTipo != "Todos" || filtroFecha != "Todos")
                      ? Colors.white
                      : FinanzasScreen.primaryColor,
            ),
            onPressed: () => _mostrarFiltros(),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------
  // MOSTRAR MODAL DE FILTROS (estilo imagen)
  // ------------------------------------------------------
  void _mostrarFiltros() {
    // valores temporales
    String tempTipo = filtroTipo;
    String tempFecha = filtroFecha;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F7FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: titulo + limpiar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF06373E),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempTipo = "Todos";
                            tempFecha = "Todos";
                          });
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Filtrar por Tipo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: tempTipo == "Todos",
                        onSelected: (_) {
                          setModalState(() => tempTipo = "Todos");
                        },
                        selectedColor: FinanzasScreen.primaryColor.withOpacity(
                          0.3,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Ingresos'),
                        selected: tempTipo == "Ingresos",
                        onSelected: (_) {
                          setModalState(() => tempTipo = "Ingresos");
                        },
                        selectedColor: FinanzasScreen.primaryColor.withOpacity(
                          0.3,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Gastos'),
                        selected: tempTipo == "Gastos",
                        onSelected: (_) {
                          setModalState(() => tempTipo = "Gastos");
                        },
                        selectedColor: FinanzasScreen.primaryColor.withOpacity(
                          0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Filtrar por Fecha',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _dateChip(
                        'Hoy',
                        tempFecha,
                        (v) => setModalState(() => tempFecha = v),
                      ),
                      _dateChip(
                        'Esta semana',
                        tempFecha,
                        (v) => setModalState(() => tempFecha = v),
                      ),
                      _dateChip(
                        'Este mes',
                        tempFecha,
                        (v) => setModalState(() => tempFecha = v),
                      ),
                      _dateChip(
                        'Este año',
                        tempFecha,
                        (v) => setModalState(() => tempFecha = v),
                      ),
                      _dateChip(
                        'Todos',
                        tempFecha,
                        (v) => setModalState(() => tempFecha = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filtroTipo = tempTipo;
                          filtroFecha = tempFecha;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FinanzasScreen.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aplicar filtros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _dateChip(String label, String selected, Function(String) onSelected) {
    final bool active = selected == label;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: active,
      onSelected: (_) => onSelected(label),
      selectedColor: FinanzasScreen.primaryColor.withOpacity(0.25),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildListaRegistros() {
    final lista = registrosFiltrados;

    if (lista.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          // AJUSTE DE POSICIÓN: Valor reducido de -28.0 a -16.0
          transform: Matrix4.translationValues(0.0, -16.0, 0.0),
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay registros financieros.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> gruposFecha = {};
    for (var e in lista) {
      String key = DateFormat('dd MMM yyyy', 'es').format(e['fecha']);
      if (!gruposFecha.containsKey(key)) {
        gruposFecha[key] = [];
      }
      gruposFecha[key]!.add(e);
    }

    return Container(
      // AJUSTE DE POSICIÓN: Valor reducido de -28.0 a -16.0
      transform: Matrix4.translationValues(0.0, 6.0, 0.0),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            gruposFecha.entries.map((grupo) {
              grupo.value.sort((a, b) => b["fecha"].compareTo(a["fecha"]));

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grupo.key,
                      style: const TextStyle(
                        color: FinanzasScreen.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: FinanzasScreen.primaryColor.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children:
                            grupo.value.asMap().entries.map((entry) {
                              int index = entry.key;
                              final e = entry.value;
                              final isIngreso = e["tipo"] == "ingreso";
                              final originalIndex = registros.indexWhere(
                                (element) =>
                                    element['nombre'] == e['nombre'] &&
                                    element['cantidad'] == e['cantidad'] &&
                                    element['fecha'] == e['fecha'],
                              );

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: _buildItem(
                                  e["nombre"],
                                  (isIngreso ? "+ " : "- ") +
                                      "\$${e["cantidad"].toStringAsFixed(2)}",
                                  isIngreso
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  isIngreso
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  index: originalIndex,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildItem(
    String nombre,
    String monto,
    Color color,
    Color textColor, {
    int? index,
  }) {
    bool isSelected = index != null && _selectedIndices.contains(index);

    return GestureDetector(
      onLongPress: () {
        if (index != null && !_selectionMode) {
          _toggleSelectionMode();
          _toggleSelection(index);
        }
      },
      onTap: () {
        if (_selectionMode && index != null) {
          _toggleSelection(index);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? FinanzasScreen.primaryColor.withOpacity(0.2) : color,
          borderRadius: BorderRadius.circular(10),
          border:
              isSelected
                  ? Border.all(color: FinanzasScreen.primaryColor, width: 2)
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Checkbox en modo selección
                if (_selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged:
                          index != null
                              ? (value) => _toggleSelection(index)
                              : null,
                      activeColor: FinanzasScreen.primaryColor,
                    ),
                  ),
                Icon(
                  Icons.monetization_on,
                  size: 20,
                  color:
                      isSelected
                          ? FinanzasScreen.textColor
                          : textColor.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  nombre,
                  style: TextStyle(
                    color: isSelected ? FinanzasScreen.textColor : textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  monto,
                  style: TextStyle(
                    color: isSelected ? FinanzasScreen.textColor : textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Botón de eliminar individual (solo en modo normal)
                if (!_selectionMode && index != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () => _showDeleteDialog(index),
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para eliminar un solo registro
  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Eliminar registro"),
            content: const Text("¿Estás seguro de eliminar este registro?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() {
                    registros.removeAt(index);
                  });
                  await _guardarRegistros();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Registro eliminado"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Eliminar"),
              ),
            ],
          ),
    );
  }

  Widget _buildGrafica() {
    return Container(
      // AJUSTE DE POSICIÓN: Valor reducido de -28.0 a -16.0
      transform: Matrix4.translationValues(0.0, -16.0, 0.0),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FinanzasScreen.primaryColor.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      height: 220,
      child: LineChart(
        LineChartData(
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _generarSpots(),
              isCurved: true,
              color: FinanzasScreen.primaryColor,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: FinanzasScreen.primaryColor.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase Empleado (sin cambios)
class Empleado {
  final String id;
  final String nombre;
  final String puesto;
  final double sueldo;
  final int vacacionesPendientes;
  final bool activo;

  Empleado({
    required this.id,
    required this.nombre,
    required this.puesto,
    required this.sueldo,
    required this.vacacionesPendientes,
    required this.activo,
  });
}
