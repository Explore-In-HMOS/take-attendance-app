import { abilityAccessCtrl, PermissionRequestResult, Permissions, bundleManager, common } from '@kit.AbilityKit';
import GlobalContext from './GlobalContext';

const TAG: string = '[Permission]';
const PERMISSIONS: Array<Permissions> =
  ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.KEEP_BACKGROUND_RUNNING'];

export default async function grantPermission(): Promise<boolean> {
  try {
    // Get context from GlobalContext singleton
    const globalContext = GlobalContext.getInstance();
    const context = globalContext.getCnx();

    if (!context) {
      console.error(TAG, 'Context is not available');
      return false;
    }

    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    let tokenId = appInfo.accessTokenId;
    let atManager = abilityAccessCtrl.createAtManager();
    let pems: Array<Permissions> = [];
    for (let i = 0; i < PERMISSIONS.length; i++) {
      let state = await atManager.checkAccessToken(tokenId, PERMISSIONS[i]);
      if (state !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        pems.push(PERMISSIONS[i]);
      }
    }
    if (pems.length > 0) {
      let result: PermissionRequestResult = await atManager.requestPermissionsFromUser(context, pems);
      let grantStatus: Array<number> = result.authResults;
      let length: number = grantStatus.length;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] !== 0) {
          return false;
        }
      }
    }
    return true;
  } catch (error) {
    return false;
  }
}