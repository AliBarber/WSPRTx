struct LatLon
{
  float lat, lon;

  LatLon(float _lat, float _lon) : lat(_lat), lon(_lon){
  }

};


struct MaidenheadLocator{
  // Numbers corresponding to pair number
  char lon_1, lon_3;
  char lat_1, lat_3;

  int lon_2, lon_4;
  int lat_2, lat_4;
  const LatLon maidenhead_lat_lon;

  MaidenheadLocator(LatLon const _lat_lon) : maidenhead_lat_lon(LatLon(_lat_lon.lat + 90, _lat_lon.lon + 180)){
    lon_1 = 'A';
    lat_1 = 'A';
    lon_2 = 0;
    lat_2 = 0;
    lon_3 = 'a';
    lat_3 = 'a';

    int diff;
    float remainder_lat, remainder_lon;

    diff = ((int) maidenhead_lat_lon.lon) / 20;
    remainder_lon = maidenhead_lat_lon.lon - (diff * 20);
    lon_1 += diff;
    diff = ((int) maidenhead_lat_lon.lat) / 10;
    remainder_lat = maidenhead_lat_lon.lat - (diff * 10);
    lat_1 += diff;

    lon_2 = ((int) remainder_lon) / 2;
    remainder_lon -= lon_2 * 2;
    lat_2 = ((int) remainder_lat);
    remainder_lat -= lat_2;

    // Convert our remainders to minutes
    remainder_lon = remainder_lon * 60;
    remainder_lat = remainder_lat * 60;

    diff = (int) remainder_lon / 5;
    remainder_lon -= diff * 5;
    lon_3 += diff;

    diff = (int) remainder_lat / 2.5;
    remainder_lat -= diff * 2.5;
    lat_3 += diff;
  }

  int to_char(char* buffer) const{
    buffer[0] = lon_1;
    buffer[1] = lat_1;
    buffer[2] = (char) lon_2 + 48;
    buffer[3] = (char) lat_2 + 48;
    buffer[4] = lon_3;
    buffer[5] = lat_3;

    return 6;
  }

};