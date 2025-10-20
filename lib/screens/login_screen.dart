import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade50,
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 3,
                            ),
                          ),
                          child: CustomPaint(
                            painter: LogoInventarioPainter(),
                            size: const Size(120, 120),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sistema de Inventario',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Decoración y Construcción',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su email';
                            }
                            if (!value.contains('@')) {
                              return 'Ingrese un email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'INICIAR SESIÓN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LogoInventarioPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);
    
    // Caja principal de inventario
    paint.color = Colors.blue.shade700;
    paint.style = PaintingStyle.fill;
    
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 5),
        width: 60,
        height: 40,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(boxRect, paint);
    
    // Parte superior de la caja
    paint.color = Colors.blue.shade400;
    final topRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 5),
        width: 60,
        height: 20,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(topRect, paint);
    
    // Líneas divisorias
    paint.color = Colors.blue.shade900;
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    
    // Línea horizontal superior
    canvas.drawLine(
      Offset(center.dx - 30, center.dy - 5),
      Offset(center.dx + 30, center.dy - 5),
      paint,
    );
    
    // Línea horizontal inferior
    canvas.drawLine(
      Offset(center.dx - 30, center.dy + 15),
      Offset(center.dx + 30, center.dy + 15),
      paint,
    );
    
    // Productos flotantes
    paint.style = PaintingStyle.fill;
    
    // Producto naranja
    paint.color = Colors.orange.shade400;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + 25, center.dy - 15),
          width: 12,
          height: 8,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    
    // Producto azul
    paint.color = Colors.blue.shade600;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + 30, center.dy - 25),
          width: 10,
          height: 6,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    
    // Producto verde
    paint.color = Colors.green.shade500;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + 27, center.dy - 35),
          width: 8,
          height: 5,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    
    // Símbolo de inventario en el centro
    paint.color = Colors.amber.shade600;
    canvas.drawCircle(center, 6, paint);
    
    // Letra "i" en el centro
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'i',
        style: TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
    
    // Líneas de conexión
    paint.color = Colors.blue.shade300;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    
    // Línea punteada a los productos
    final dashPath = Path();
    dashPath.moveTo(center.dx + 15, center.dy);
    dashPath.lineTo(center.dx + 25, center.dy - 15);
    canvas.drawPath(dashPath, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}






