// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'finalize_registration_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FinalizeRegistrationState {

 String get login; bool get isLoading; String? get errorMessage; String? get successMessage;
/// Create a copy of FinalizeRegistrationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinalizeRegistrationStateCopyWith<FinalizeRegistrationState> get copyWith => _$FinalizeRegistrationStateCopyWithImpl<FinalizeRegistrationState>(this as FinalizeRegistrationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinalizeRegistrationState&&(identical(other.login, login) || other.login == login)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage));
}


@override
int get hashCode => Object.hash(runtimeType,login,isLoading,errorMessage,successMessage);

@override
String toString() {
  return 'FinalizeRegistrationState(login: $login, isLoading: $isLoading, errorMessage: $errorMessage, successMessage: $successMessage)';
}


}

/// @nodoc
abstract mixin class $FinalizeRegistrationStateCopyWith<$Res>  {
  factory $FinalizeRegistrationStateCopyWith(FinalizeRegistrationState value, $Res Function(FinalizeRegistrationState) _then) = _$FinalizeRegistrationStateCopyWithImpl;
@useResult
$Res call({
 String login, bool isLoading, String? errorMessage, String? successMessage
});




}
/// @nodoc
class _$FinalizeRegistrationStateCopyWithImpl<$Res>
    implements $FinalizeRegistrationStateCopyWith<$Res> {
  _$FinalizeRegistrationStateCopyWithImpl(this._self, this._then);

  final FinalizeRegistrationState _self;
  final $Res Function(FinalizeRegistrationState) _then;

/// Create a copy of FinalizeRegistrationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? login = null,Object? isLoading = null,Object? errorMessage = freezed,Object? successMessage = freezed,}) {
  return _then(_self.copyWith(
login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,successMessage: freezed == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FinalizeRegistrationState].
extension FinalizeRegistrationStatePatterns on FinalizeRegistrationState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinalizeRegistrationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinalizeRegistrationState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinalizeRegistrationState value)  $default,){
final _that = this;
switch (_that) {
case _FinalizeRegistrationState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinalizeRegistrationState value)?  $default,){
final _that = this;
switch (_that) {
case _FinalizeRegistrationState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String login,  bool isLoading,  String? errorMessage,  String? successMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinalizeRegistrationState() when $default != null:
return $default(_that.login,_that.isLoading,_that.errorMessage,_that.successMessage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String login,  bool isLoading,  String? errorMessage,  String? successMessage)  $default,) {final _that = this;
switch (_that) {
case _FinalizeRegistrationState():
return $default(_that.login,_that.isLoading,_that.errorMessage,_that.successMessage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String login,  bool isLoading,  String? errorMessage,  String? successMessage)?  $default,) {final _that = this;
switch (_that) {
case _FinalizeRegistrationState() when $default != null:
return $default(_that.login,_that.isLoading,_that.errorMessage,_that.successMessage);case _:
  return null;

}
}

}

/// @nodoc


class _FinalizeRegistrationState extends FinalizeRegistrationState {
  const _FinalizeRegistrationState({required this.login, required this.isLoading, this.errorMessage, this.successMessage}): super._();
  

@override final  String login;
@override final  bool isLoading;
@override final  String? errorMessage;
@override final  String? successMessage;

/// Create a copy of FinalizeRegistrationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinalizeRegistrationStateCopyWith<_FinalizeRegistrationState> get copyWith => __$FinalizeRegistrationStateCopyWithImpl<_FinalizeRegistrationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinalizeRegistrationState&&(identical(other.login, login) || other.login == login)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage));
}


@override
int get hashCode => Object.hash(runtimeType,login,isLoading,errorMessage,successMessage);

@override
String toString() {
  return 'FinalizeRegistrationState(login: $login, isLoading: $isLoading, errorMessage: $errorMessage, successMessage: $successMessage)';
}


}

/// @nodoc
abstract mixin class _$FinalizeRegistrationStateCopyWith<$Res> implements $FinalizeRegistrationStateCopyWith<$Res> {
  factory _$FinalizeRegistrationStateCopyWith(_FinalizeRegistrationState value, $Res Function(_FinalizeRegistrationState) _then) = __$FinalizeRegistrationStateCopyWithImpl;
@override @useResult
$Res call({
 String login, bool isLoading, String? errorMessage, String? successMessage
});




}
/// @nodoc
class __$FinalizeRegistrationStateCopyWithImpl<$Res>
    implements _$FinalizeRegistrationStateCopyWith<$Res> {
  __$FinalizeRegistrationStateCopyWithImpl(this._self, this._then);

  final _FinalizeRegistrationState _self;
  final $Res Function(_FinalizeRegistrationState) _then;

/// Create a copy of FinalizeRegistrationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? login = null,Object? isLoading = null,Object? errorMessage = freezed,Object? successMessage = freezed,}) {
  return _then(_FinalizeRegistrationState(
login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,successMessage: freezed == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
