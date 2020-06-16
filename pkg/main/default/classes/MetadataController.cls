public with sharing class MetadataController extends Controller {

	public class Configuration {
		@AuraEnabled
		public String sendActionName { get; private set; }
		@AuraEnabled
		public List<MergeObject> commonObjects { get; private set; }
		@AuraEnabled
		public List<MergeObject> allObjects { get; private set; }

		private Configuration(
			final String sendActionName,
			final List<MergeObject> commonObjects,
			final List<MergeObject> allObjects) {

			this.sendActionName = sendActionName;
			this.commonObjects = commonObjects;
			this.allObjects = allObjects;
		}
	}

	@AuraEnabled(Cacheable = true)
	public static Configuration getConfiguration() {
		try {
			return new Configuration(
				Layout.ACTION_NAME_SEND,
				MetadataService.getCommonObjects(),
				MetadataService.getObjects());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve Salesforce objects');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static String getGenActionName() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			return Layout.ACTION_NAME_GEN;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve GenAction Name');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static String getDecActionName() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			return Layout.ACTION_NAME_DEC;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve DecAction Name');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static List<Layout> getLayouts(final String sObjectType) {
		try {
			return MetadataService.getLayouts(Salesforce.getSObjectType(sObjectType));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve layouts');
		}
	}

	@AuraEnabled
	public static List<Layout> updateLayouts(
		final String sObjectType,
		final String layoutsJson,
		final String parameters) {
		try {
			return MetadataService.updateLayouts(
				Salesforce.getSObjectType(sObjectType),
				(List<Layout>)JSON.deserialize(layoutsJson, List<Layout>.class),
				parameters,
				null);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to update layouts');
		}
	}
}
