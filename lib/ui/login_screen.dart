import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/remote/sesion_service.dart';
import '../data/repositories/tienda_repository.dart';
import '../theme/app_theme.dart';

/// Ingreso y registro con correo y clave.
///
/// La clave no se guarda ni se hashea aqui: va directa al SDK de Supabase por
/// HTTPS, y el hash (bcrypt) lo hace el servidor en un esquema al que la app
/// no tiene acceso. Escribir uno mismo el hashing de contrasenas es facil de
/// hacer mal — salt reutilizado, algoritmo rapido, comparacion no constante —
/// y delegarlo elimina esa categoria entera de errores.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.sesion,
    required this.tienda,
  });

  final SesionService sesion;
  final TiendaRepository tienda;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();

  bool _registrando = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    _nombre.dispose();
    _apellido.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final correo = _correo.text.trim();
    final clave = _clave.text;

    if (correo.isEmpty || clave.isEmpty) {
      setState(() => _error = 'El correo y la clave son obligatorios.');
      return;
    }
    if (_registrando && _nombre.text.trim().isEmpty) {
      setState(() => _error = 'Falta tu nombre.');
      return;
    }
    // El minimo de Supabase son 6 caracteres. Se comprueba aqui para no gastar
    // un viaje de red en decir algo que ya se sabe.
    if (_registrando && clave.length < 6) {
      setState(() => _error = 'La clave necesita al menos 6 caracteres.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      if (_registrando) {
        final respuesta = await widget.sesion.registrarse(
          correo: correo,
          clave: clave,
        );

        // Si el proyecto exige confirmar el correo, la sesion viene null. No
        // es un fallo: falta que el usuario abra su correo.
        if (respuesta.session == null) {
          if (!mounted) return;
          setState(() {
            _cargando = false;
            _registrando = false;
            _error = 'Revisa tu correo para confirmar la cuenta y luego ingresa.';
          });
          return;
        }

        // Con sesion ya abierta se crea la ficha de negocio.
        await widget.tienda.registrarCliente(
          nombre: _nombre.text.trim(),
          paterno: _apellido.text.trim().isEmpty ? null : _apellido.text.trim(),
        );
      } else {
        await widget.sesion.ingresar(correo: correo, clave: clave);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/tienda');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo continuar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 56,
                    color: AppTheme.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tienda Adaptativa',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _registrando
                        ? 'Crea tu cuenta para empezar'
                        : 'Ingresa con tu cuenta',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_registrando) ...[
                    TextField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apellido,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Apellido (opcional)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clave,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Clave',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    onSubmitted: (_) => _cargando ? null : _enviar(),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.danger,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _cargando ? null : _enviar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_registrando ? 'Crear cuenta' : 'Ingresar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cargando
                        ? null
                        : () => setState(() {
                            _registrando = !_registrando;
                            _error = null;
                          }),
                    child: Text(
                      _registrando
                          ? 'Ya tengo cuenta'
                          : 'No tengo cuenta, quiero registrarme',
                    ),
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
