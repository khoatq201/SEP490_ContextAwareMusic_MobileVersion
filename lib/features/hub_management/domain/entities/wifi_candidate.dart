import 'package:equatable/equatable.dart';

class WifiCandidate extends Equatable {
  const WifiCandidate({required this.ssid});

  final String ssid;

  @override
  List<Object?> get props => [ssid];
}
