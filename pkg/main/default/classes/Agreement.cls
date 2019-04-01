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
* Agreement status
*/
	@AuraEnabled
	public String status { get; private set; }
/**
* Agreement history
*/
	@AuraEnabled
	public List<AgreementHistoryItem> historyItems { get; private set; }

	public Agreement(
		final UUID id,
		final String name,
		final Datetime createdDate,
		final String status) {

		this.id = id;
		this.name = name;
		this.createdDate = createdDate;
		setStatus(status);
		this.historyItems = new List<AgreementHistoryItem>();

	}

	public void setStatus(String status) {
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
	}

	public void setHistoryItems(List<AgreementHistoryItem> historyItems) {
		if (historyItems == null || historyItems.isEmpty()){
			this.historyItems = new List<AgreementHistoryItem>();
		} else {
			this.historyItems = historyItems;
		}
	}
}