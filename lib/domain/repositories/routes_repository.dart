import '../models/route_manifest.dart';

abstract interface class RoutesRepository {
  /// Opções de planejamento de rota. [shiftId]/[period] filtram as crianças
  /// pelos turnos do período (ver ROUTE_PERIODS no backend); [shiftId] tem
  /// precedência quando ambos são informados.
  Future<RoutePlanningOptions> getPlanningOptions({int? shiftId, String? period});

  Future<List<Map<String, dynamic>>> listDriverRoutes();

  /// [childIds] restringe a rota às crianças selecionadas no planejamento
  /// (ver `PlanningChild.selectedByDefault`). Quando nulo, o backend usa
  /// todas as crianças elegíveis do período — comportamento anterior.
  Future<RouteManifest> startRoute({
    int? shiftId,
    String? period,
    List<int>? childIds,
  });

  Future<void> finishRoute(int id);

  Future<RouteManifest?> getActiveRoute();

  Future<RouteStop> markBoarding(int routeId, int childId);

  Future<RouteStop> markDisembarking(int routeId, int childId);

  Future<RouteStop> markAbsent(int routeId, int childId);

  Future<List<RouteStop>> bulkDisembarkAtSchool(int routeId, int schoolId);

  Future<void> removeStudent(int routeId, int childId);

  Future<void> notifyParent(
    int routeId,
    int childId,
    String type, {
    String? message,
  });

  Future<void> alertAll(int routeId, String type, {String? message});
}

class RoutePlanningOptions {
  const RoutePlanningOptions({required this.vans, required this.children});

  final List<PlanningVan> vans;
  final List<PlanningChild> children;

  factory RoutePlanningOptions.fromJson(Map<String, dynamic> json) {
    return RoutePlanningOptions(
      vans:
          (json['vans'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PlanningVan.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          [
            if (json['vanId'] != null)
              PlanningVan(
                id: (json['vanId'] as num?)?.toInt() ?? 0,
                plate: '',
                model: '',
              ),
          ],
      children:
          (json['children'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PlanningChild.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
    );
  }
}

class PlanningVan {
  const PlanningVan({
    required this.id,
    required this.plate,
    required this.model,
  });

  final int id;
  final String plate;
  final String model;

  factory PlanningVan.fromJson(Map<String, dynamic> json) {
    return PlanningVan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      plate: (json['plate'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
    );
  }
}

class PlanningChild {
  const PlanningChild({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.address,
    this.schoolId,
    this.shiftId,
    this.shiftName,
    this.selectedByDefault = true,
  });

  final int id;
  final String name;
  final String schoolName;
  final String address;
  final int? schoolId;
  final int? shiftId;
  final String? shiftName;

  /// Indica se a criança entra marcada na seleção da rota (planning).
  /// O backend envia `false` apenas para casos excepcionais (ex.: integrais
  /// em manhã_volta); quando o campo não existe na resposta (backend
  /// antigo), o padrão é `true` para manter o comportamento anterior.
  final bool selectedByDefault;

  factory PlanningChild.fromJson(Map<String, dynamic> json) {
    final address = [
      json['street']?.toString(),
      json['number']?.toString(),
    ].where((value) => value != null && value.trim().isNotEmpty).join(', ');

    final selectedRaw = json['selectedByDefault'];

    return PlanningChild(
      id: ((json['id'] ?? json['childId']) as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['childName'] ?? '').toString(),
      schoolName: (json['schoolName'] ?? '').toString(),
      address: (json['address'] ?? address).toString(),
      schoolId: (json['schoolId'] as num?)?.toInt(),
      shiftId: (json['shiftId'] as num?)?.toInt(),
      shiftName: json['shiftName']?.toString(),
      selectedByDefault: selectedRaw is bool ? selectedRaw : true,
    );
  }
}
