import 'mock_data.dart';
import 'models.dart';

/// The only thing the UI knows about data sources.
///
/// To connect a real backend (Supabase, REST, Firebase ...) create a class
/// that `implements ClinicRepository`, return a [ClinicData], and pass it to
/// `AppController` in `main.dart`.
abstract class ClinicRepository {
  Future<ClinicData> load();
}

class MockClinicRepository implements ClinicRepository {
  const MockClinicRepository();

  @override
  Future<ClinicData> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockData.snapshot();
  }
}
