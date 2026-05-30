import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/driver_tracking_controller.dart';
import '../state/driver_tracking_state.dart';

final driverTrackingControllerProvider =
    NotifierProvider<DriverTrackingController, DriverTrackingState>(
      DriverTrackingController.new,
    );
