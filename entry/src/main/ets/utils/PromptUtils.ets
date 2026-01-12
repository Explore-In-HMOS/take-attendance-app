import { PromptAction } from '@kit.ArkUI';

export class PromptUtils {
  static showToast(promptAction: PromptAction, message: string, duration: number = 3000): void {
    try {
      promptAction.showToast({ message, duration });
    } catch (error) {
      console.error('Toast not shown:', error);
    }
  }
}
