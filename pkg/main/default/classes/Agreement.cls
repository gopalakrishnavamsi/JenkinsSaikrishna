/**
 * Representation of a DocuSign Agreement.
 */
public class Agreement {
/**
* The Agreement UUID from SpringCM API.
*/
	@AuraEnabled
	public UUID id { get; private set; }
/**
* The DocuSign Agreement name.
*/
	@AuraEnabled
	public String name { get; private set; }
/**
* Date and time when the Agreement was created.
*/
	@AuraEnabled
	public Datetime createdDate { get; private set; }
/**
* Date and time when the Agreement was modified.
*/
	@AuraEnabled
	public Datetime modifiedDate { get; private set; }
/**
* Agreement status
*/
	@AuraEnabled
	public String status { get; private set; }
/**
* Agreement href at SpringCM
*/
	@AuraEnabled
	public Url href { get; private set; }
/**
* Agreement size at SpringCM
*/
	@AuraEnabled
	public Long pdfFileSize { get; private set; }
/**
* Agreement size at SpringCM
*/
	@AuraEnabled
	public String version { get; private set; }
/**
* Agreement history
*/
	@AuraEnabled
	public List<AgreementHistoryItem> historyItems { get; private set; }
/**
* Agreement history
*/
	@AuraEnabled
	public List<Agreement> versions { get; private set; }

	public Agreement(
		final UUID id,
		final String name,
		final Datetime createdDate,
		final Datetime modifiedDate,
		final String status,
		final Url href,
		final Long pdfFileSize,
		final String version) {

		this.id = id;
		this.name = name;
		this.createdDate = createdDate;
		this.modifiedDate = modifiedDate;
		this.status = status;
		this.href = href;
		this.pdfFileSize = pdfFileSize;
		this.version = version;
		this.historyItems = new List<AgreementHistoryItem>();
		this.versions = new List<Agreement>();

	}

	public Agreement withStatus(String status) {
		try {
			if (AgreementStatus.isValid(status)) {
				this.status = status;
			} else {
				this.status = AgreementStatus.SYSTEM_ERROR;
			}
		} catch (Exception ex) {

			this.status = AgreementStatus.SYSTEM_ERROR;
			LoggerService.getInstance().exception(ex, 'Invalid Agreement status');
		}
		return this;
	}

	public Agreement withHistoryItems(List<AgreementHistoryItem> historyItems) {
		if (historyItems == null || historyItems.isEmpty()) {
			this.historyItems = new List<AgreementHistoryItem>();
		} else {
			this.historyItems = historyItems;
		}
		return this;
	}

	public Agreement withVersions(List<Agreement> versions) {
		if (versions == null || versions.isEmpty()) {
			this.versions = new List<Agreement>();
		} else {
			this.versions = versions;
		}
		return this;
	}

	public Agreement withModifiedDate(Datetime modifiedDatetime) {
		if (modifiedDatetime == null) {
			this.modifiedDate = this.createdDate;
		} else {
			this.modifiedDate = modifiedDatetime;
		}
		return this;
	}
}