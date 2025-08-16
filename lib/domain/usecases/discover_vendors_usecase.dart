import 'package:isiza_pay/domain/entities/vendor_info.dart';
import 'package:isiza_pay/domain/repositories/event_mode_repository.dart';

class DiscoverVendorsUseCase {
  final EventModeRepository _repository;

  DiscoverVendorsUseCase(this._repository);

  Future<List<VendorInfoEntity>> execute() async {
    try {
      final vendors = await _repository.discoverNearbyVendors();
      
      // Filter only active vendors
      return vendors.where((vendor) => vendor.isEventModeActive).toList();
    } catch (e) {
      // Return empty list on error, could be logged for debugging
      return [];
    }
  }

  Future<VendorInfoEntity?> getVendorDetails(String vendorId) async {
    try {
      return await _repository.getVendorInfo(vendorId);
    } catch (e) {
      return null;
    }
  }
}
