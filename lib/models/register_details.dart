class StateOption {
  const StateOption({required this.id, required this.name});

  final int id;
  final String name;

  factory StateOption.fromJson(Map<String, dynamic> json) => StateOption(
    id: json['id'] as int,
    name: json['state_name'] as String,
  );
}

class CityOption {
  const CityOption({required this.id, required this.name, required this.stateId});

  final int id;
  final String name;
  final int stateId;

  factory CityOption.fromJson(Map<String, dynamic> json) => CityOption(
    id: json['id'] as int,
    name: json['city_name'] as String,
    stateId: json['state_id'] as int,
  );
}

class RegisterDetails {
  const RegisterDetails({required this.states, required this.cities});

  final List<StateOption> states;
  final List<CityOption> cities;

  factory RegisterDetails.fromJson(Map<String, dynamic> json) => RegisterDetails(
    states: (json['states'] as List<dynamic>? ?? [])
        .map((e) => StateOption.fromJson(e as Map<String, dynamic>))
        .toList(),
    cities: (json['cities'] as List<dynamic>? ?? [])
        .map((e) => CityOption.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  List<CityOption> citiesForState(int stateId) =>
      cities.where((c) => c.stateId == stateId).toList();
}
