import { LocationPoint, LocationService } from '../services/LocationService';
import { AttendanceRecord } from '../models/AttendanceRecord';
import { PromptAction, uiObserver } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { vibrator } from '@kit.SensorServiceKit';
import { BaseViewModel } from '../viewmodel/BaseViewModel';

@Builder
export function AttendanceDetailPageBuilder() {
  AttendanceDetailPage()
}

@Entry({ routeName: 'AttendanceDetailPage' })
@Component
export struct AttendanceDetailPage {
  @State currentRecord: AttendanceRecord = new AttendanceRecord();
  @State currentTime: string = '--:--:--';
  @State isInRange: boolean = false;
  @State distance: number = 0;
  @State message: string = 'Checking for location';
  baseVm: BaseViewModel = new BaseViewModel();
  navDesInfo: uiObserver.NavDestinationInfo | undefined
   item: AttendanceRecord = new AttendanceRecord();
  promptAction: PromptAction = this.getUIContext().getPromptAction();
  // Example coordinate
  private companyLocation: LocationPoint = {
    latitude: 39.8649463,
    longitude: 32.849474
  };
  // restricted area limited with 100 meters
  private maxDistance: number = 100;
  // time update
  private timerId: number = 0;
  private locationService: LocationService = new LocationService();

  aboutToAppear() {
    this.updateCurrentTime();
    this.navDesInfo = this.queryNavDestinationInfo();

    if (this.navDesInfo?.param) {
      this.item = JSON.parse(this.navDesInfo?.param?.valueOf().toString())
    }
    this.currentRecord = this.item
  }

  aboutToDisappear() {
    if (this.timerId) {
      clearInterval(this.timerId);
    }
  }

  updateCurrentTime() {
    this.currentTime = AttendanceRecord.getCurrentTime();
  }

  startVibration() {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 200
      }, {
        id: 0,
        usage: 'alarm'
      }, (error: BusinessError) => {
        if (error) {
          console.error(`Vibration error: ${error.code}, ${error.message}`);
        }
      });
    } catch (err) {
      console.error(`Vibration error: ${JSON.stringify(err)}`);
    }
  }

  async checkLocation() {
    try {
      if (!this.locationService.isLocationEnabled()) {
        this.message = 'Please enable location settings';
        return;
      }

      const location = await this.locationService.getCurrentLocationFast(5000);

      if (location) {
        //Calculate distance
        this.distance = this.locationService.distanceMeters(
          { latitude: location.latitude, longitude: location.longitude },
          this.companyLocation
        );

        this.isInRange = this.distance <= this.maxDistance;
        this.message = this.isInRange ? `Attendance succesfull (${this.distance.toFixed(0)}m)` :
          `Unavailable location (${this.distance.toFixed(0)}m)`;
      } else {
        this.message = 'Failure getting location';
      }
    } catch (error) {
      this.message = 'Location error';
      console.error(`Location error: ${JSON.stringify(error)}`);
    }
  }

  // Handle touch
  async handleTouch() {
    await this.checkLocation();

    if (!this.isInRange) {
      this.promptAction.showToast({
        message: 'Out of range. Enable Wi-Fi to improve location accuracy!',
        duration: 3000
      });
      return;

    }

    if (this.currentRecord.isComplete()) {
      this.promptAction.showToast({ message: 'Attendance successful.', duration: 3000 });
      return;
    }

    // Start vibration
    this.startVibration();

    if (this.currentRecord.firstRecord === '--:--:--') {
      // First record
      this.currentRecord.recordFirstEntry();
      const message = this.currentRecord.status === 'late' ? `You are late! Time: ${this.currentRecord.firstRecord}` :
        `First record has taken: ${this.currentRecord.firstRecord}`;
      this.promptAction.showToast({ message: message, duration: 3000 });
    } else {
      // Last record
      this.currentRecord.recordLastEntry();
      this.promptAction.showToast({
        message: `Last record has taken: ${this.currentRecord.lastRecord}`,
        duration: 3000
      });
    }
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Text(this.currentRecord.date)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })

        Text(this.currentTime)
          .fontSize(14)

        Text(this.message)
          .fontSize(12)
          .fontColor(this.isInRange ? '#0A0' : '#F00')

        if (this.distance > 0) {
          Text(`Distance: ${this.distance.toFixed(0)} meters`)
            .fontSize(12)
            .opacity(0.7)
        }
        Row() {
          Column() {
            Text('First record')
              .fontSize(12)
              .opacity(0.7)
            Text(this.currentRecord.firstRecord)
              .fontSize(16)
              .fontColor(this.currentRecord.firstRecord !== '--:--:--' ? '#000' : '#999')
          }
          .width('50%')

          Column() {
            Text('Last record')
              .fontSize(12)
              .opacity(0.7)
            Text(this.currentRecord.lastRecord)
              .fontSize(16)
              .fontColor(this.currentRecord.lastRecord !== '--:--:--' ? '#000' : '#999')
          }
          .width('50%')
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)

        if (this.currentRecord.status === 'approved') {
          Text('Attendance successful')
            .fontSize(14)
            .fontColor('#0A0')
        } else if (this.currentRecord.status === 'late') {
          Text('You are late')
            .fontSize(14)
            .fontColor('#F00')
        } else if (this.currentRecord.status === 'pending') {
          Text('Pending')
            .fontSize(14)
            .fontColor('#FA0')
        }

        Button('Touch', { type: ButtonType.Capsule, stateEffect: true })
          .width(120)
          .height(120)
          .fontSize(18)
          .backgroundColor(this.isInRange ? '#007DFF' : '#CCC')
          .onClick(() => this.handleTouch())
          .margin({ top: 20 })

        Button('Recheck location')
          .width('80%')
          .onClick(() => this.checkLocation())
          .margin({ top: 10 })

        Button('Back')
          .width('80%')
          .onClick(() => {
            this.baseVm.navigationService.pageInfos.pop()
          })
          .margin({ top: 10 })
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Center)
    }
  }
}