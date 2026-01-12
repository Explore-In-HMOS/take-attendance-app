import { NavigationService } from '../services/NavigationService';
import { AttendanceDetailPage } from './AttendanceDetailPage';
import { AttendanceMainPage } from './AttendanceMainPage';

@Entry
@Component
struct Index {
  navigationService: NavigationService = NavigationService.getInstance();

  @Builder
  routeMap(name: string) {
    NavDestination() {
      if (name === 'Main') {
        AttendanceMainPage()
      } else if (name === 'Detail') {
        AttendanceDetailPage()
      }
    }
    .hideTitleBar(true)
  }

  build() {
    Navigation(this.navigationService.pageInfos) {
      AttendanceMainPage()
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.routeMap)
    .ignoreLayoutSafeArea()
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}