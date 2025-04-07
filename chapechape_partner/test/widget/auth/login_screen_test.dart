import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chapechape_partner/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_partner/presentation/screens/auth/login_screen.dart';
import 'package:go_router/go_router.dart';

// Mocks
class MockAuthBloc extends Mock implements AuthBloc {}
class MockGoRouter extends Mock implements GoRouter {}

// Route qui ne va nulle part mais qui est nécessaire pour les tests
class _MockRoute extends Mock implements Route {}

void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthUnauthenticated());
  });

  tearDown(() {
    reset(authBloc);
  });

  // Helper pour construire le widget avec le mock BLoC
  Widget createWidgetUnderTest() {
    return MockGoRouterProvider(
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders login form correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Connexion Partenaire'), findsOneWidget);
      expect(find.text('Connectez-vous pour gérer vos résidences'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email ou téléphone'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Mot de passe oublié ?'), findsOneWidget);
      expect(find.text('Pas encore partenaire ?'), findsOneWidget);
      expect(find.text('S\'inscrire'), findsOneWidget);
    });

    testWidgets('validates form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Cliquer sur le bouton de connexion sans remplir les champs
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      // Vérifier que les erreurs de validation s'affichent
      expect(find.text('Ce champ est requis'), findsWidgets);
    });

    testWidgets('dispatches AuthLoginRequested when form is valid', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Remplir le formulaire
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      
      // Cliquer sur le bouton de connexion
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      // Vérifier que l'événement est déclenché avec les bonnes données
      verify(() => authBloc.add(AuthLoginRequested(
        email: 'test@example.com',
        password: 'password123',
      ))).called(1);
    });

    testWidgets('shows loading indicator when AuthLoading', (WidgetTester tester) async {
      when(() => authBloc.state).thenReturn(AuthLoading());
      await tester.pumpWidget(createWidgetUnderTest());

      // Vérifier que l'indicateur de chargement est visible
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows error message when AuthFailure', (WidgetTester tester) async {
      final errorMessage = 'Login failed';
      
      // Configurer le bloc pour émettre une erreur
      when(() => authBloc.state).thenReturn(AuthFailure(errorMessage));
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Vérifier que le message d'erreur s'affiche dans un SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}

// Widget pour simuler le GoRouter dans les tests
class MockGoRouterProvider extends StatelessWidget {
  final Widget child;

  const MockGoRouterProvider({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mockRouter = MockGoRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    
    return InheritedGoRouter(
      goRouter: mockRouter,
      child: child,
    );
  }
}

class InheritedGoRouter extends InheritedWidget {
  final GoRouter goRouter;

  const InheritedGoRouter({
    required this.goRouter,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(InheritedGoRouter oldWidget) {
    return goRouter != oldWidget.goRouter;
  }

  static InheritedGoRouter of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedGoRouter>()!;
  }
} 