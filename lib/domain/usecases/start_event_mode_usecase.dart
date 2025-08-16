import 'package:isiza_pay/domain/repositories/event_mode_repository.dart';

class StartEventModeUseCase {
  final EventModeRepository _repository;

  StartEventModeUseCase(this._repository);

  Future<void> execute({
    required String vendorId,
    required String vendorName,
    required String description,
  }) async {
    // Validate inputs
    if (vendorId.isEmpty) {
      throw ArgumentError('Vendor ID cannot be empty');
    }
    if (vendorName.isEmpty) {
      throw ArgumentError('Vendor name cannot be empty');
    }

    // Check if event mode is already active
    final isActive = await _repository.isEventModeActive(vendorId);
    if (isActive) {
      throw StateError('Event mode is already active for this vendor');
    }

    // Start event mode
    await _repository.startEventMode(vendorId, vendorName, description);
  }
}
