class ReverseGC {
  final String si, gu, dong, buildingName, road;

  ReverseGC.fromJson(Map<String, dynamic> gc)
      : si = gc["results"][0]['region']['area1']['name'],
        gu = gc["results"][0]['region']['area2']['name'],
        dong = gc["results"][0]['region']['area3']['name'],
        buildingName = gc["results"][0]['land']['addition0']['value'],
        road = gc["results"][0]['land']['name'];
}
