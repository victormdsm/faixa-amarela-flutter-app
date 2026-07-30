// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transport_driver.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransportDriver {

 String get id; String get driverName; String get vanName; String get whatsappNumber; List<String> get schools; List<String> get neighborhoods; List<ServicePeriod> get periods; int get availableSeats; double get rating; int get yearsExperience; String? get note;
/// Create a copy of TransportDriver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportDriverCopyWith<TransportDriver> get copyWith => _$TransportDriverCopyWithImpl<TransportDriver>(this as TransportDriver, _$identity);


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportDriver&&(identical(other.id, id) || other.id == id)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.vanName, vanName) || other.vanName == vanName)&&(identical(other.whatsappNumber, whatsappNumber) || other.whatsappNumber == whatsappNumber)&&const DeepCollectionEquality().equals(other.schools, schools)&&const DeepCollectionEquality().equals(other.neighborhoods, neighborhoods)&&const DeepCollectionEquality().equals(other.periods, periods)&&(identical(other.availableSeats, availableSeats) || other.availableSeats == availableSeats)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.yearsExperience, yearsExperience) || other.yearsExperience == yearsExperience)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,driverName,vanName,whatsappNumber,const DeepCollectionEquality().hash(schools),const DeepCollectionEquality().hash(neighborhoods),const DeepCollectionEquality().hash(periods),availableSeats,rating,yearsExperience,note);

@override
String toString() {
  return 'TransportDriver(id: $id, driverName: $driverName, vanName: $vanName, whatsappNumber: $whatsappNumber, schools: $schools, neighborhoods: $neighborhoods, periods: $periods, availableSeats: $availableSeats, rating: $rating, yearsExperience: $yearsExperience, note: $note)';
}


}

/// @nodoc
abstract mixin class $TransportDriverCopyWith<$Res>  {
  factory $TransportDriverCopyWith(TransportDriver value, $Res Function(TransportDriver) _then) = _$TransportDriverCopyWithImpl;
@useResult
$Res call({
 String id, String driverName, String vanName, String whatsappNumber, List<String> schools, List<String> neighborhoods, List<ServicePeriod> periods, int availableSeats, double rating, int yearsExperience, String? note
});




}
/// @nodoc
class _$TransportDriverCopyWithImpl<$Res>
    implements $TransportDriverCopyWith<$Res> {
  _$TransportDriverCopyWithImpl(this._self, this._then);

  final TransportDriver _self;
  final $Res Function(TransportDriver) _then;

/// Create a copy of TransportDriver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? driverName = null,Object? vanName = null,Object? whatsappNumber = null,Object? schools = null,Object? neighborhoods = null,Object? periods = null,Object? availableSeats = null,Object? rating = null,Object? yearsExperience = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,vanName: null == vanName ? _self.vanName : vanName // ignore: cast_nullable_to_non_nullable
as String,whatsappNumber: null == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String,schools: null == schools ? _self.schools : schools // ignore: cast_nullable_to_non_nullable
as List<String>,neighborhoods: null == neighborhoods ? _self.neighborhoods : neighborhoods // ignore: cast_nullable_to_non_nullable
as List<String>,periods: null == periods ? _self.periods : periods // ignore: cast_nullable_to_non_nullable
as List<ServicePeriod>,availableSeats: null == availableSeats ? _self.availableSeats : availableSeats // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,yearsExperience: null == yearsExperience ? _self.yearsExperience : yearsExperience // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransportDriver].
extension TransportDriverPatterns on TransportDriver {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransportDriver value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransportDriver() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransportDriver value)  $default,){
final _that = this;
switch (_that) {
case _TransportDriver():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransportDriver value)?  $default,){
final _that = this;
switch (_that) {
case _TransportDriver() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String driverName,  String vanName,  String whatsappNumber,  List<String> schools,  List<String> neighborhoods,  List<ServicePeriod> periods,  int availableSeats,  double rating,  int yearsExperience,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransportDriver() when $default != null:
return $default(_that.id,_that.driverName,_that.vanName,_that.whatsappNumber,_that.schools,_that.neighborhoods,_that.periods,_that.availableSeats,_that.rating,_that.yearsExperience,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String driverName,  String vanName,  String whatsappNumber,  List<String> schools,  List<String> neighborhoods,  List<ServicePeriod> periods,  int availableSeats,  double rating,  int yearsExperience,  String? note)  $default,) {final _that = this;
switch (_that) {
case _TransportDriver():
return $default(_that.id,_that.driverName,_that.vanName,_that.whatsappNumber,_that.schools,_that.neighborhoods,_that.periods,_that.availableSeats,_that.rating,_that.yearsExperience,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String driverName,  String vanName,  String whatsappNumber,  List<String> schools,  List<String> neighborhoods,  List<ServicePeriod> periods,  int availableSeats,  double rating,  int yearsExperience,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _TransportDriver() when $default != null:
return $default(_that.id,_that.driverName,_that.vanName,_that.whatsappNumber,_that.schools,_that.neighborhoods,_that.periods,_that.availableSeats,_that.rating,_that.yearsExperience,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransportDriver implements TransportDriver {
  const _TransportDriver({required this.id, required this.driverName, required this.vanName, required this.whatsappNumber, required final  List<String> schools, required final  List<String> neighborhoods, required final  List<ServicePeriod> periods, required this.availableSeats, required this.rating, this.yearsExperience = 0, this.note}): _schools = schools,_neighborhoods = neighborhoods,_periods = periods;

@override final  String id;
@override final  String driverName;
@override final  String vanName;
@override final  String whatsappNumber;
 final  List<String> _schools;
@override List<String> get schools {
  if (_schools is EqualUnmodifiableListView) return _schools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_schools);
}

 final  List<String> _neighborhoods;
@override List<String> get neighborhoods {
  if (_neighborhoods is EqualUnmodifiableListView) return _neighborhoods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_neighborhoods);
}

 final  List<ServicePeriod> _periods;
@override List<ServicePeriod> get periods {
  if (_periods is EqualUnmodifiableListView) return _periods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_periods);
}

@override final  int availableSeats;
@override final  double rating;
@override@JsonKey() final  int yearsExperience;
@override final  String? note;

/// Create a copy of TransportDriver
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransportDriverCopyWith<_TransportDriver> get copyWith => __$TransportDriverCopyWithImpl<_TransportDriver>(this, _$identity);

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransportDriver&&(identical(other.id, id) || other.id == id)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.vanName, vanName) || other.vanName == vanName)&&(identical(other.whatsappNumber, whatsappNumber) || other.whatsappNumber == whatsappNumber)&&const DeepCollectionEquality().equals(other._schools, _schools)&&const DeepCollectionEquality().equals(other._neighborhoods, _neighborhoods)&&const DeepCollectionEquality().equals(other._periods, _periods)&&(identical(other.availableSeats, availableSeats) || other.availableSeats == availableSeats)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.yearsExperience, yearsExperience) || other.yearsExperience == yearsExperience)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,driverName,vanName,whatsappNumber,const DeepCollectionEquality().hash(_schools),const DeepCollectionEquality().hash(_neighborhoods),const DeepCollectionEquality().hash(_periods),availableSeats,rating,yearsExperience,note);

@override
String toString() {
  return 'TransportDriver(id: $id, driverName: $driverName, vanName: $vanName, whatsappNumber: $whatsappNumber, schools: $schools, neighborhoods: $neighborhoods, periods: $periods, availableSeats: $availableSeats, rating: $rating, yearsExperience: $yearsExperience, note: $note)';
}


}

/// @nodoc
abstract mixin class _$TransportDriverCopyWith<$Res> implements $TransportDriverCopyWith<$Res> {
  factory _$TransportDriverCopyWith(_TransportDriver value, $Res Function(_TransportDriver) _then) = __$TransportDriverCopyWithImpl;
@override @useResult
$Res call({
 String id, String driverName, String vanName, String whatsappNumber, List<String> schools, List<String> neighborhoods, List<ServicePeriod> periods, int availableSeats, double rating, int yearsExperience, String? note
});




}
/// @nodoc
class __$TransportDriverCopyWithImpl<$Res>
    implements _$TransportDriverCopyWith<$Res> {
  __$TransportDriverCopyWithImpl(this._self, this._then);

  final _TransportDriver _self;
  final $Res Function(_TransportDriver) _then;

/// Create a copy of TransportDriver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? driverName = null,Object? vanName = null,Object? whatsappNumber = null,Object? schools = null,Object? neighborhoods = null,Object? periods = null,Object? availableSeats = null,Object? rating = null,Object? yearsExperience = null,Object? note = freezed,}) {
  return _then(_TransportDriver(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,vanName: null == vanName ? _self.vanName : vanName // ignore: cast_nullable_to_non_nullable
as String,whatsappNumber: null == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String,schools: null == schools ? _self._schools : schools // ignore: cast_nullable_to_non_nullable
as List<String>,neighborhoods: null == neighborhoods ? _self._neighborhoods : neighborhoods // ignore: cast_nullable_to_non_nullable
as List<String>,periods: null == periods ? _self._periods : periods // ignore: cast_nullable_to_non_nullable
as List<ServicePeriod>,availableSeats: null == availableSeats ? _self.availableSeats : availableSeats // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,yearsExperience: null == yearsExperience ? _self.yearsExperience : yearsExperience // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
