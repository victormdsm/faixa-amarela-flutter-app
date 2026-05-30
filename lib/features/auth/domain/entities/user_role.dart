enum UserRole { parent, driver }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.parent => 'Pais',
    UserRole.driver => 'Tio da Van',
  };

  String get subtitle => switch (this) {
    UserRole.parent => 'Acompanhar filhos, enderecos e localizacao da van',
    UserRole.driver => 'Gerenciar clientes, rotas e mensagens via WhatsApp',
  };
}
