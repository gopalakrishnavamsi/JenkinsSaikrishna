public with sharing class SettingsController extends Controller {

	@AuraEnabled
	public static AccountSettings getSettings() {
		try {
			return AccountService.getSettings();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get account settings');
		}
	}

	@AuraEnabled
	public static AccountSettings saveSettings(final String settingsJson) {
		try {
			return AccountService.saveSettings((AccountSettings)JSON.deserialize(
				settingsJson,
				AccountSettings.class));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to save account settings');
		}
	}
}
