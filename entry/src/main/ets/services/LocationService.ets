import { geoLocationManager } from '@kit.LocationKit';

export type LocationFix = geoLocationManager.Location;


export interface LocationPoint {
  latitude: number;
  longitude: number;
}

export class LocationService {
  private watching = false;
  private cb?: (loc: LocationFix) => void;

  isLocationEnabled(): boolean {
    try {
      return geoLocationManager.isLocationEnabled();
    } catch (err) {
      console.error(`isLocationEnabled error: ${JSON.stringify(err)}`);
      return false;
    }
  }


  getLastLocation(): LocationFix | null {
    try {
      return geoLocationManager.getLastLocation();
    } catch (err) {
      console.error(`getLastLocation error: ${JSON.stringify(err)}`);
      return null;
    }
  }


  async getCurrentLocationFast(timeoutMs = 10_000): Promise<LocationFix | null> {
    const req: geoLocationManager.SingleLocationRequest = {
      locatingPriority: geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
      locatingTimeoutMs: timeoutMs
    };
    try {
      return await geoLocationManager.getCurrentLocation(req);
    } catch (e) {
      console.error(`getCurrentLocation error: ${JSON.stringify(e)}`);
      return null;
    }
  }


  startContinuous(onChange: (loc: LocationFix) => void, intervalSec = 1) {
    if (this.watching) {
      return;
    }
    const request: geoLocationManager.ContinuousLocationRequest = {
      interval: intervalSec,
      locationScenario: geoLocationManager.UserActivityScenario.NAVIGATION
    };
    this.cb = (loc: LocationFix) => onChange(loc);
    try {
      geoLocationManager.on('locationChange', request, this.cb);
      // optional: listen errors
      geoLocationManager.on('locationError', (err) => {
        console.error(`locationError: ${JSON.stringify(err)}`);
      });
      this.watching = true;
    } catch (err) {
      console.error(`on(locationChange) error: ${JSON.stringify(err)}`);
    }
  }


  stopContinuous() {
    if (!this.watching) {
      return;
    }
    try {
      if (this.cb) {
        geoLocationManager.off('locationChange', this.cb);
      }
      geoLocationManager.off('locationError');
    } finally {
      this.cb = undefined;
      this.watching = false;
    }
  }


  // Haversine distance function
  distanceMeters(a: LocationPoint, b: LocationPoint): number {
    const R: number = 6371e3; // Earth radius as meters
    const phi1: number = a.latitude * Math.PI / 180;
    const phi2: number = b.latitude * Math.PI / 180;
    const deltaPhi: number = (b.latitude - a.latitude) * Math.PI / 180;
    const deltaLambda: number = (b.longitude - a.longitude) * Math.PI / 180;
    const aCalc: number = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
      Math.cos(phi1) * Math.cos(phi2) *
      Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
    const c: number = 2 * Math.atan2(Math.sqrt(aCalc), Math.sqrt(1 - aCalc));
    return R * c;
  }
}