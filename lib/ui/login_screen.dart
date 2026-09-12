import 'package:flutter/material.dart';

import '../data/remote/autenticacion.dart';
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
    required this.autenticacion,
    required this.tienda,
  });

  /// La interfaz, no SesionService: ese envuelve el SDK de Supabase y no se
  /// construye sin un cliente vivo, lo que dejaba esta pantalla imposible de
  /// montar en una prueba. Y es donde vive el flujo mas delicado de la app:
  /// crear la cuenta, crear la ficha de negocio, y no dejar al usuario a
  /// medias entre las dos cosas.
  final Autenticacion autenticacion;
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

  /// La cuenta se creo pero falta abrir el correo. Se muestra un aviso propio
  /// en vez de un mensaje de error, porque no hay nada que corregir.
  bool _confirmacionPendiente = false;

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
        final conSesion = await widget.autenticacion.registrarse(
          correo: correo,
          clave: clave,
        );

        // Si el proyecto exige confirmar el correo, no hay sesion todavia. No
        // es un fallo: falta que el usuario abra su correo. La ficha de
        // negocio no se puede crear aun --fn_registrar_cliente exige sesion--
        // asi que se crea al ingresar, con [_asegurarFicha].
        if (!conSesion) {
          if (!mounted) return;
          setState(() {
            _cargando = false;
            _registrando = false;
            _confirmacionPendiente = true;
            _error = null;
          });
          return;
        }

        await _asegurarFicha();
      } else {
        await widget.autenticacion.ingresar(correo: correo, clave: clave);
        // Quien confirmo su correo entra por aqui la primera vez, todavia sin
        // ficha: sin ella fn_cliente_actual() devuelve null y no podria ni
        // comprar ni ver ofertas.
        await _asegurarFicha();
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/tienda');
    } on AutenticacionException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.mensaje;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo continuar: $e';
      });
    }
  }

  /// Crea la ficha de negocio si el usuario todavia no la tiene.
  ///
  /// `fn_registrar_cliente` es idempotente: si ya existe devuelve la suya, asi
  /// que llamarla de mas no duplica nada. El nombre solo se usa cuando hay que
  /// crearla; si el usuario confirmo su correo en otro dispositivo y el
  /// formulario de ingreso no lo pidio, se cae al nombre del correo, que el
  /// cliente puede corregir despues.
  Future<void> _asegurarFicha() async {
    final yaTiene = await widget.tienda.clienteActual();
    if (yaTiene != null) return;

    final nombre = _nombre.text.trim();
    await widget.tienda.registrarCliente(
      nombre: nombre.isEmpty ? _correo.text.trim().split('@').first : nombre,
      paterno: _apellido.text.trim().isEmpty ? null : _apellido.text.trim(),
    );
  }

  Future<void> _recuperarClave() async {
    final correo = _correo.text.trim();
    if (correo.isEmpty) {
      setState(() => _error = 'Escribe tu correo y vuelve a pulsar.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await widget.autenticacion.recuperarClave(correo);
      if (!mounted) return;
      setState(() {
        _cargando = false;
        // No se dice si la cuenta existe: eso revelaria a cualquiera que
        // correos estan registrados en la tienda.
        _error = 'Si esa cuenta existe, le enviamos un correo para cambiar la clave.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo enviar el correo: $e';
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

                  // Cuenta creada, falta abrir el correo. No es un error: no
                  // hay nada que corregir en el formulario, solo un paso
                  // pendiente fuera de la app.
                  if (_confirmacionPendiente) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.mark_email_unread_outlined,
                            color: AppTheme.success,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Revisa tu correo',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Te enviamos un enlace a ${_correo.text.trim()}. '
                            'Abrelo para confirmar la cuenta y despues ingresa '
                            'aqui con tu clave.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

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
                  if (!_registrando)
                    TextButton(
                      onPressed: _cargando ? null : _recuperarClave,
                      child: const Text('Olvide mi clave'),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cargando
                        ? null
                        : () => setState(() {
                            _registrando = !_registrando;
                            _error = null;
                            _confirmacionPendiente = false;
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
