import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/inventario_provider.dart';
import 'services/database_service.dart';
import 'services/supabase_service.dart';
import 'services/inventario_service.dart';
import 'utils/create_test_employee.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar base de datos local
  await DatabaseService().isar;
  
  // 🔧 CONFIGURAR SUPABASE: Reemplaza con tus credenciales
   await SupabaseService().initialize(
     'https://pqdcwiqiyxifiwthleot.supabase.co',  // ← Tu URL de Supabase
     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxZGN3aXFpeXhpZml3dGhsZW90Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0NDg0OTIsImV4cCI6MjA3NjAyNDQ5Mn0.akYp9itTfMBXoN1aX7FABDI56hQCX_OV__sZkeAV8ZU',                  // ← Tu anon/public key
   );
  
  // Crear datos de prueba
  await CreateTestEmployee.createTestData();
  
  // Inicializar stock inicial
  await InventarioService().inicializarStockInicial();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => InventarioProvider()),
      ],
      child: MaterialApp(
        title: 'Sistema de Inventario',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Inicializar autenticación
      await context.read<AuthProvider>().initialize();
      
      // Inicializar inventario
      await context.read<InventarioProvider>().loadInventario();
      
      // Pequeña pausa para mostrar el splash
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Navegar según estado de autenticación
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error inicializando: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2,
                size: 120,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Sistema de Inventario',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Decoración y Construcción',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
