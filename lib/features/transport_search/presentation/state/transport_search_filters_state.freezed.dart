// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transport_search_filters_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransportSearchFiltersState {

 String? get school; String? get neighborhood; ServicePeriod? get period;
/// Create a copy of TransportSearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportSearchFiltersStateCopyWith<TransportSearchFiltersState> get copyWith => _$TransportSearchFiltersStateCopyWithImpl<TransportSearchFiltersState>(this as TransportSearchFiltersState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportSearchFiltersState&&(identical(other.school, school) || other.school == school)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.period, period) || other.period == period));
}


@override
int get hashCode => Object.hash(runtimeType,school,neighborhood,period);

@override
String toString() {
  return 'TransportSearchFiltersState(school: $school, neighborhood: $neighborhood, period: $period)';
}


}

/// @nodoc
abstract mixin class $TransportSearchFiltersStateCopyWith<$Res>  {
  factory $TransportSearchFiltersStateCopyWith(TransportSearchFiltersState value, $Res Function(TransportSearchFiltersState) _then) = _$TransportSearchFiltersStateCopyWithImpl;
@useResult
$Res call({
 String? school, String? neighborhood, ServicePeriod? period
});




}
/// @nodoc
class _$TransportSearchFiltersStateCopyWithImpl<$Res>
    implements $TransportSearchFiltersStateCopyWith<$Res> {
  _$TransportSearchFiltersStateCopyWithImpl(this._self, this._then);

  final TransportSearchFiltersState _self;
  final $Res Function(TransportSearchFiltersState) _then;

/// Create a copy of TransportSearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? school = freezed,Object? neighborhood = freezed,Object? period = freezed,}) {
  return _then(_self.copyWith(
school: freezed == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as ServicePeriod?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransportSearchFiltersState].
extension TransportSearchFiltersStatePatterns on TransportSearchFiltersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransportSearchFiltersState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransportSearchFiltersState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransportSearchFiltersState value)  $default,){
final _that = this;
switch (_that) {
case _TransportSearchFiltersState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransportSearchFiltersState value)?  $default,){
final _that = this;
switch (_that) {
case _TransportSearchFiltersState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? school,  String? neighborhood,  ServicePeriod? period)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransportSearchFiltersState() when $default != null:
return $default(_that.school,_that.neighborhood,_that.period);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? school,  String? neighborhood,  ServicePeriod? period)  $default,) {final _that = this;
switch (_that) {
case _TransportSearchFiltersState():
return $default(_that.school,_that.neighborhood,_that.period);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? school,  String? neighborhood,  ServicePeriod? period)?  $default,) {final _that = this;
switch (_that) {
case _TransportSearchFiltersState() when $default != null:
return $default(_that.school,_that.neighborhood,_that.period);case _:
  return null;

}
}

}

/// @nodoc


class _TransportSearchFiltersState extends TransportSearchFiltersState {
  const _TransportSearchFiltersState({this.school, this.neighborhood, this.period}): super._();
  

@override final  String? school;
@override final  String? neighborhood;
@override final  ServicePeriod? period;

/// Create a copy of TransportSearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransportSearchFiltersStateCopyWith<_TransportSearchFiltersState> get copyWith => __$TransportSearchFiltersStateCopyWithImpl<_TransportSearchFiltersState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransportSearchFiltersState&&(identical(other.school, school) || other.school == school)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.period, period) || other.period == period));
}


@override
int get hashCode => Object.hash(runtimeType,school,neighborhood,period);

@override
String toString() {
  return 'TransportSearchFiltersState(school: $school, neighborhood: $neighborhood, period: $period)';
}


}

/// @nodoc
abstract mixin class _$TransportSearchFiltersStateCopyWith<$Res> implements $TransportSearchFiltersStateCopyWith<$Res> {
  factory _$TransportSearchFiltersStateCopyWith(_TransportSearchFiltersState value, $Res Function(_TransportSearchFiltersState) _then) = __$TransportSearchFiltersStateCopyWithImpl;
@override @useResult
$Res call({
 String? school, String? neighborhood, ServicePeriod? period
});




}
/// @nodoc
class __$TransportSearchFiltersStateCopyWithImpl<$Res>
    implements _$TransportSearchFiltersStateCopyWith<$Res> {
  __$TransportSearchFiltersStateCopyWithImpl(this._self, this._then);

  final _TransportSearchFiltersState _self;
  final $Res Function(_TransportSearchFiltersState) _then;

/// Create a copy of TransportSearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? school = freezed,Object? neighborhood = freezed,Object? period = freezed,}) {
  return _then(_TransportSearchFiltersState(
school: freezed == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as ServicePeriod?,
  ));
}


}

// dart format on
