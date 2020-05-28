public with sharing class LookupController {

	private static final Integer DEFAULT_QUERY_LIMIT = 25;

	public with sharing class Response {
		@AuraEnabled public Boolean isSuccess;
		@AuraEnabled public Map<String, Object> results;
		@AuraEnabled public String errMsg;

		public Response() {
			this.isSuccess = false;
			this.results = new Map<String, Object>();
		}

		public Response(Map<String, Object> results) {
			this.isSuccess = true;
			this.results = results;
		}

		public void addError(String errMsg) {
			this.errMsg = errMsg;
			this.isSuccess = false;
		}
	}

	@AuraEnabled
	public static Response getRecords(final String searchTerm) {
		Response response = new Response();
		try {
			Map<String, Object> results = getData(searchTerm);
			response = new Response(results);
		} catch (Exception e) {
			response.addError(e.getMessage());
		}
		return response;
	}

	private static Map<String, Object> getData(final String searchTerm) {
		List<Map<String, Object>> data = new List<Map<String, Object>>();

		if (String.isNotEmpty(searchTerm)) {
			data = getResultData(searchTerm);
		} else {
			throw new DocuSignException(Label.NoSearchResults);
		}
		return new Map<String, Object> {
			'data' => data,
			'searchTerm' => searchTerm
		};
	}

	//This method uses SOSL to pull records from User,Contact
	private static List<Map<String, Object>> getResultData(final String searchTerm) {
		List<Map<String, Object>> data = new List<Map<String, Object>>();
		List<List<SObject>> results = soslQuery(searchTerm);
		for (List<SObject> objectList : results) {
			for (SObject obj : objectList) {
				String sObjType = obj.Id.getSobjectType().getDescribe().getName();
				data.add(new Map<String, Object> {
					'label' => obj.get('Name'),
					'sublabel' => obj.get('Email'),
					'value' => obj.Id,
					'objType' => sObjType
				});
			}
		}
		return data;
	}

	private static List<List<SObject>> soslQuery(final String searchTerm) {
		List<List<SObject>> searchList = [FIND :searchTerm IN ALL FIELDS RETURNING Contact (Name, Email), User(Name, Email) limit :DEFAULT_QUERY_LIMIT];
		return searchList;
	}

}
