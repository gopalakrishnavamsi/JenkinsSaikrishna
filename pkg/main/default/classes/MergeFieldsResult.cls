public class MergeFieldsResult {

	@AuraEnabled
	public OnlineEditorMergeObject[] objects { get; private set; }
	@AuraEnabled
	public Map<String, MergeField[]> fields { get; private set; }

	public MergeFieldsResult(
		final OnlineEditorMergeObject[] objects,
		final Map<String, MergeField[]> fields) {

		this.objects = objects;
		this.fields = fields;
	}

}