import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kWorkerCodeKey = 'jobersdesk_worker_code';
const String _kWorkerNameKey = 'jobersdesk_worker_name';
const String _kWorkerRoleKey = 'jobersdesk_worker_role';
const String _kApiUrl = 'https://jobdesk.jobers.es/api/worker/validate';

class WorkerBadge extends StatefulWidget {
  const WorkerBadge({Key? key}) : super(key: key);

  @override
  State<WorkerBadge> createState() => _WorkerBadgeState();
}

class _WorkerBadgeState extends State<WorkerBadge> {
  String? _code;
  String? _name;
  String? _role;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _code = prefs.getString(_kWorkerCodeKey);
      _name = prefs.getString(_kWorkerNameKey);
      _role = prefs.getString(_kWorkerRoleKey);
    });
  }

  Future<void> _saveClear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWorkerCodeKey);
    await prefs.remove(_kWorkerNameKey);
    await prefs.remove(_kWorkerRoleKey);
    setState(() {
      _code = null;
      _name = null;
      _role = null;
    });
  }

  Future<bool> _validate(String code) async {
    setState(() => _loading = true);
    try {
      final resp = await http.post(
        Uri.parse(_kApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code.toUpperCase()}),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['ok'] == true) {
          final w = data['worker'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kWorkerCodeKey, w['code']);
          await prefs.setString(_kWorkerNameKey, w['name']);
          await prefs.setString(_kWorkerRoleKey, w['role']);
          setState(() {
            _code = w['code'];
            _name = w['name'];
            _role = w['role'];
          });
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showCodeDialog() {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF28a745), Color(0xFF20c997)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF28a745).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.badge_outlined, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Identificación de Trabajador',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Introduce tu código de trabajador para identificarte.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 4,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'F001',
                    hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 6),
                    counterText: '',
                    errorText: errorText,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF28a745), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                final code = controller.text.trim();
                                if (code.length != 4) {
                                  setDialogState(() => errorText = 'Formato: 1 letra + 3 números');
                                  return;
                                }
                                final ok = await _validate(code);
                                if (ok) {
                                  Navigator.pop(ctx);
                                } else {
                                  setDialogState(() => errorText = 'Código no válido');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28a745),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Validar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_code != null && _name != null) {
      // Trabajador identificado
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF28a745), Color(0xFF20c997)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF28a745).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _code!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _role ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _saveClear,
              child: Icon(
                Icons.logout_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
          ],
        ),
      );
    }

    // Sin identificar - botón para identificarse
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _showCodeDialog,
        icon: const Icon(Icons.badge_outlined, size: 18),
        label: const Text('Soy trabajador'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF28a745),
          side: const BorderSide(color: Color(0xFF28a745)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
