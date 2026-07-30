import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/change_password_dialog.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_profile_hero.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../data/nestjs_user_repository.dart';
import '../../../../domain/models/user_profile.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../providers/parent_portal_providers.dart';
import '../widgets/profile_widgets.dart';

class ParentProfilePage extends ConsumerStatefulWidget {
  const ParentProfilePage({super.key});

  @override
  ConsumerState<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends ConsumerState<ParentProfilePage> {
  static const _maxUploadBytes = 900 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();

  bool _hydrated = false;
  bool _isSaving = false;
  String? _avatarUrl;
  String? _avatarLocalPath;
  String? _email;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(parentUserProfileProvider);
    final session = ref.watch(appSessionControllerProvider).session;

    ref.listen(parentUserProfileProvider, (previous, next) {
      next.whenData((data) {
        if (!_hydrated) _applyProfile(data);
      });
    });

    Future<void> confirmSignOut() async {
      final shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sair do app?'),
          content: const Text('Sua sessão será encerrada neste aparelho.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair'),
            ),
          ],
        ),
      );

      if (shouldSignOut == true) {
        await ref.read(appSessionControllerProvider.notifier).signOut();
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        appBar: FaixaAppBar.screen(
          title: 'Meu perfil',
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() => _hydrated = false);
                      ref.invalidate(parentUserProfileProvider);
                    },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        bottomNavigationBar: profileAsync.maybeWhen(
          data: (_) => SafeArea(
            top: false,
            // Ver driver_settings_page.dart: piso mínimo para aparelhos que
            // reportam inset bottom = 0 (botão sob a barra de navegação).
            minimum: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: FilledButton.icon(
                onPressed: _isSaving ? null : () => _save(context),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar perfil'),
              ),
            ),
          ),
          orElse: () => null,
        ),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ProfileErrorPane(
            message: AppErrorReporter.messageFor(error),
            onRetry: () => ref.invalidate(parentUserProfileProvider),
          ),
          data: (_) => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                160,
              ),
              children: [
                FaixaProfileHero(
                  name: _nameController.text.trim().isEmpty
                      ? (session?.user.name ?? 'Responsável')
                      : _nameController.text.trim(),
                  subtitle: 'Responsável',
                  avatarUrl: _avatarUrl,
                  avatarLocalPath: _avatarLocalPath,
                  onAvatarTap: _isSaving ? null : _pickAvatar,
                  avatarShape: BoxShape.rectangle,
                ),
                const SizedBox(height: AppSpacing.lg),
                FaixaSectionCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Dados pessoais',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Informe o nome.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [InputFormatters.phone()],
                        decoration: const InputDecoration(
                          labelText: 'Celular / WhatsApp',
                          hintText: '(00) 00000-0000',
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        initialValue: _email ?? '',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FaixaSectionCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Segurança',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.ink,
                    ),
                    title: const Text('Alterar senha'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                    onTap: _isSaving ? null : () => _changePassword(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : confirmSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  label: const Text('Sair'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyProfile(UserProfile data) {
    _hydrated = true;
    _nameController.text = data.name;
    _phoneController.text = InputFormatters.formatPhone(
      (data.cellPhone ?? '').toString(),
    );
    _email = data.email;
    _avatarUrl = data.avatarUrl;
    _avatarLocalPath = null;
    if (mounted) setState(() {});
  }

  Future<void> _changePassword(BuildContext context) async {
    final result = await showDialog<PasswordResult>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
    if (result == null || !context.mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .changePassword(
            currentPassword: result.currentPassword,
            newPassword: result.newPassword,
          );
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: 'Senha alterada com sucesso.',
        type: AppFeedbackType.success,
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: 'Falha ao alterar a senha.',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 58,
      maxWidth: 900,
      maxHeight: 900,
    );
    if (file == null || !mounted) return;

    final bytes = await file.length();
    if (!mounted) return;

    if (bytes > _maxUploadBytes) {
      showAppSnackBar(
        context,
        message:
            'A foto selecionada ficou grande para envio. Escolha outra foto menor.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() => _avatarLocalPath = file.path);
  }

  Future<void> _save(BuildContext context) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (!mounted) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(userRepositoryProvider);

      if (_avatarLocalPath != null) {
        await repo.uploadAvatar(_avatarLocalPath!);
      }

      final updated = await repo.updateMe(
        name: _nameController.text.trim(),
        cellPhone: _phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      // APP-21/22: AuthUser não carrega mais telefone/avatar — a sessão
      // atualiza só o nome; o avatar exibido vem do perfil recém-salvo.
      ref
          .read(appSessionControllerProvider.notifier)
          .updateCurrentUser(name: updated.name);

      _applyProfile(updated);
      ref.invalidate(parentUserProfileProvider);

      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: 'Perfil atualizado com sucesso.',
        type: AppFeedbackType.success,
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: 'Falha ao salvar perfil.',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
