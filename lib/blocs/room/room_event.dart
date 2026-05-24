class RoomFetched {}

class LightToggled {
  final String lightKey;

  const LightToggled(this.lightKey);
}

class CurtainChanged {
  final int value;

  const CurtainChanged(this.value);
}

class ACTemperatureChanged {
  final int temp;

  const ACTemperatureChanged(this.temp);
}

class ACModeToggled {}
