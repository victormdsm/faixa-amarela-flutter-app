/// Sealed-like failure types for the app.
sealed class AppFailure {
  const AppFailure({this.message = 'Ocorreu um erro inesperado.'});

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

class AuthFailure extends AppFailure {
  const AuthFailure({super.message = 'Falha de autenticação.'});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({super.message = 'Sem conexão com a internet.'});
}

class ServerFailure extends AppFailure {
  const ServerFailure({
    super.message = 'Erro no servidor. Tente novamente mais tarde.',
  });
}

class TimeoutFailure extends AppFailure {
  const TimeoutFailure({super.message = 'A conexão expirou. Tente novamente.'});
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({
    super.message = 'Dados inválidos. Verifique e tente novamente.',
  });
}

class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({super.message = 'Acesso não permitido.'});
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.message = 'Recurso não encontrado.'});
}

class CacheFailure extends AppFailure {
  const CacheFailure({super.message = 'Erro ao acessar dados locais.'});
}
