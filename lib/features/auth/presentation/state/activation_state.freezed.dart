// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActivationState {

 String get emailOrCpf; String get code; bool get isLoading; String? get errorMessage; bool? get success;
/// Create a copy of ActivationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivationStateCopyWith<ActivationState> get copyWith => _$ActivationStateCopyWithImpl<ActivationState>(this as ActivationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivationState&&(identical(other.emailOrCpf, emailOrCpf) || other.emailOrCpf == emailOrCpf)&&(identical(other.code, code) || other.code == code)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.success, success) || other.success == success));
}


@override
int get hashCode => Object.hash(runtimeType,emailOrCpf,code,isLoading,errorMessage,success);

@override
String toString() {
  return 'ActivationState(emailOrCpf: $emailOrCpf, code: $code, isLoading: $isLoading, errorMessage: $errorMessage, success: $success)';
}


}

/// @nodoc
abstract mixin class $ActivationStateCopyWith<$Res>  {
  factory $ActivationStateCopyWith(ActivationState value, $Res Function(ActivationState) _then) = _$ActivationStateCopyWithImpl;
@useResult
$Res call({
 String emailOrCpf, String code, bool isLoading, String? errorMessage, bool? success
});




}
/// @nodoc
class _$ActivationStateCopyWithImpl<$Res>
    implements $ActivationStateCopyWith<$Res> {
  _$ActivationStateCopyWithImpl(this._self, this._then);

  final ActivationState _self;
  final $Res Function(ActivationState) _then;

/// Create a copy of ActivationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? emailOrCpf = null,Object? code = null,Object? isLoading = null,Object? errorMessage = freezed,Object? success = freezed,}) {
  return _then(_self.copyWith(
emailOrCpf: null == emailOrCpf ? _self.emailOrCpf : emailOrCpf // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,success: freezed == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivationState].
extension ActivationStatePatterns on ActivationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivationState value)  $default,){
final _that = this;
switch (_that) {
case _ActivationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivationState value)?  $default,){
final _that = this;
switch (_that) {
case _ActivationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String emailOrCpf,  String code,  bool isLoading,  String? errorMessage,  bool? success)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivationState() when $default != null:
return $default(_that.emailOrCpf,_that.code,_that.isLoading,_that.errorMessage,_that.success);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String emailOrCpf,  String code,  bool isLoading,  String? errorMessage,  bool? success)  $default,) {final _that = this;
switch (_that) {
case _ActivationState():
return $default(_that.emailOrCpf,_that.code,_that.isLoading,_that.errorMessage,_that.success);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String emailOrCpf,  String code,  bool isLoading,  String? errorMessage,  bool? success)?  $default,) {final _that = this;
switch (_that) {
case _ActivationState() when $default != null:
return $default(_that.emailOrCpf,_that.code,_that.isLoading,_that.errorMessage,_that.success);case _:
  return null;

}
}

}

/// @nodoc


class _ActivationState extends ActivationState {
  const _ActivationState({required this.emailOrCpf, required this.code, required this.isLoading, this.errorMessage, this.success}): super._();
  

@override final  String emailOrCpf;
@override final  String code;
@override final  bool isLoading;
@override final  String? errorMessage;
@override final  bool? success;

/// Create a copy of ActivationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivationStateCopyWith<_ActivationState> get copyWith => __$ActivationStateCopyWithImpl<_ActivationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivationState&&(identical(other.emailOrCpf, emailOrCpf) || other.emailOrCpf == emailOrCpf)&&(identical(other.code, code) || other.code == code)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.success, success) || other.success == success));
}


@override
int get hashCode => Object.hash(runtimeType,emailOrCpf,code,isLoading,errorMessage,success);

@override
String toString() {
  return 'ActivationState(emailOrCpf: $emailOrCpf, code: $code, isLoading: $isLoading, errorMessage: $errorMessage, success: $success)';
}


}

/// @nodoc
abstract mixin class _$ActivationStateCopyWith<$Res> implements $ActivationStateCopyWith<$Res> {
  factory _$ActivationStateCopyWith(_ActivationState value, $Res Function(_ActivationState) _then) = __$ActivationStateCopyWithImpl;
@override @useResult
$Res call({
 String emailOrCpf, String code, bool isLoading, String? errorMessage, bool? success
});




}
/// @nodoc
class __$ActivationStateCopyWithImpl<$Res>
    implements _$ActivationStateCopyWith<$Res> {
  __$ActivationStateCopyWithImpl(this._self, this._then);

  final _ActivationState _self;
  final $Res Function(_ActivationState) _then;

/// Create a copy of ActivationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? emailOrCpf = null,Object? code = null,Object? isLoading = null,Object? errorMessage = freezed,Object? success = freezed,}) {
  return _then(_ActivationState(
emailOrCpf: null == emailOrCpf ? _self.emailOrCpf : emailOrCpf // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,success: freezed == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
