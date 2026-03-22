import 'dart:ui';
import 'package:flutter/material.dart';

/// Tipos de diálogo disponibles — cada uno tiene icono, color y gradiente propios.
enum JDDialogType { success, danger, warning, info, connect, worker }

class _JDDialogTheme {
  final List<Color> gradient;
  final IconData icon;

  const _JDDialogTheme({required this.gradient, required this.icon});
}

const _themes = {
  JDDialogType.success: _JDDialogTheme(
    gradient: [Color(0xFF2ecc71), Color(0xFF27ae60)],
    icon: Icons.check_circle_rounded,
  ),
  JDDialogType.danger: _JDDialogTheme(
    gradient: [Color(0xFFff6b6b), Color(0xFFee5a24)],
    icon: Icons.error_rounded,
  ),
  JDDialogType.warning: _JDDialogTheme(
    gradient: [Color(0xFFff9f43), Color(0xFFfeca57)],
    icon: Icons.warning_rounded,
  ),
  JDDialogType.info: _JDDialogTheme(
    gradient: [Color(0xFF54a0ff), Color(0xFF2e86de)],
    icon: Icons.info_rounded,
  ),
  JDDialogType.connect: _JDDialogTheme(
    gradient: [Color(0xFF28a745), Color(0xFF20c997)],
    icon: Icons.play_circle_rounded,
  ),
  JDDialogType.worker: _JDDialogTheme(
    gradient: [Color(0xFF28a745), Color(0xFF20c997)],
    icon: Icons.badge_outlined,
  ),
};

// ─────────────────────────────────────────────────────────────────────
// Botón de diálogo
// ─────────────────────────────────────────────────────────────────────

class JDDialogAction {
  final String label;
  final IconData? icon;
  final bool isPrimary;
  final bool isDanger;
  final VoidCallback? onPressed;

  const JDDialogAction({
    required this.label,
    this.icon,
    this.isPrimary = false,
    this.isDanger = false,
    this.onPressed,
  });
}

// ─────────────────────────────────────────────────────────────────────
// Widget de diálogo enriquecido JobDesk
// ─────────────────────────────────────────────────────────────────────

class JDDialog extends StatelessWidget {
  final JDDialogType type;
  final String title;
  final String? message;
  final Widget? body;
  final Widget? details;
  final List<JDDialogAction> actions;
  final double width;
  final IconData? customIcon;

  const JDDialog({
    Key? key,
    required this.type,
    required this.title,
    this.message,
    this.body,
    this.details,
    this.actions = const [],
    this.width = 420,
    this.customIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = _themes[type]!;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
        backgroundColor: Colors.white,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icono animado ──
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, val, child) =>
                    Transform.scale(scale: val, child: child),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: theme.gradient,
                    ),
                    shape: type == JDDialogType.worker
                        ? BoxShape.rectangle
                        : BoxShape.circle,
                    borderRadius: type == JDDialogType.worker
                        ? BorderRadius.circular(20)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: theme.gradient.first.withOpacity(0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    customIcon ?? theme.icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Título ──
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1a1a2e),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              // ── Mensaje ──
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // ── Cuerpo personalizado ──
              if (body != null) ...[
                const SizedBox(height: 20),
                body!,
              ],

              // ── Detalles ──
              if (details != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: details!,
                ),
              ],

              // ── Acciones ──
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: actions
                      .map((a) => Expanded(
                            flex: a.isPrimary ? 2 : 1,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: a.isPrimary
                                  ? _buildPrimaryButton(a, theme)
                                  : _buildSecondaryButton(a),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(JDDialogAction action, _JDDialogTheme theme) {
    final colors = action.isDanger
        ? [const Color(0xFFff6b6b), const Color(0xFFee5a24)]
        : theme.gradient;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: action.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: action.isDanger
              ? Colors.white
              : (type == JDDialogType.warning ? const Color(0xFF2d3436) : Colors.white),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (action.icon != null) ...[
              Icon(action.icon, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                action.label,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(JDDialogAction action) {
    if (action.isDanger) {
      return ElevatedButton(
        onPressed: action.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFee5a24),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (action.icon != null) ...[
              Icon(action.icon, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                action.label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return OutlinedButton(
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[600],
        side: BorderSide(color: Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        action.label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Función de conveniencia para mostrar un JDDialog
// ─────────────────────────────────────────────────────────────────────

Future<T?> showJDDialog<T>({
  required BuildContext context,
  required JDDialogType type,
  required String title,
  String? message,
  Widget? body,
  Widget? details,
  List<JDDialogAction> actions = const [],
  bool barrierDismissible = true,
  double width = 420,
  IconData? customIcon,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black54,
    builder: (_) => JDDialog(
      type: type,
      title: title,
      message: message,
      body: body,
      details: details,
      actions: actions,
      width: width,
      customIcon: customIcon,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Atajos rápidos
// ─────────────────────────────────────────────────────────────────────

/// Alerta simple con un solo botón "Entendido"
Future<void> showJDAlert({
  required BuildContext context,
  required JDDialogType type,
  required String title,
  String? message,
  Widget? details,
  String buttonText = 'Entendido',
}) {
  return showJDDialog(
    context: context,
    type: type,
    title: title,
    message: message,
    details: details,
    actions: [
      JDDialogAction(
        label: buttonText,
        isPrimary: true,
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}

/// Confirmación con Cancelar / Confirmar. Devuelve true si confirma.
Future<bool> showJDConfirm({
  required BuildContext context,
  required JDDialogType type,
  required String title,
  String? message,
  Widget? details,
  String cancelText = 'Cancelar',
  String confirmText = 'Confirmar',
  IconData? confirmIcon,
  bool isDangerConfirm = false,
}) async {
  final result = await showJDDialog<bool>(
    context: context,
    type: type,
    title: title,
    message: message,
    details: details,
    barrierDismissible: false,
    actions: [
      JDDialogAction(
        label: cancelText,
        onPressed: () => Navigator.pop(context, false),
      ),
      JDDialogAction(
        label: confirmText,
        icon: confirmIcon,
        isPrimary: true,
        isDanger: isDangerConfirm,
        onPressed: () => Navigator.pop(context, true),
      ),
    ],
  );
  return result ?? false;
}

// ─────────────────────────────────────────────────────────────────────
// Tarjeta decorativa (para mostrar datos del trabajador, etc.)
// ─────────────────────────────────────────────────────────────────────

class JDGradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final double borderRadius;

  const JDGradientCard({
    Key? key,
    this.colors = const [Color(0xFF28a745), Color(0xFF20c997)],
    required this.child,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Caja de información (tip / nota)
// ─────────────────────────────────────────────────────────────────────

class JDInfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? bgColor;
  final Color? borderColor;

  const JDInfoBox({
    Key? key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.bgColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? const Color(0xFFB7EBC6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? const Color(0xFF28a745), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
