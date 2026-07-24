import 'package:flutter/material.dart';

/// Keys usadas pelos testes E2E (integration_test).
/// Nao remover ou renomear sem atualizar os testes.
abstract final class E2EKeys {
  // Auth
  static const emailInput = Key('email_input');
  static const passwordInput = Key('password_input');
  static const loginButton = Key('login_button');

  // Parent
  static const parentHome = Key('parent_home');
  static const parentChildrenAction = Key('parent_children_action');
  static const childCreateButton = Key('child_create_button');
  static const childNameInput = Key('child_name_input');
  static const childCpfInput = Key('child_cpf_input');
  static const childSchoolDropdown = Key('child_school_dropdown');
  static const childShiftDropdown = Key('child_shift_dropdown');
  static const childSaveButton = Key('child_save_button');
  static const addressStreetInput = Key('address_street_input');
  static const addressNumberInput = Key('address_number_input');
  static const addressComplementInput = Key('address_complement_input');
  static const addressZipCodeInput = Key('address_zip_code_input');
  static const parentEnrollmentsTab = Key('parent_enrollments_tab');
  static const enrollmentAcceptButton = Key('enrollment_accept_button');

  // Driver
  static const driverHome = Key('driver_home');
  static const driverLookupButton = Key('driver_lookup_button');
  static const driverCpfInput = Key('driver_cpf_input');
  static const driverSearchChildButton = Key('driver_search_child_button');
  static const driverRequestEnrollmentButton = Key(
    'driver_request_enrollment_button',
  );
  static const driverLogoutButton = Key('driver_logout_button');
}
