public class DataSourceLookupController extends Controller {
	@AuraEnabled(cacheable=true)
	public static DataSourceConfiguration getDataSourceObjects() {
		try {
			return new DataSourceConfiguration(
				MetadataService.getCommonObjects(),
				MetadataService.getAllOtherObjects());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get all objects.');
		}
	}

	public class DataSourceConfiguration {

		@AuraEnabled
		public List<MergeObject> commonObjects { get; private set; }
		@AuraEnabled
		public List<MergeObject> allOtherObjects { get; private set; }

		private DataSourceConfiguration(
			final List<MergeObject> commonObjects,
			final List<MergeObject> allOtherObjects
		) {
			this.commonObjects = commonObjects == null ? new List<MergeObject>() : commonObjects;
			this.allOtherObjects = allOtherObjects == null ? new List<MergeObject>() : allOtherObjects;
		}
	}

}