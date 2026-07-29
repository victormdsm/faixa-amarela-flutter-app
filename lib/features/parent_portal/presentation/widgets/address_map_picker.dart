import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../domain/models/address_suggestion.dart';
import '../providers/parent_portal_providers.dart';

/// Origem da resolução de endereço entregue pelo [AddressMapPicker]:
/// - [reverse]: reverse geocoding disparado ao parar de mover o mapa (ou
///   pelo GPS) — efeito colateral, então o consumidor preenche SOMENTE
///   campos vazios, nunca sobrescreve o que o usuário digitou.
/// - [search]: sugestão escolhida explicitamente na busca — ação do usuário,
///   o consumidor pode preencher todos os campos que a sugestão trouxer.
enum AddressResolveSource { reverse, search }

/// Handle imperativo para o consumidor mover o mapa do [AddressMapPicker]
/// (ex.: após o geocode forward do endereço digitado com rua + número).
/// Opcional: o picker funciona normalmente sem ele.
class AddressMapPickerController {
  _AddressMapPickerState? _state;

  void _attach(_AddressMapPickerState state) => _state = state;

  void _detach(_AddressMapPickerState state) {
    if (identical(_state, state)) _state = null;
  }

  /// Move a câmera para [point] (zoom de rua), marca o ponto como definido
  /// pelo usuário e atualiza o label do overlay quando informado. Movimento
  /// programático: NÃO dispara reverse geocoding.
  void moveTo(LatLng point, {String? label}) {
    _state?._moveToAddress(point, label: label);
  }
}

/// Mapa de endereço estilo Uber: o pin fica FIXO no centro e o mapa desliza
/// sob ele. Ao parar de mover (debounce de 500ms) o centro é resolvido via
/// reverse geocoding; a busca no topo usa autocomplete (debounce de 400ms) e
/// o botão flutuante centraliza no GPS do aparelho.
///
/// O widget é semicondutor de estado:
/// - [onPositionChanged]: centro do pin sempre que o usuário define um ponto
///   (gesto, GPS, escolha na busca ou [AddressMapPickerController.moveTo]).
///   Movimentos programáticos (ex.: recentralizar na cidade) NÃO disparam o
///   callback.
/// - [onAddressResolved]: endereço estruturado resolvido ou escolhido, com a
///   [AddressResolveSource] indicando a origem — reverse (mapa parou, o
///   consumidor preenche só campos vazios) ou search (escolha explícita na
///   busca, o consumidor pode preencher tudo). Quem preenche é o consumidor.
/// - [onError]: mensagens amigáveis PT-BR para o consumidor exibir.
class AddressMapPicker extends ConsumerStatefulWidget {
  const AddressMapPicker({
    super.key,
    this.controller,
    this.initialPosition,
    this.initialLabel,
    this.cityBias,
    this.height = 300,
    required this.onPositionChanged,
    required this.onAddressResolved,
    this.onError,
  });

  /// Handle imperativo opcional para o consumidor mover o mapa (ex.: após o
  /// geocode forward do endereço digitado com número).
  final AddressMapPickerController? controller;

  /// Posição inicial do pin (ex.: endereço já salvo na edição). Quando nula,
  /// o mapa recentraliza na [cityBias] via geocode ao ficar pronto.
  final LatLng? initialPosition;

  /// Label inicial do overlay (ex.: endereço já salvo).
  final String? initialLabel;

  /// Cidade/UF usados como viés no autocomplete e na centralização inicial
  /// (ex.: "São Paulo, SP"). Ao trocar, o mapa recentraliza na nova cidade.
  final String? cityBias;

  final double height;

  final ValueChanged<LatLng> onPositionChanged;

  /// Chamado com a sugestão e a origem da resolução: reverse (o mapa parou
  /// de mover — preencher somente campos vazios) ou search (o usuário
  /// escolheu uma sugestão na busca — preenchimento completo é bem-vindo).
  final void Function(
    AddressSuggestion suggestion,
    AddressResolveSource source,
  )
  onAddressResolved;
  final ValueChanged<String>? onError;

  @override
  ConsumerState<AddressMapPicker> createState() => _AddressMapPickerState();
}

class _AddressMapPickerState extends ConsumerState<AddressMapPicker>
    with TickerProviderStateMixin {
  /// Centro do Brasil — visão neutra antes de qualquer geocode.
  static const _defaultCenter = LatLng(-14.2350, -51.9253);

  /// Distância mínima do último ponto resolvido para chamar o reverse de
  /// novo (evita chamadas redundantes em pinch zoom quase parado).
  static const _minResolveDistanceM = 15.0;

  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _reverseDebounce = Debouncer(delay: const Duration(milliseconds: 500));
  final _searchDebounce = Debouncer(delay: const Duration(milliseconds: 400));

  bool _mapReady = false;

  bool _reverseLoading = false;
  bool _reverseFailed = false;
  String? _overlayLabel;

  bool _searching = false;
  List<AddressSuggestion>? _suggestions;
  bool _searchNoResults = false;

  bool _locating = false;

  int _reverseSeq = 0;
  int _searchSeq = 0;
  LatLng? _pendingCenter;
  LatLng? _lastResolvedCenter;
  LatLng? _userDefinedCenter;

  /// moveTo recebido antes do mapa ficar pronto — aplicado no _onMapReady.
  ({LatLng point, String? label})? _pendingMoveTo;

  @override
  void initState() {
    super.initState();
    _overlayLabel = widget.initialLabel;
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _reverseDebounce.dispose();
    _searchDebounce.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AddressMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.cityBias != widget.cityBias &&
        (widget.cityBias ?? '').trim().isNotEmpty) {
      _recenterOnCity();
    }
    if (oldWidget.initialLabel != widget.initialLabel &&
        widget.initialLabel != null) {
      setState(() => _overlayLabel = widget.initialLabel);
    }
    // Endereço carregado depois do mapa pronto (edição): move para ele,
    // desde que o usuário ainda não tenha definido um ponto.
    if (oldWidget.initialPosition != widget.initialPosition &&
        widget.initialPosition != null &&
        _userDefinedCenter == null &&
        _mapReady) {
      _animatedMove(widget.initialPosition!, 17);
    }
  }

  void _onMapReady() {
    _mapReady = true;
    // moveTo chamado antes do mapa ficar pronto (ex.: geocode forward muito
    // rápido): aplica agora e não recentraliza na cidade.
    final pending = _pendingMoveTo;
    if (pending != null) {
      _pendingMoveTo = null;
      _moveToAddress(pending.point, label: pending.label);
      return;
    }
    if (widget.initialPosition == null &&
        (widget.cityBias ?? '').trim().isNotEmpty) {
      _recenterOnCity();
    }
  }

  // -------------------------------------------------------------------------
  // Movimentação do mapa → reverse geocoding
  // -------------------------------------------------------------------------

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    // Movimentos programáticos (cidade, busca, GPS) são tratados pelos
    // próprios callers; aqui só interessa o gesto do usuário.
    if (!hasGesture) return;
    _pendingCenter = camera.center;
    _reverseDebounce.run(() {
      final center = _pendingCenter;
      if (center != null) _resolveCenter(center);
    });
  }

  Future<void> _resolveCenter(LatLng center) async {
    _userDefinedCenter = center;
    widget.onPositionChanged(center);

    final last = _lastResolvedCenter;
    if (last != null &&
        const Distance().as(LengthUnit.Meter, last, center) <
            _minResolveDistanceM) {
      return;
    }

    final seq = ++_reverseSeq;
    setState(() {
      _reverseLoading = true;
      _reverseFailed = false;
    });
    try {
      final result = await ref
          .read(childrenRepositoryProvider)
          .reverseAddress(
            latitude: center.latitude,
            longitude: center.longitude,
          );
      if (!mounted || seq != _reverseSeq) return;
      _lastResolvedCenter = center;
      setState(() {
        _reverseLoading = false;
        _overlayLabel = result.label;
      });
      widget.onAddressResolved(result, AddressResolveSource.reverse);
    } catch (e) {
      if (!mounted || seq != _reverseSeq) return;
      setState(() {
        _reverseLoading = false;
        _reverseFailed = true;
      });
      widget.onError?.call(AppErrorReporter.messageFor(e));
    }
  }

  void _retryReverse() {
    if (!_mapReady) return;
    _lastResolvedCenter = null;
    _resolveCenter(_mapController.camera.center);
  }

  // -------------------------------------------------------------------------
  // Busca (autocomplete)
  // -------------------------------------------------------------------------

  void _onSearchChanged(String value) {
    setState(() {}); // atualiza o suffix (limpar/loading)
    _searchSeq++;
    final query = value.trim();
    if (query.length < 3) {
      _searchDebounce.cancel();
      if (_suggestions != null || _searchNoResults || _searching) {
        setState(() {
          _suggestions = null;
          _searchNoResults = false;
          _searching = false;
        });
      }
      return;
    }
    _searchDebounce.run(() => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final seq = ++_searchSeq;
    setState(() => _searching = true);
    try {
      final results = await ref
          .read(childrenRepositoryProvider)
          .autocompleteAddress(query, city: widget.cityBias);
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searching = false;
        _suggestions = results;
        _searchNoResults = results.isEmpty;
      });
    } catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searching = false;
        _suggestions = null;
        _searchNoResults = false;
      });
      widget.onError?.call(AppErrorReporter.messageFor(e));
    }
  }

  void _pickSuggestion(AddressSuggestion suggestion) {
    _searchFocus.unfocus();
    _searchCtrl.text = suggestion.label;
    setState(() {
      _suggestions = null;
      _searchNoResults = false;
      _overlayLabel = suggestion.label;
    });
    widget.onAddressResolved(suggestion, AddressResolveSource.search);
    final lat = suggestion.latitude;
    final lng = suggestion.longitude;
    if (lat != null && lng != null) {
      final dest = LatLng(lat, lng);
      _userDefinedCenter = dest;
      _lastResolvedCenter = dest;
      widget.onPositionChanged(dest);
      _animatedMove(dest, 17);
    }
  }

  // -------------------------------------------------------------------------
  // GPS
  // -------------------------------------------------------------------------

  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        widget.onError?.call(
          'Ative a localização do aparelho para usar sua posição atual.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await _offerOpenSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        widget.onError?.call(
          'Permita o acesso à localização para usar sua posição atual.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      final dest = LatLng(position.latitude, position.longitude);
      _animatedMove(dest, 17);
      await _resolveCenter(dest);
    } catch (_) {
      if (!mounted) return;
      widget.onError?.call(
        'Não conseguimos obter sua localização. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _offerOpenSettings() async {
    if (!mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Localização bloqueada'),
        content: const Text(
          'A permissão de localização está bloqueada. Para usar sua posição '
          'atual, libere o acesso nas configurações do app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abrir configurações'),
          ),
        ],
      ),
    );
    if (open == true) {
      await Geolocator.openAppSettings();
    }
  }

  // -------------------------------------------------------------------------
  // Movimento imperativo (geocode forward do endereço digitado)
  // -------------------------------------------------------------------------

  /// Chamado via [AddressMapPickerController.moveTo]: o consumidor já
  /// resolveu o ponto (geocode forward com rua + número), então aqui só
  /// movemos a câmera — sem reverse (movimento programático) e sem tocar
  /// nos campos de texto.
  void _moveToAddress(LatLng point, {String? label}) {
    if (!_mapReady) {
      _pendingMoveTo = (point: point, label: label);
      return;
    }
    _userDefinedCenter = point;
    _lastResolvedCenter = point;
    if ((label ?? '').trim().isNotEmpty) {
      setState(() => _overlayLabel = label);
    }
    widget.onPositionChanged(point);
    _animatedMove(point, 17);
  }

  // -------------------------------------------------------------------------
  // Centralização na cidade (geocode do cityBias)
  // -------------------------------------------------------------------------

  Future<void> _recenterOnCity() async {
    final city = (widget.cityBias ?? '').trim();
    if (city.isEmpty || !_mapReady) return;
    try {
      final result = await ref
          .read(childrenRepositoryProvider)
          .geocodeAddress(city);
      if (!mounted || result == null) return;
      _animatedMove(LatLng(result.latitude, result.longitude), 13);
      if (result.label != null) {
        setState(() => _overlayLabel = result.label);
      }
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call(AppErrorReporter.messageFor(e));
    }
  }

  // -------------------------------------------------------------------------
  // Animação da câmera (sem dependências extras)
  // -------------------------------------------------------------------------

  void _animatedMove(LatLng destLocation, double destZoom) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialPosition ?? _defaultCenter,
                initialZoom: widget.initialPosition != null ? 17 : 4.5,
                onMapReady: _onMapReady,
                onPositionChanged: _onMapPositionChanged,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'br.com.faixaamarela.app',
                ),
              ],
            ),
            // Sombra do pin no ponto exato do centro.
            const IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 12,
                  height: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.shadowDark,
                      borderRadius: BorderRadius.all(Radius.elliptical(6, 2.5)),
                    ),
                  ),
                ),
              ),
            ),
            // Pin fixo no centro — a base do marcador toca o ponto exato.
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: _AddressPinMarker(),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchBar(context),
                  if (_suggestions != null || _searchNoResults)
                    _buildSuggestionsCard(context),
                  const SizedBox(height: AppSpacing.xs),
                  _buildLabelCard(context),
                ],
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: FloatingActionButton.small(
                heroTag: null,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.ink,
                tooltip: 'Usar minha localização',
                onPressed: _locating ? null : _useMyLocation,
                child: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Material(
      elevation: 2,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar endereço...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchCtrl.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Limpar busca',
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear_rounded, size: 18),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(BuildContext context) {
    final suggestions = _suggestions ?? const <AddressSuggestion>[];
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      constraints: const BoxConstraints(maxHeight: 220),
      child: Material(
        elevation: 2,
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: _searchNoResults
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Nenhum endereço encontrado. Tente rua e número.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    title: Text(
                      suggestion.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: (suggestion.city ?? '').isNotEmpty
                        ? Text(
                            suggestion.state != null
                                ? '${suggestion.city}/${suggestion.state}'
                                : suggestion.city!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () => _pickSuggestion(suggestion),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLabelCard(BuildContext context) {
    final label = _reverseFailed
        ? 'Não conseguimos identificar o endereço neste ponto.'
        : (_overlayLabel ?? 'Mova o mapa para posicionar o pin no endereço.');

    return Material(
      elevation: 2,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              _reverseFailed
                  ? Icons.wrong_location_rounded
                  : Icons.place_rounded,
              size: 16,
              color: _reverseFailed ? AppColors.danger : AppColors.yellowDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _reverseFailed ? AppColors.danger : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_reverseLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (_reverseFailed)
              IconButton(
                tooltip: 'Tentar novamente',
                onPressed: _retryReverse,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: AppColors.danger,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

/// Marcador do endereço no padrão da marca: círculo amarelo com borda ink e
/// o glyph de localização, como o marcador da van no mapa de tracking.
class _AddressPinMarker extends StatelessWidget {
  const _AddressPinMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on_rounded,
        color: AppColors.ink,
        size: 26,
      ),
    );
  }
}
