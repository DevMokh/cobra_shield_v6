import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/strings.dart';
import '../widgets/intel_settings.dart';
import '../widgets/scale_header.dart';
import '../widgets/tools.dart';
import '../widgets/tools_extra.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  int _tab = 0;

  static const List<String> _names = <String>[
    'القوة',
    'مولّد',
    'منظّف',
    'هاش',
    'المرسل',
    'مجمّع',
  ];

  Widget _tool() {
    switch (_tab) {
      case 0:
        return const StrengthTool();
      case 1:
        return const GeneratorTool();
      case 2:
        return const CleanerTool();
      case 3:
        return const HashTool();
      case 4:
        return const SenderTool();
      default:
        return const BatchTool();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ScaleHeader(
          title: tr(S.toolsTitle),
          subtitle: tr(S.toolsSubtitle),
          icon: Icons.build_circle_rounded,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _names.length; i++)
                    ChoiceChip(
                      label: Text(_names[i]),
                      selected: _tab == i,
                      onSelected: (_) => setState(() => _tab = i),
                      showCheckmark: false,
                      selectedColor: alpha(C.emerald, 0.22),
                      backgroundColor: C.surface,
                      side: const BorderSide(color: C.line),
                      labelStyle: TextStyle(
                        color: _tab == i ? C.emerald : C.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _tool(),
              const SizedBox(height: 18),
              const IntelSettingsPanel(),
              const SizedBox(height: 14),
              const SettingsPanel(),
            ],
          ),
        ),
      ],
    );
  }
}
