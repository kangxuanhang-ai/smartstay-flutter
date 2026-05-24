class RoomState {
  final String roomNumber;
  final String roomType;
  final double basePrice;
  final double currentPrice;
  final String roomStatus;

  final bool livingLight;
  final bool bedroomLight;
  final bool bedsideLight;
  final int curtain;
  final int acTemp;
  final bool acCool; // true = cool, false = heat

  final bool loading;

  const RoomState({
    this.roomNumber = '',
    this.roomType = '',
    this.basePrice = 0,
    this.currentPrice = 0,
    this.roomStatus = '',
    this.livingLight = false,
    this.bedroomLight = false,
    this.bedsideLight = false,
    this.curtain = 50,
    this.acTemp = 24,
    this.acCool = true,
    this.loading = false,
  });

  RoomState copyWith({
    String? roomNumber,
    String? roomType,
    double? basePrice,
    double? currentPrice,
    String? roomStatus,
    bool? livingLight,
    bool? bedroomLight,
    bool? bedsideLight,
    int? curtain,
    int? acTemp,
    bool? acCool,
    bool? loading,
  }) {
    return RoomState(
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      basePrice: basePrice ?? this.basePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      roomStatus: roomStatus ?? this.roomStatus,
      livingLight: livingLight ?? this.livingLight,
      bedroomLight: bedroomLight ?? this.bedroomLight,
      bedsideLight: bedsideLight ?? this.bedsideLight,
      curtain: curtain ?? this.curtain,
      acTemp: acTemp ?? this.acTemp,
      acCool: acCool ?? this.acCool,
      loading: loading ?? this.loading,
    );
  }
}
