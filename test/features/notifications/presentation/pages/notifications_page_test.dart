import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/core/models/paginated_result.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_controller.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_state.dart';
import 'package:app_faixa_amarela/features/notifications/data/app_notification.dart';
import 'package:app_faixa_amarela/features/notifications/data/notification_repository.dart';
import 'package:app_faixa_amarela/features/notifications/presentation/pages/notifications_page.dart';
import 'package:app_faixa_amarela/features/notifications/presentation/providers/notification_providers.dart';
import 'package:app_faixa_amarela/features/notifications/presentation/widgets/notification_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

class _FakeAppSessionController extends AppSessionController {
  @override
  AppSessionState build() {
    return AppSessionState(
      session: AuthSession(
        accessToken: 'tok',
        tokenType: 'Bearer',
        user: AuthUser(
          id: 1,
          name: 'Responsável',
          email: 'resp@example.com',
          roles: const ['user'],
        ),
      ),
      isLoading: false,
      loginRole: UserRole.parent,
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  late _MockNotificationRepository repository;

  final longBody = List.filled(
    40,
    'A van escolar está a caminho do ponto de embarque com tudo dentro do previsto.',
  ).join(' ');

  final unread = AppNotification(
    id: '1',
    type: 'boarded',
    title: 'Embarque realizado',
    body: longBody,
    data: const {},
    createdAt: DateTime(2026, 7, 8, 8, 30),
  );

  final alreadyRead = AppNotification(
    id: '2',
    type: 'system',
    title: 'Aviso do sistema',
    body: 'Manutenção programada concluída.',
    data: const {},
    createdAt: DateTime(2026, 7, 7, 18, 5),
    readAt: DateTime(2026, 7, 7, 19, 0),
  );

  setUp(() {
    repository = _MockNotificationRepository();
    when(
      () => repository.notifications(
        any(),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResult<AppNotification>(
        items: [unread, alreadyRead],
        currentPage: 1,
        lastPage: 1,
        total: 2,
      ),
    );
    when(() => repository.unreadCount(any())).thenAnswer((_) async => 1);
    when(() => repository.markAsRead(any(), any())).thenAnswer((_) async {});
    when(() => repository.markAllAsRead(any())).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSessionControllerProvider.overrideWith(
            _FakeAppSessionController.new,
          ),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const NotificationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tap abre sheet com título, corpo completo, badge e data, e marca como lida',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Embarque realizado'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationDetailSheet), findsOneWidget);
      // Título completo no cabeçalho do sheet.
      expect(find.text('Embarque realizado'), findsWidgets);
      // Corpo completo (sem ellipsis), selecionável.
      expect(find.byType(SelectableText), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NotificationDetailSheet),
          matching: find.text(longBody, findRichText: true),
        ),
        findsOneWidget,
      );
      // Badge de tipo e data/hora em pt-BR.
      expect(find.text('Embarque'), findsOneWidget);
      expect(find.text('08/07/2026 08:30'), findsOneWidget);
      expect(find.text('Fechar'), findsOneWidget);

      verify(() => repository.markAsRead('Bearer tok', '1')).called(1);

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationDetailSheet), findsNothing);
    },
  );

  testWidgets('mensagem longa rola dentro do sheet com altura máxima de 70%',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Embarque realizado'));
    await tester.pumpAndSettle();

    final sheetSize = tester.getSize(find.byType(NotificationDetailSheet));
    final screenHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio;
    expect(sheetSize.height, lessThanOrEqualTo(screenHeight * 0.7 + 0.5));

    // Conteúdo rola dentro do sheet (scroll interno).
    expect(
      find.descendant(
        of: find.byType(NotificationDetailSheet),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('notificação já lida abre o sheet sem chamar markAsRead',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Aviso do sistema'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationDetailSheet), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);
    verifyNever(() => repository.markAsRead(any(), any()));
  });
}
