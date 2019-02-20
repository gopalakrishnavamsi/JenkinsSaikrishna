public with sharing class SettingsController extends Controller {

	public class Settings {
		@AuraEnabled
		public AccountSettings account { get; private set; }
		@AuraEnabled
		public List<AccountService.SystemSender> availableSystemSenders { get; private set; }

		public Settings(
			final AccountSettings account,
			final List<AccountService.SystemSender> availableSystemSenders) {

			this.account = account;
			this.availableSystemSenders = availableSystemSenders;
		}
	}

	@AuraEnabled(Cacheable = true)
	public static Settings getSettings() {
		try {
			return new Settings(
				AccountService.getSettings(),
				AccountService.getAvailableSystemSenders());
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
