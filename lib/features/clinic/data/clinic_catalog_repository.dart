import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic_equipment_model.dart';
import '../models/clinic_facility_model.dart';
import '../models/clinic_medicine_model.dart';
import '../models/clinic_operating_hours_model.dart';
import '../models/clinic_service_model.dart';

abstract class ClinicCatalogRepository {
  // Services
  Future<List<ClinicServiceModel>> fetchServices(String clinicId);
  Future<ClinicServiceModel> saveService(ClinicServiceModel service);
  Future<void> deleteService(String id);
  Future<void> toggleServiceCategories(String clinicId, List<String> activeCategories);

  // Facilities
  Future<List<ClinicFacilityModel>> fetchFacilities(String clinicId);
  Future<ClinicFacilityModel> saveFacility(ClinicFacilityModel facility);
  Future<void> deleteFacility(String id);

  // Equipment
  Future<List<ClinicEquipmentModel>> fetchEquipment(String clinicId);
  Future<ClinicEquipmentModel> saveEquipment(ClinicEquipmentModel equipment);
  Future<void> deleteEquipment(String id);

  // Medicines
  Future<List<ClinicMedicineModel>> fetchMedicines(String clinicId);
  Future<ClinicMedicineModel> saveMedicine(ClinicMedicineModel medicine);
  Future<void> deleteMedicine(String id);
  Future<void> importMedicinesFromCsv(String clinicId, String csvContent);

  // Operating Hours
  Future<List<ClinicOperatingHoursModel>> fetchOperatingHours(String clinicId);
  Future<void> updateOperatingHours(List<ClinicOperatingHoursModel> hours);
  Future<void> copyHoursToWeekdays(String clinicId, ClinicOperatingHoursModel source);
}

class SupabaseClinicCatalogRepository implements ClinicCatalogRepository {
  SupabaseClinicCatalogRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<ClinicServiceModel>> fetchServices(String clinicId) async {
    final res = await _client
        .from('clinic_services')
        .select()
        .eq('clinic_id', clinicId)
        .order('service_type', ascending: true);
    return (res as List)
        .map((e) => ClinicServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClinicServiceModel> saveService(ClinicServiceModel service) async {
    final Map<String, dynamic> payload = service.toJson();
    if (service.id.isEmpty) payload.remove('id');
    final res = await _client
        .from('clinic_services')
        .upsert(payload, onConflict: 'clinic_id, service_type')
        .select()
        .single();
    return ClinicServiceModel.fromJson(res);
  }

  @override
  Future<void> deleteService(String id) async {
    await _client.from('clinic_services').delete().eq('id', id);
  }

  @override
  Future<void> toggleServiceCategories(
      String clinicId, List<String> activeCategories) async {
    final existing = await fetchServices(clinicId);
    final existingMap = {for (var s in existing) s.serviceType: s};

    for (final cat in activeCategories) {
      if (!existingMap.containsKey(cat)) {
        await saveService(
          ClinicServiceModel(id: '', clinicId: clinicId, serviceType: cat, isActive: true),
        );
      } else if (!existingMap[cat]!.isActive) {
        await saveService(existingMap[cat]!.copyWith(isActive: true));
      }
    }

    for (final s in existing) {
      if (!activeCategories.contains(s.serviceType) && s.isActive) {
        await saveService(s.copyWith(isActive: false));
      }
    }
  }

  @override
  Future<List<ClinicFacilityModel>> fetchFacilities(String clinicId) async {
    final res = await _client
        .from('clinic_facilities')
        .select()
        .eq('clinic_id', clinicId)
        .order('name', ascending: true);
    return (res as List)
        .map((e) => ClinicFacilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClinicFacilityModel> saveFacility(ClinicFacilityModel facility) async {
    final Map<String, dynamic> payload = facility.toJson();
    if (facility.id.isEmpty) payload.remove('id');
    final res = await _client
        .from('clinic_facilities')
        .upsert(payload)
        .select()
        .single();
    return ClinicFacilityModel.fromJson(res);
  }

  @override
  Future<void> deleteFacility(String id) async {
    await _client.from('clinic_facilities').delete().eq('id', id);
  }

  @override
  Future<List<ClinicEquipmentModel>> fetchEquipment(String clinicId) async {
    final res = await _client
        .from('clinic_equipment')
        .select()
        .eq('clinic_id', clinicId)
        .order('name', ascending: true);
    return (res as List)
        .map((e) => ClinicEquipmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClinicEquipmentModel> saveEquipment(
      ClinicEquipmentModel equipment) async {
    final Map<String, dynamic> payload = equipment.toJson();
    if (equipment.id.isEmpty) payload.remove('id');
    final res = await _client
        .from('clinic_equipment')
        .upsert(payload)
        .select()
        .single();
    return ClinicEquipmentModel.fromJson(res);
  }

  @override
  Future<void> deleteEquipment(String id) async {
    await _client.from('clinic_equipment').delete().eq('id', id);
  }

  @override
  Future<List<ClinicMedicineModel>> fetchMedicines(String clinicId) async {
    final res = await _client
        .from('clinic_medicines')
        .select()
        .eq('clinic_id', clinicId)
        .order('name', ascending: true);
    return (res as List)
        .map((e) => ClinicMedicineModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClinicMedicineModel> saveMedicine(ClinicMedicineModel medicine) async {
    final Map<String, dynamic> payload = medicine.toJson();
    if (medicine.id.isEmpty) payload.remove('id');
    final res = await _client
        .from('clinic_medicines')
        .upsert(payload)
        .select()
        .single();
    return ClinicMedicineModel.fromJson(res);
  }

  @override
  Future<void> deleteMedicine(String id) async {
    await _client.from('clinic_medicines').delete().eq('id', id);
  }

  @override
  Future<void> importMedicinesFromCsv(
      String clinicId, String csvContent) async {
    final lines = csvContent.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase().startsWith('nama')) continue;
      final parts = trimmed.split(',');
      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
        final name = parts[0].trim();
        final form = parts.length > 1 ? parts[1].trim() : null;
        final strength = parts.length > 2 ? parts[2].trim() : null;

        await saveMedicine(
          ClinicMedicineModel(
            id: '',
            clinicId: clinicId,
            name: name,
            dosageForm: form,
            strength: strength,
            isAvailable: true,
          ),
        );
      }
    }
  }

  @override
  Future<List<ClinicOperatingHoursModel>> fetchOperatingHours(
      String clinicId) async {
    final res = await _client
        .from('clinic_operating_hours')
        .select()
        .eq('clinic_id', clinicId)
        .order('day_of_week', ascending: true);
    return (res as List)
        .map((e) => ClinicOperatingHoursModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateOperatingHours(
      List<ClinicOperatingHoursModel> hours) async {
    for (final item in hours) {
      await _client
          .from('clinic_operating_hours')
          .update(item.toJson())
          .eq('id', item.id);
    }
  }

  @override
  Future<void> copyHoursToWeekdays(
      String clinicId, ClinicOperatingHoursModel source) async {
    final all = await fetchOperatingHours(clinicId);
    for (final item in all) {
      if (item.dayOfWeek >= 1 && item.dayOfWeek <= 5) {
        final updated = item.copyWith(
          isOpen: source.isOpen,
          openTime: source.openTime,
          closeTime: source.closeTime,
          breakStart: source.breakStart,
          breakEnd: source.breakEnd,
        );
        await _client
            .from('clinic_operating_hours')
            .update(updated.toJson())
            .eq('id', item.id);
      }
    }
  }
}

class FakeClinicCatalogRepository implements ClinicCatalogRepository {
  List<ClinicServiceModel> services = [];
  List<ClinicFacilityModel> facilities = [];
  List<ClinicEquipmentModel> equipment = [];
  List<ClinicMedicineModel> medicines = [];
  List<ClinicOperatingHoursModel> operatingHours = List.generate(
    7,
    (index) => ClinicOperatingHoursModel(
      id: 'h${index + 1}',
      clinicId: 'c1',
      dayOfWeek: index + 1,
      isOpen: index < 5,
    ),
  );

  @override
  Future<List<ClinicServiceModel>> fetchServices(String clinicId) async =>
      services;

  @override
  Future<ClinicServiceModel> saveService(ClinicServiceModel service) async {
    services.removeWhere((s) => s.serviceType == service.serviceType);
    services.add(service);
    return service;
  }

  @override
  Future<void> deleteService(String id) async {
    services.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> toggleServiceCategories(
      String clinicId, List<String> activeCategories) async {
    services = activeCategories
        .map((cat) => ClinicServiceModel(id: cat, clinicId: clinicId, serviceType: cat, isActive: true))
        .toList();
  }

  @override
  Future<List<ClinicFacilityModel>> fetchFacilities(String clinicId) async =>
      facilities;

  @override
  Future<ClinicFacilityModel> saveFacility(ClinicFacilityModel facility) async {
    facilities.removeWhere((f) => f.id == facility.id && facility.id.isNotEmpty);
    facilities.add(facility);
    return facility;
  }

  @override
  Future<void> deleteFacility(String id) async {
    facilities.removeWhere((f) => f.id == id);
  }

  @override
  Future<List<ClinicEquipmentModel>> fetchEquipment(String clinicId) async =>
      equipment;

  @override
  Future<ClinicEquipmentModel> saveEquipment(
      ClinicEquipmentModel equipmentItem) async {
    equipment.removeWhere((e) => e.id == equipmentItem.id && equipmentItem.id.isNotEmpty);
    equipment.add(equipmentItem);
    return equipmentItem;
  }

  @override
  Future<void> deleteEquipment(String id) async {
    equipment.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<ClinicMedicineModel>> fetchMedicines(String clinicId) async =>
      medicines;

  @override
  Future<ClinicMedicineModel> saveMedicine(ClinicMedicineModel medicine) async {
    medicines.removeWhere((m) => m.id == medicine.id && medicine.id.isNotEmpty);
    medicines.add(medicine);
    return medicine;
  }

  @override
  Future<void> deleteMedicine(String id) async {
    medicines.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> importMedicinesFromCsv(
      String clinicId, String csvContent) async {}

  @override
  Future<List<ClinicOperatingHoursModel>> fetchOperatingHours(
          String clinicId) async =>
      operatingHours;

  @override
  Future<void> updateOperatingHours(
      List<ClinicOperatingHoursModel> hours) async {
    operatingHours = List.of(hours);
  }

  @override
  Future<void> copyHoursToWeekdays(
      String clinicId, ClinicOperatingHoursModel source) async {
    operatingHours = operatingHours.map((h) {
      if (h.dayOfWeek >= 1 && h.dayOfWeek <= 5) {
        return h.copyWith(
          isOpen: source.isOpen,
          openTime: source.openTime,
          closeTime: source.closeTime,
          breakStart: source.breakStart,
          breakEnd: source.breakEnd,
        );
      }
      return h;
    }).toList();
  }
}
