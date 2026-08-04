import 'package:app_faixa_amarela/features/parent_portal/data/nestjs_enrollments_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late NestjsEnrollmentsRepository repository;

  setUp(() {
    dio = MockDio();
    repository = NestjsEnrollmentsRepository(dio);
  });

}
