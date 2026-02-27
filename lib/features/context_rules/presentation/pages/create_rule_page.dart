import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';

//
// Page
//

class CreateRulePage extends StatefulWidget {
  const CreateRulePage({super.key});

  @override
  State<CreateRulePage> createState() => _CreateRulePageState();
}

class _CreateRulePageState extends State<CreateRulePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Condition state
  String? _selectedSensorType; // 'Nhiệt độ' | 'Độ ẩm' | 'Lượng khách'
  double _sliderValue = 25;
  int _crowdLevelIndex = 1; // 0=Vắng, 1=Bình thường, 2=Đông

  // Action state
  String _selectedPlaylist = 'Chưa chọn';

  static const _crowdLabels = ['Vắng', 'Bình thường', 'Đông'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Computed helpers

  double get _sliderMin => 0;
  double get _sliderMax => _selectedSensorType == 'Độ ẩm' ? 100 : 50;
  int get _sliderDivisions => _selectedSensorType == 'Độ ẩm' ? 20 : 25;
  String get _sliderUnit => _selectedSensorType == 'Độ ẩm' ? '%' : '°C';

  bool get _isCrowd => _selectedSensorType == 'Lượng khách';
  bool get _isSlider =>
      _selectedSensorType == 'Nhiệt độ' || _selectedSensorType == 'Độ ẩm';

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: _buildAppBar(palette),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BlockCard(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BlockTitle(
                      icon: LucideIcons.tag,
                      label: 'TÊN QUY TẮC',
                      palette: palette,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(
                          color: palette.textPrimary, fontSize: 14),
                      cursorColor: palette.accent,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng đặt tên quy tắc'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'VD: Nhạc buổi trưa đông khách',
                        hintStyle: GoogleFonts.inter(
                          color: palette.textMuted.withOpacity(0.55),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: palette.overlay,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: palette.accent, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _BlockCard(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BlockTitle(
                      icon: LucideIcons.thermometer,
                      label: 'NẾU  (Điều kiện môi trường)',
                      palette: palette,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Loại cảm biến',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedSensorType,
                      hint: Text(
                        'Chọn loại cảm biến…',
                        style: GoogleFonts.inter(
                          color: palette.textMuted.withOpacity(0.55),
                          fontSize: 14,
                        ),
                      ),
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn loại cảm biến' : null,
                      dropdownColor: palette.card,
                      iconEnabledColor: palette.accent,
                      borderRadius: BorderRadius.circular(12),
                      style: GoogleFonts.inter(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: palette.overlay,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: palette.accent, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Nhiệt độ', child: Text('Nhiệt độ')),
                        DropdownMenuItem(value: 'Độ ẩm', child: Text('Độ ẩm')),
                        DropdownMenuItem(
                            value: 'Lượng khách', child: Text('Lượng khách')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedSensorType = v;
                          _sliderValue = v == 'Độ ẩm' ? 50 : 25;
                          _crowdLevelIndex = 1;
                        });
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: _selectedSensorType == null
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  'Ngưỡng giá trị',
                                  style: GoogleFonts.inter(
                                    color: palette.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_isSlider) ...[
                                  _SliderInput(
                                    value: _sliderValue,
                                    min: _sliderMin,
                                    max: _sliderMax,
                                    divisions: _sliderDivisions,
                                    unit: _sliderUnit,
                                    palette: palette,
                                    onChanged: (v) =>
                                        setState(() => _sliderValue = v),
                                  ),
                                ] else if (_isCrowd) ...[
                                  _CrowdToggle(
                                    labels: _crowdLabels,
                                    selectedIndex: _crowdLevelIndex,
                                    palette: palette,
                                    onChanged: (i) =>
                                        setState(() => _crowdLevelIndex = i),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _BlockCard(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BlockTitle(
                      icon: LucideIcons.music2,
                      label: 'THÌ  (Phát nhạc)',
                      palette: palette,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Playlist hoặc chủ đề sẽ được phát khi điều kiện đúng',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: palette.overlay,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.border),
                      ),
                      child: ListTile(
                        onTap: () {
                          debugPrint('Mở BottomSheet chọn nhạc');
                        },
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        title: Text(
                          'Chọn Playlist / Chủ đề',
                          style: GoogleFonts.inter(
                            color: palette.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _selectedPlaylist,
                          style: GoogleFonts.inter(
                            color: _selectedPlaylist == 'Chưa chọn'
                                ? palette.textMuted.withOpacity(0.55)
                                : palette.accent,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: palette.textMuted,
                          size: 22,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.textOnAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lưu quy tắc',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

  AppBar _buildAppBar(_Palette palette) {
    return AppBar(
      backgroundColor: palette.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: palette.overlay,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Icon(LucideIcons.chevronLeft,
              color: palette.textPrimary, size: 20),
        ),
      ),
      title: Text(
        'Tạo luật tự động mới',
        style: GoogleFonts.poppins(
          color: palette.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    context.pop();
  }
}

class _SliderInput extends StatelessWidget {
  const _SliderInput({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.palette,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final _Palette palette;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lớn hơn',
              style: GoogleFonts.inter(color: palette.textMuted, fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: palette.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.accent.withOpacity(0.3)),
              ),
              child: Text(
                '${value.round()}$unit',
                style: GoogleFonts.poppins(
                  color: palette.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: palette.accent,
            inactiveTrackColor: palette.textMuted.withOpacity(0.2),
            thumbColor: palette.accent,
            overlayColor: palette.accent.withOpacity(0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.round()}$unit',
                style:
                    GoogleFonts.inter(color: palette.textMuted, fontSize: 11)),
            Text('${max.round()}$unit',
                style:
                    GoogleFonts.inter(color: palette.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _CrowdToggle extends StatelessWidget {
  const _CrowdToggle({
    required this.labels,
    required this.selectedIndex,
    required this.palette,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final _Palette palette;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / labels.length;
        return Container(
          decoration: BoxDecoration(
            color: palette.overlay,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(labels.length, (i) {
              final selected = i == selectedIndex;
              return GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: itemWidth,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? palette.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: GoogleFonts.inter(
                      color:
                          selected ? palette.textOnAccent : palette.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.palette, required this.child});
  final _Palette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: palette.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: palette.accent, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: palette.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Palette {
  const _Palette({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.overlay,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentAlt,
    required this.textOnAccent,
    required this.shadow,
  });

  factory _Palette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return _Palette(
        isDark: true,
        bg: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        overlay: Colors.white.withOpacity(0.06),
        border: AppColors.borderDarkMedium,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
        accentAlt: AppColors.secondaryLime,
        textOnAccent: AppColors.textDarkPrimary,
        shadow: AppColors.shadowDark,
      );
    }
    return _Palette(
      isDark: false,
      bg: AppColors.backgroundPrimary,
      card: AppColors.surface,
      overlay: AppColors.backgroundSecondary,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
      accentAlt: AppColors.secondaryTeal,
      textOnAccent: AppColors.textInverse,
      shadow: AppColors.shadow,
    );
  }

  final bool isDark;
  final Color bg;
  final Color card;
  final Color overlay;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color accentAlt;
  final Color textOnAccent;
  final Color shadow;
}
