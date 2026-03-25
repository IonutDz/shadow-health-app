import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'body_provider.dart';

class BodyPage extends ConsumerStatefulWidget {
  const BodyPage({super.key});

  @override
  ConsumerState<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends ConsumerState<BodyPage> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final body = ref.watch(bodyProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppTheme.blue400.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.accessibility_new_outlined, color: AppTheme.blue400, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cuerpo', style: TextStyle(color: AppTheme.foreground, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Revisión física mensual', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                    ],
                  )),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCheckSheet(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nueva', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue400.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == i ? AppTheme.blue400 : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _activeTab == i ? AppTheme.blue400 : AppTheme.border),
                          ),
                          child: Text(
                            ['Resumen', 'Medidas', 'Historial'][i],
                            style: TextStyle(color: _activeTab == i ? Colors.white : AppTheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Expanded(
              child: _activeTab == 0
                  ? _OverviewTab(body: body)
                  : _activeTab == 1
                      ? _MeasuresTab(body: body)
                      : _HistoryTab(body: body, onDelete: (id) => ref.read(bodyProvider.notifier).deleteBodyCheck(id)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCheckSheet(BuildContext context, WidgetRef ref) {
    final weightCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final measureCtrls = <String, TextEditingController>{
      for (final r in measurementRegions) r['region']!: TextEditingController(),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nueva Revisión Física', style: TextStyle(color: AppTheme.foreground, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _BodyFormField(ctrl: weightCtrl, label: 'Peso (kg)', hint: '70.0')),
                const SizedBox(width: 12),
                Expanded(child: _BodyFormField(ctrl: fatCtrl, label: 'Grasa corporal (%)', hint: '15.0')),
              ]),
              const SizedBox(height: 12),
              const Text('Medidas (cm)', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.5,
                children: measurementRegions.map((r) => _BodyFormField(
                  ctrl: measureCtrls[r['region']!]!,
                  label: r['label']!,
                  hint: '0',
                )).toList(),
              ),
              const SizedBox(height: 12),
              _BodyFormField(ctrl: notesCtrl, label: 'Notas', hint: 'Opcional...'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final measurements = measurementRegions
                        .where((r) => measureCtrls[r['region']!]!.text.isNotEmpty)
                        .map((r) => {
                              'region': r['region']!,
                              'value': double.tryParse(measureCtrls[r['region']!]!.text) ?? 0.0,
                              'label': r['label']!,
                            })
                        .toList();
                    await ref.read(bodyProvider.notifier).addBodyCheck(
                          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          weight: double.tryParse(weightCtrl.text),
                          bodyFat: double.tryParse(fatCtrl.text),
                          measurements: measurements,
                          notes: notesCtrl.text.trim(),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blue400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Guardar Revisión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final BodyState body;
  const _OverviewTab({required this.body});

  @override
  Widget build(BuildContext context) {
    final latest = body.latestCheck;

    if (latest == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.accessibility_new_outlined, color: AppTheme.mutedForeground, size: 48),
            SizedBox(height: 16),
            Text('No hay revisiones todavía', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
            SizedBox(height: 4),
            Text('Registra tu primera revisión física', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Latest check summary
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.blue400.withOpacity(0.1), AppTheme.blue400.withOpacity(0.03)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.blue400.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.straighten_outlined, color: AppTheme.blue400, size: 18),
                    const SizedBox(width: 8),
                    const Text('Última Revisión', style: TextStyle(color: AppTheme.foreground, fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(latest.date, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _BigStat(
                      label: 'Peso',
                      value: latest.weight != null ? '${latest.weight}' : '--',
                      unit: 'kg',
                      diff: body.weightDiff,
                      color: AppTheme.blue400,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _BigStat(
                      label: 'Grasa corporal',
                      value: latest.bodyFat != null ? '${latest.bodyFat}' : '--',
                      unit: '%',
                      diff: body.bodyFatDiff,
                      color: AppTheme.amber400,
                    )),
                  ],
                ),
              ],
            ),
          ),

          // Measurements
          if (latest.measurements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Medidas', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: latest.measurements.map((m) => Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${m.value}', style: const TextStyle(color: AppTheme.foreground, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('cm', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 9)),
                    Text(m.label, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 10), textAlign: TextAlign.center),
                  ],
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double? diff;
  final Color color;

  const _BigStat({required this.label, required this.value, required this.unit, required this.diff, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 3),
              Text(unit, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
            ],
          ),
          if (diff != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  diff! < 0 ? Icons.trending_down : diff! > 0 ? Icons.trending_up : Icons.trending_flat,
                  color: diff! < 0 ? AppTheme.primary : diff! > 0 ? AppTheme.destructive : AppTheme.mutedForeground,
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  '${diff! > 0 ? '+' : ''}$diff $unit',
                  style: TextStyle(
                    color: diff! < 0 ? AppTheme.primary : diff! > 0 ? AppTheme.destructive : AppTheme.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Measures Tab ──────────────────────────────────────────────────────────────
class _MeasuresTab extends StatelessWidget {
  final BodyState body;
  const _MeasuresTab({required this.body});

  @override
  Widget build(BuildContext context) {
    final latest = body.latestCheck;
    if (latest == null || latest.measurements.isEmpty) {
      return const Center(child: Text('No hay medidas registradas todavía', style: TextStyle(color: AppTheme.mutedForeground)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final region in measurementRegions) ...[
          _MeasureRow(
            label: region['label']!,
            latest: latest.measurements.where((m) => m.region == region['region']).firstOrNull?.value,
            previous: body.previousCheck?.measurements.where((m) => m.region == region['region']).firstOrNull?.value,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _MeasureRow extends StatelessWidget {
  final String label;
  final double? latest;
  final double? previous;

  const _MeasureRow({required this.label, required this.latest, required this.previous});

  @override
  Widget build(BuildContext context) {
    final diff = (latest != null && previous != null) ? (latest! - previous!) : null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w500))),
          if (latest != null)
            Text('$latest cm', style: const TextStyle(color: AppTheme.blue400, fontSize: 14, fontWeight: FontWeight.w600))
          else
            const Text('--', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
          if (diff != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: diff > 0 ? AppTheme.primary.withOpacity(0.1) : AppTheme.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
                style: TextStyle(
                  color: diff > 0 ? AppTheme.primary : AppTheme.destructive,
                  fontSize: 10, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final BodyState body;
  final void Function(String) onDelete;

  const _HistoryTab({required this.body, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (body.bodyChecks.isEmpty) {
      return const Center(child: Text('No hay historial todavía', style: TextStyle(color: AppTheme.mutedForeground)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: body.bodyChecks.length,
      itemBuilder: (ctx, i) {
        final check = body.bodyChecks[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: i == 0 ? AppTheme.blue400.withOpacity(0.3) : AppTheme.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (i == 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.blue400.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('ÚLTIMA', style: TextStyle(color: AppTheme.blue400, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(check.date, style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (check.weight != null)
                          Text('${check.weight} kg', style: const TextStyle(color: AppTheme.blue400, fontSize: 12, fontWeight: FontWeight.w600)),
                        if (check.weight != null && check.bodyFat != null)
                          const Text(' · ', style: TextStyle(color: AppTheme.mutedForeground)),
                        if (check.bodyFat != null)
                          Text('${check.bodyFat}% grasa', style: const TextStyle(color: AppTheme.amber400, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (check.measurements.isNotEmpty)
                      Text('${check.measurements.length} medidas registradas', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onDelete(check.id),
                icon: const Icon(Icons.delete_outline, color: AppTheme.destructive, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BodyFormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;

  const _BodyFormField({required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.foreground, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.blue400)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }
}
