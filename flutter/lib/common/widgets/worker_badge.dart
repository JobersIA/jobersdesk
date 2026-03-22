import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'jobdesk_dialog.dart';

const String kWorkerCodeKey = 'jobdesk_worker_code';
const String _kWorkerNameKey = 'jobdesk_worker_name';
const String _kWorkerRoleKey = 'jobdesk_worker_role';
const String _kApiUrl = 'https://jobdesk.jobers.es/api/worker/validate';
const String _kCheckTargetUrl =
    'https://jobdesk.jobers.es/api/worker/check-target';

// ────────────────────────────────────────────────────────────────────
// Notifier global — cualquier widget escucha cambios
// ────────────────────────────────────────────────────────────────────
class WorkerIdentity extends ChangeNotifier {
  static final WorkerIdentity instance = WorkerIdentity._();
  WorkerIdentity._();

  String? code;
  String? name;
  String? role;

  bool get isIdentified => code != null && code!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    code = prefs.getString(kWorkerCodeKey);
    name = prefs.getString(_kWorkerNameKey);
    role = prefs.getString(_kWorkerRoleKey);
    notifyListeners();
  }

  Future<void> save(String c, String n, String r) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kWorkerCodeKey, c);
    await prefs.setString(_kWorkerNameKey, n);
    await prefs.setString(_kWorkerRoleKey, r);
    code = c;
    name = n;
    role = r;
    notifyListeners();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kWorkerCodeKey);
    await prefs.remove(_kWorkerNameKey);
    await prefs.remove(_kWorkerRoleKey);
    code = null;
    name = null;
    role = null;
    notifyListeners();
  }
}

// ────────────────────────────────────────────────────────────────────
// Funciones de utilidad
// ────────────────────────────────────────────────────────────────────

Future<bool> isWorkerIdentified() async {
  if (!WorkerIdentity.instance.isIdentified) {
    await WorkerIdentity.instance.load();
  }
  return WorkerIdentity.instance.isIdentified;
}

Future<bool> isTargetWorker(String rustdeskId) async {
  try {
    final resp = await http
        .post(
          Uri.parse(_kCheckTargetUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'rustdesk_id': rustdeskId}),
        )
        .timeout(const Duration(seconds: 5));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['is_worker'] == true;
    }
  } catch (_) {}
  return false;
}

Future<bool> isConnectionAllowed(String targetId) async {
  if (await isWorkerIdentified()) return true;
  if (await isTargetWorker(targetId)) return true;
  return false;
}

/// Diálogo: conexión no permitida (necesita identificarse)
void showWorkerRequiredDialog(BuildContext context) {
  showJDDialog(
    context: context,
    type: JDDialogType.danger,
    title: 'Conexión no permitida',
    message:
        'Para conectarte a otros equipos necesitas identificarte como trabajador de Jobers.\n\n'
        'Pulsa el botón "Soy Trabajador" e introduce tu código (ejemplo: F001).',
    customIcon: Icons.block_rounded,
    details: JDInfoBox(
      icon: Icons.info_outline_rounded,
      text: 'Si no tienes código, solicítalo a tu administrador.',
      iconColor: Colors.grey[500],
      bgColor: Colors.grey[50],
      borderColor: Colors.grey[200],
    ),
    actions: [
      JDDialogAction(
        label: 'Entendido',
        isPrimary: true,
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}

// ────────────────────────────────────────────────────────────────────
// Banner superior — visible en toda la app cuando hay trabajador
// ────────────────────────────────────────────────────────────────────
class WorkerTopBanner extends StatelessWidget {
  const WorkerTopBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WorkerIdentity.instance,
      builder: (context, _) {
        final wi = WorkerIdentity.instance;
        if (!wi.isIdentified) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF28a745), Color(0xFF20c997)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    wi.name != null && wi.name!.isNotEmpty
                        ? wi.name![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  wi.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  wi.code ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// WorkerBadge — botón principal en la home
// ────────────────────────────────────────────────────────────────────

class WorkerBadge extends StatefulWidget {
  const WorkerBadge({Key? key}) : super(key: key);

  @override
  State<WorkerBadge> createState() => _WorkerBadgeState();
}

class _WorkerBadgeState extends State<WorkerBadge>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _hovering = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WorkerIdentity.instance.load();
    WorkerIdentity.instance.addListener(_onIdentityChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _onIdentityChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WorkerIdentity.instance.removeListener(_onIdentityChanged);
    _pulseController.dispose();
    super.dispose();
  }

  // ── Validar código contra API ──
  Future<Map<String, dynamic>?> _validateCode(String code) async {
    setState(() => _loading = true);
    try {
      final resp = await http
          .post(
            Uri.parse(_kApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code.toUpperCase()}),
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['ok'] == true) return data['worker'];
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Diálogo: introducir código ──
  void _showCodeDialog() {
    final ctrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => JDDialog(
          type: JDDialogType.worker,
          title: 'Identificación de Trabajador',
          message:
              'Introduce tu código personal para identificarte en este equipo.',
          body: TextField(
            controller: ctrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 4,
            autofocus: true,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 10,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'F001',
              hintStyle: TextStyle(
                  color: Colors.grey[300],
                  letterSpacing: 10,
                  fontWeight: FontWeight.w400),
              counterText: '',
              errorText: errorText,
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFF28a745), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFee5a24), width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFee5a24), width: 2),
              ),
            ),
            onSubmitted: (_) async {
              final code = ctrl.text.trim();
              if (code.length != 4) {
                setDlg(
                    () => errorText = 'Formato: 1 letra + 3 números');
                return;
              }
              final worker = await _validateCode(code);
              if (worker != null) {
                Navigator.pop(ctx);
                _showSaveDialog(worker);
              } else {
                setDlg(
                    () => errorText = 'Código no válido o sin conexión');
              }
            },
          ),
          actions: [
            JDDialogAction(
              label: 'Cancelar',
              onPressed: () => Navigator.pop(ctx),
            ),
            JDDialogAction(
              label: 'Validar',
              icon: Icons.check_circle_outline_rounded,
              isPrimary: true,
              onPressed: _loading
                  ? null
                  : () async {
                      final code = ctrl.text.trim();
                      if (code.length != 4) {
                        setDlg(() =>
                            errorText = 'Formato: 1 letra + 3 números');
                        return;
                      }
                      final worker = await _validateCode(code);
                      if (worker != null) {
                        Navigator.pop(ctx);
                        _showSaveDialog(worker);
                      } else {
                        setDlg(() =>
                            errorText = 'Código no válido o sin conexión');
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ── Diálogo: ¿Guardar en este equipo? ──
  void _showSaveDialog(Map<String, dynamic> worker) {
    final wName = worker['name'] as String? ?? '';
    final wCode = worker['code'] as String? ?? '';
    final wRole = worker['role'] as String? ?? '';

    showJDDialog(
      context: context,
      type: JDDialogType.success,
      title: '¡Identificación correcta!',
      barrierDismissible: false,
      body: Column(
        children: [
          // Tarjeta del trabajador
          JDGradientCard(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      wName.isNotEmpty ? wName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  wName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$wCode  ·  $wRole',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const JDInfoBox(
            icon: Icons.save_outlined,
            text:
                '¿Guardar tu identificación en este equipo para no volver a pedirla?',
          ),
        ],
      ),
      actions: [
        JDDialogAction(
          label: 'Solo esta vez',
          onPressed: () {
            Navigator.pop(context);
            final wi = WorkerIdentity.instance;
            wi.code = wCode;
            wi.name = wName;
            wi.role = wRole;
            wi.notifyListeners();
          },
        ),
        JDDialogAction(
          label: 'Guardar siempre',
          icon: Icons.save_rounded,
          isPrimary: true,
          onPressed: () async {
            Navigator.pop(context);
            await WorkerIdentity.instance.save(wCode, wName, wRole);
          },
        ),
      ],
    );
  }

  // ── Diálogo: cerrar identificación ──
  void _showLogoutDialog() {
    final wi = WorkerIdentity.instance;
    showJDDialog(
      context: context,
      type: JDDialogType.warning,
      title: 'Cerrar identificación',
      message: '¿Quieres dejar de estar identificado como ${wi.name}?',
      customIcon: Icons.logout_rounded,
      actions: [
        JDDialogAction(
          label: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        JDDialogAction(
          label: 'Cerrar sesión',
          isPrimary: true,
          isDanger: true,
          icon: Icons.logout_rounded,
          onPressed: () async {
            Navigator.pop(context);
            await WorkerIdentity.instance.clear();
          },
        ),
      ],
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WorkerIdentity.instance,
      builder: (context, _) {
        final wi = WorkerIdentity.instance;
        if (wi.isIdentified) return _buildIdentified(wi);
        return _buildButton();
      },
    );
  }

  // ── Tarjeta de trabajador identificado ──
  Widget _buildIdentified(WorkerIdentity wi) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF28a745), Color(0xFF20c997)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28a745).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    wi.name != null && wi.name!.isNotEmpty
                        ? wi.name![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wi.name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            wi.code ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          wi.role ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _showLogoutDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Botón "Soy Trabajador" ──
  Widget _buildButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _hovering ? 1.03 : _pulseAnimation.value,
              child: child,
            );
          },
          child: GestureDetector(
            onTap: _showCodeDialog,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _hovering
                      ? const [Color(0xFF218838), Color(0xFF1aae88)]
                      : const [Color(0xFF28a745), Color(0xFF20c997)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF28a745)
                        .withOpacity(_hovering ? 0.45 : 0.3),
                    blurRadius: _hovering ? 20 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soy Trabajador',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Pulsa para identificarte',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
