import 'package:cod/simulation/round_simulation.dart';
import 'package:cod/theme/colors.dart';
import 'package:flutter/material.dart';

class RoundSimulationDebugScreen extends StatefulWidget {
  const RoundSimulationDebugScreen({super.key, required this.entries});

  final List<RoundSimulationEntry> entries;

  @override
  State<RoundSimulationDebugScreen> createState() => _RoundSimulationDebugScreenState();
}

class _RoundSimulationDebugScreenState extends State<RoundSimulationDebugScreen> {
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;

    return Scaffold(
      body: entries.isEmpty
          ? const Center(child: Text('No rounds to display.'))
          : SafeArea(
              child: SingleChildScrollView(
                controller: _verticalController,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Round Simulation',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          notificationPredicate: (notification) => notification.metrics.axis == Axis.horizontal,
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Player(s)')),
                                DataColumn(label: Text('Title')),
                                DataColumn(label: Text('Description')),
                              ],
                              rows: entries
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => DataRow(
                                      cells: [
                                        DataCell(Text('${entry.key + 1}')),
                                        DataCell(Text(entry.value.category)),
                                        DataCell(
                                          Text(
                                            entry.value.playerNames.isEmpty ? '—' : entry.value.playerNames.join(', '),
                                          ),
                                        ),
                                        DataCell(Text(entry.value.isRepeatable ? entry.value.title ?? '—' : '—')),
                                        DataCell(
                                          SizedBox(
                                            width: 320,
                                            child: Text(
                                              entry.value.isRepeatable ? (entry.value.description ?? '—') : '—',
                                              softWrap: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
